//
//  CircularSpinner.swift
//  CircularSpinnerExample
//
//  Created by Matteo Tagliafico on 15/09/16.
//  Copyright © 2016 Matteo Tagliafico. All rights reserved.
//

import UIKit

@objc public protocol CircularSpinnerDelegate: NSObjectProtocol {
    @objc optional func circularSpinnerTitleForValue(_ value: Float) -> NSAttributedString
}


@objc public enum CircularSpinnerType: Int {
    case determinate
    case indeterminate
}

public class CircularSpinner: UIView {
    
    // MARK: - singleton
    static public let sharedInstance = CircularSpinner(frame: CGRect.zero)
    
    
    // MARK: - outlets
    @IBOutlet fileprivate weak var circleView: UIView!
    @IBOutlet fileprivate weak var circleViewWidth: NSLayoutConstraint! {
        didSet {
            layoutIfNeeded()
        }
    }
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var dismissButton: UIButton!
    
    // MARK: - properties
    open weak var delegate: CircularSpinnerDelegate?
    fileprivate var mainView: UIView!
    fileprivate let nibName = "CircularSpinner"
    
    fileprivate static weak var customSuperview: UIView? = nil
    
    fileprivate var backgroundCircleLayer = CAShapeLayer()
    fileprivate var progressCircleLayer = CAShapeLayer()
    
    var indeterminateDuration: Double = 1.5
    
    fileprivate var startAngle: CGFloat {
        return CGFloat(Double.pi / 2)
    }
    fileprivate var endAngle: CGFloat {
        return 5 * CGFloat(Double.pi / 2)
    }
    var arcCenter: CGPoint {
        return convert(circleView.center, to: circleView)
    }
    fileprivate var arcRadius: CGFloat {
        return (min(bounds.width, bounds.height) * 0.8) / 2
    }
    
    fileprivate var oldStrokeEnd: Float?
    fileprivate var backingValue: Float = 0
    open override var frame: CGRect {
        didSet {
            if frame == CGRect.zero { return }
            
            backgroundCircleLayer.frame = bounds
            progressCircleLayer.frame = bounds
            circleView.center = center
        }
    }
    open var value: Float {
        get {
            return backingValue
        }
        set {
            backingValue = min(1, max(0, newValue))
        }
    }
    open var type: CircularSpinnerType = .determinate {
        didSet {
            configureType()
        }
    }
    public static var dismissButton: Bool = true
    open var showDismissButton = dismissButton {
        didSet {
            appearanceDismissButton()
        }
    }
    public static var trackLineWidth: CGFloat = 3
    private var lineWidth = trackLineWidth {
        didSet {
            appearanceBackgroundLayer()
            appearanceProgressLayer()
        }
    }
    
    public static var trackBgColor = UIColor(red: 250.0/255, green: 250.0/255, blue: 250.0/255, alpha: 1)
    private var bgColor = trackBgColor {
        didSet {
            appearanceBackgroundLayer()
        }
    }
    public static var trackPgColor = UIColor(red: 91.0/255, green: 209.0/255, blue: 120.0/255, alpha: 1)
    open var pgColor = trackPgColor {
        didSet {
            appearanceProgressLayer()
        }
    }
    
    
    // MARK: - view lifecycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func xibSetup() {
        mainView = loadViewFromNib()
        mainView.frame = bounds
        mainView.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(mainView)
    }
    
    fileprivate func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: Swift.type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }
    
    
    // MARK: - drawing methods
    open override func draw(_ rect: CGRect) {
        backgroundCircleLayer.path = getCirclePath()
        progressCircleLayer.path = getCirclePath()
        updateFrame()
    }
    
    fileprivate func getCirclePath() -> CGPath {
        return UIBezierPath(arcCenter: arcCenter, radius: arcRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true).cgPath
    }
    
    
    // MARK: - configure
    fileprivate func configure() {
        backgroundColor = UIColor.clear
        
        configureCircleView()
        configureBackgroundLayer()
        configureProgressLayer()
        configureDismissButton()
        configureType()
    }
    
    fileprivate func configureCircleView() {
        circleViewWidth.constant = arcRadius * 2
        circleView.backgroundColor = UIColor.clear
    }
    
    fileprivate func configureBackgroundLayer() {
        circleView.layer.addSublayer(backgroundCircleLayer)
        appearanceBackgroundLayer()
    }
    
    fileprivate func configureProgressLayer() {
        circleView.layer.addSublayer(progressCircleLayer)
        appearanceProgressLayer()
    }
    
    fileprivate func configureDismissButton() {
        appearanceDismissButton()
    }
    
    fileprivate func configureType() {
        switch type {
        case .indeterminate:
            startInderminateAnimation()
        default:
            oldStrokeEnd = nil
            updateTitleLabel()
            self.value = 1.0
            self.updateTitleLabel()
            self.setStrokeEnd(animated: true) {
                if self.value >= 1 {
                    //CircularSpinner.hide()
                }
            }
        }
    }
    
    
    
    // MARK: - appearance
    fileprivate func appearanceBackgroundLayer() {
        backgroundCircleLayer.lineWidth = lineWidth
        backgroundCircleLayer.fillColor = UIColor.clear.cgColor
        backgroundCircleLayer.strokeColor = UIColor.clear.cgColor //bgColor.cgColor
        backgroundCircleLayer.lineCap = CAShapeLayerLineCap.round
    }
    
    public func appearanceProgressLayer() {
        progressCircleLayer.lineWidth = lineWidth
        progressCircleLayer.fillColor = UIColor.clear.cgColor
        progressCircleLayer.strokeColor = pgColor.cgColor
        progressCircleLayer.lineCap = CAShapeLayerLineCap.round
    }
    
    fileprivate func appearanceDismissButton() {
        dismissButton.isHidden = !showDismissButton
    }
    
    
    // MARK: - methods
    fileprivate static func containerView() -> UIView? {
        return customSuperview ?? UIApplication.shared.keyWindow
    }
    
    open class func useContainerView(_ sv: UIView?) {
        customSuperview = sv
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        updateFrame()
    }
    
    @objc public func updateFrame() {
        if let containerView = CircularSpinner.containerView() {
            CircularSpinner.sharedInstance.frame = containerView.bounds
        }
    }
    
    fileprivate func generateAnimation() -> CAAnimationGroup {
        let headAnimation = CABasicAnimation(keyPath: "strokeStart")
        headAnimation.beginTime = indeterminateDuration / 3
        headAnimation.fromValue = 0
        headAnimation.toValue = 1
        headAnimation.duration = indeterminateDuration / 1.5
        headAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        let tailAnimation = CABasicAnimation(keyPath: "strokeEnd")
        tailAnimation.fromValue = 0
        tailAnimation.toValue = 1
        tailAnimation.duration = indeterminateDuration / 1.5
        tailAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.duration = indeterminateDuration
        groupAnimation.repeatCount = Float.infinity
        groupAnimation.animations = [headAnimation, tailAnimation]
        return groupAnimation
    }
    
    fileprivate func generateRotationAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue = 2 * Double.pi
        animation.duration = indeterminateDuration
        animation.repeatCount = Float.infinity
        return animation
    }
    
    public func startInderminateAnimation() {
        progressCircleLayer.add(generateAnimation(), forKey: "strokeLineAnimation")
        circleView.layer.add(generateRotationAnimation(), forKey: "rotationAnimation")
    }
    
    fileprivate func stopInderminateAnimation() {
        progressCircleLayer.removeAllAnimations()
        circleView.layer.removeAllAnimations()
    }
    
    
    // MARK: - update
    open class func setValue(_ value: Float, animated: Bool) {
        let spinner = CircularSpinner.sharedInstance
        guard spinner.type == .determinate else { return }
        
        if spinner.value != value {
            spinner.value = value
            spinner.updateTitleLabel()
            spinner.setStrokeEnd(animated: animated) {
                if value >= 1 {
                    //CircularSpinner.hide()
                }
            }
        }
    }
    
    fileprivate func updateTitleLabel() {
        let spinner = CircularSpinner.sharedInstance
        
        if let attributeStr = spinner.delegate?.circularSpinnerTitleForValue?(value) {
            spinner.titleLabel.attributedText = attributeStr
        } else {
            spinner.titleLabel.text = "\(Int(value * 100))%"
        }
    }
    
    fileprivate func setStrokeEnd(animated: Bool, completed: (() -> Void)? = nil) {
        let spinner = CircularSpinner.sharedInstance
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock({
            completed?()
        })
        
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.duration = animated ? 0.66 : 0
        strokeAnimation.repeatCount = 1
        strokeAnimation.fromValue = oldStrokeEnd ?? 0
        strokeAnimation.toValue = spinner.value
        strokeAnimation.isRemovedOnCompletion = false
        strokeAnimation.fillMode = CAMediaTimingFillMode.removed
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        progressCircleLayer.add(strokeAnimation, forKey: "strokeLineAnimation")
        progressCircleLayer.strokeEnd = CGFloat(spinner.value)
        CATransaction.commit()
        
        oldStrokeEnd = spinner.value
    }
    
    
    // MARK: - actions
    @IBAction fileprivate func dismissButtonTapped(_ sender: UIButton?) {
        CircularSpinner.hide()
    }
}


// MARK: - API
extension CircularSpinner {
    
    open class func show(_ title: String = "", animated: Bool = true, type: CircularSpinnerType = .determinate, showDismissButton: Any? = nil, delegate: CircularSpinnerDelegate? = nil) {
        let spinner = CircularSpinner.sharedInstance
        spinner.type = type
        spinner.delegate = delegate
        spinner.titleLabel.text = title
        spinner.showDismissButton = (showDismissButton as? Bool) ?? CircularSpinner.dismissButton
        spinner.value = 0
        spinner.updateFrame()
        
        if spinner.superview == nil {
            spinner.alpha = 0
            
            guard let containerView = CircularSpinner.containerView() else {
                fatalError("UIApplication.keyWindow is nil.")
            }
            
            containerView.addSubview(spinner)
            
            UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseOut, animations: {
                spinner.alpha = 1
                }, completion: nil)
        }
        
        NotificationCenter.default.addObserver(spinner, selector: #selector(updateFrame), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    open class func hide(_ completion: (() -> Void)? = nil) {
        let spinner = CircularSpinner.sharedInstance
        spinner.stopInderminateAnimation()
        
        NotificationCenter.default.removeObserver(spinner)
        
        DispatchQueue.main.async(execute: {
            if spinner.superview == nil {
                return
            }
            
            UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseOut, animations: {
                spinner.alpha = 0
                }, completion: { _ in
                    spinner.alpha = 1
                    spinner.removeFromSuperview()
                    completion?()
            })
        })
    }
}
