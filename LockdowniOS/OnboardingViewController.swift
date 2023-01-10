//
//  OnboardingViewController.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 9/26/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import AVFoundation
import Foundation
import UIKit

final class OnboardingViewController: UIViewController, CAAnimationDelegate {
    
    @IBOutlet private var progressBarStackView: UIStackView!
    
    @IBOutlet private var infoLabelStackView: UIStackView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    
    @IBOutlet private var videoContentBorderView: UIView!
    @IBOutlet private var videoContentView: UIView!
    @IBOutlet private var imageView: UIImageView!
    
    @IBOutlet private var leftTapGestureView: UIView!
    @IBOutlet private var rightTapGestureView: UIView!
    
    @IBOutlet private var signUpButton: UIButton!
    @IBOutlet private var loginButton: UIButton!
    
    @IBOutlet private var videoContentVerticalCenterConstraint: NSLayoutConstraint!
    @IBOutlet private var imageContentLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var imageContentTrailingConstraint: NSLayoutConstraint!
    
    private var progressViews: [WeakObject<ProgressView>] = []
    private var gradientLayer: CAGradientLayer?
    private var avPlayerLayer: AVPlayerLayer?
    private var avPlayer: AVPlayer?
    
    /// Defining if page progress should be continued upon viewWillAppear.
    private var hasDisappearedBefore = false
    
    private let configuration = OnboardingConfiguration()
    private var progressBarTimer: Timer?
    private var currentTimerDuration: Float = 0
    
    private var currentProgressPercentage: Float {
        switch currentPage.content {
        case .image(_, let duration, _):
            return currentTimerDuration / duration
        case .video:
            return currentTimerDuration / currentPage.videoDuration
        }
    }
    
    private let pages: [OnboardingPage]
    private var currentPage: OnboardingPage { pages[currentPageIndex] }
    
    @PositiveAndArrayRestricted(defaultValue: 0)
    private var currentPageIndex {
        didSet {
            DispatchQueue.main.async {
                self.updatePage()
            }
        }
    }
    
    init(pages: [OnboardingPage] = .defaultPages) {
        self.pages = pages
        _currentPageIndex.arrayCount = pages.count
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupProgressViews()
        updatePage()
        setupTexts()
        setupButtons()
        setupSideTapGestures()
        
        configureContentSizingForIdiom()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(freezePageProgress),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.layoutIfNeeded()
        
        gradientLayer?.frame = view.bounds
        avPlayerLayer?.frame = videoContentView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.tintColor = .label
        navigationController?.navigationBar.barStyle = .default
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        if hasDisappearedBefore {
            continuePageProgress()
            hasDisappearedBefore = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        freezePageProgress()
        hasDisappearedBefore = true
    }
    
    @IBAction private func didTapSignUp(_ sender: Any) {
        OneTimeActions.markAsSeen(.newFancyOnboarding)
        signUpButton.showAnimatedPress { [weak self] in
            let signUpViewController = SignUpViewController(mode: .signUp)
            self?.navigationController?.pushViewController(signUpViewController, animated: true)
        }
    }
    
    @IBAction private func didTapLogin(_ sender: Any) {
        OneTimeActions.markAsSeen(.newFancyOnboarding)
        loginButton.showAnimatedPress { [weak self] in
            let signUpViewController = SignUpViewController(mode: .login)
            self?.navigationController?.pushViewController(signUpViewController, animated: true)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupProgressViews() {
        progressBarStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        progressBarStackView.layoutIfNeeded()
        
        for _ in pages {
            let progressView = ProgressView()
            progressBarStackView.addArrangedSubview(progressView)
            progressViews.append(WeakObject(progressView))
            
            progressView.heightAnchor.constraint(equalToConstant: isPad ? 6 : 4).isActive = true
        }
    }
    
    private func setupTexts() {
        signUpButton.setTitle(.localized("onboarding_sign_up"), for: .normal)
        loginButton.setTitle(.localized("onboarding_login"), for: .normal)
        
        // https://stackoverflow.com/questions/46200027/uilabel-wrong-word-wrap-in-ios-11/
        // To prevent UIKit from moving the penultimate word to the line with the last orphaned word.
        titleLabel.lineBreakStrategy = []
    }
    
    private func setupButtons() {
        [signUpButton, loginButton].forEach {
            $0?.dropShadow()
            $0?.corners = .continuous(16)
            $0?.titleLabel?.adjustsFontSizeToFitWidth = true
            $0?.contentEdgeInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
            $0?.clipsToBounds = true
        }
    }
    
    private func configureContentSizingForIdiom() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Make video centered on iPad
            videoContentVerticalCenterConstraint.priority = .required
            
            // Lower priority of side constraints, so the =< width constraint in XIB is prioritized.
            // This gives the imageView on iPad [limited] space to grow.
            // As a result, the image doesn't look overly big on large iPads.
            imageContentLeadingConstraint.priority = .defaultHigh
            imageContentTrailingConstraint.priority = .defaultHigh
        } else {
            videoContentVerticalCenterConstraint.priority = .defaultHigh
            imageContentLeadingConstraint.priority = .required
            imageContentTrailingConstraint.priority = .required
        }
    }
    
    private func updatePage() {
        UIView.transition(with: infoLabelStackView,
                          duration: configuration.contentAnimationDuration,
                          options: .transitionCrossDissolve) { [weak self] in
            guard let self = self else { return }
            self.titleLabel.text = self.currentPage.title
            self.descriptionLabel.text = self.currentPage.description
        }
        
        updateGradient()
        updateContent()
    }
    
    private func updateContent() {
        imageView.prepareForReuse()
        switch currentPage.content {
        case .image(let title, _, let presentationType):
            switchContentVisibility(isVideoContent: false)
            showImage(title: title, animation: presentationType.animation)
        case .video(let videoTitle):
            switchContentVisibility(isVideoContent: true)
            showVideo(title: videoTitle)
        }
        view.setNeedsLayout()
        
        startTimer()
    }
    
    private func switchContentVisibility(isVideoContent: Bool) {
        imageView.isHidden = isVideoContent
        videoContentView.isHidden = !isVideoContent
        videoContentBorderView.isHidden = !isVideoContent
    }
    
    private func showImage(title: String, animation: ImageViewAnimationCompletion) {
        imageView.image = UIImage(named: title) ?? UIImage()
        imageView.prepareForReuse()
        DispatchQueue.main.async {
            animation?(self.imageView)
        }
    }
    
    private func showVideo(title: String) {
        guard let videoPath = Bundle.main.path(forResource: title, ofType: "mp4") else { return }
        
        avPlayerLayer?.removeFromSuperlayer()
        avPlayerLayer = nil
        
        videoContentView.corners = .continuous(12)
        videoContentBorderView.corners = .continuous(12)
        
        let videoUrl = URL(fileURLWithPath: videoPath)
        let avPlayer = AVPlayer(url: videoUrl)
        let avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.videoGravity = .resizeAspectFill
        avPlayerLayer.corners = .continuous(12)
        self.avPlayerLayer = avPlayerLayer
        self.avPlayer = avPlayer
        
        videoContentView.layer.addSublayer(avPlayerLayer)
        avPlayer.play()
    }
    
    @objc private func updateProgressView() {
        let currentProgressView = progressViews[currentPageIndex]
        currentTimerDuration += Float(configuration.timerInterval)
        currentProgressView.object?.progress = currentProgressPercentage
        
        if currentProgressPercentage >= 1.0 {
            stopTimer()
            switchToNextPage()
        }
    }
    
    private func startTimer() {
        progressBarTimer = Timer.scheduledTimer(timeInterval: configuration.timerInterval,
                                                target: self,
                                                selector: #selector(updateProgressView),
                                                userInfo: nil,
                                                repeats: true)
    }
    
    private func stopTimer(keepProgress: Bool = false) {
        if !keepProgress {
            currentTimerDuration = 0
        }
        progressBarTimer?.invalidate()
        progressBarTimer = nil
    }
    
    @objc private func continuePageProgress() {
        guard progressBarTimer == nil else { return }
        // Removing observer of returning to app since it makes no sense when we are in the app.
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        
        DispatchQueue.main.async {
            if case .image = self.currentPage.content {
                // If it's an image, we have a complete restart of content displaying.
                self.updateContent()
            } else {
                // If it is a video, we continue playing it from where we stopped
                // and restart the timer for progress view updating.
                self.avPlayer?.play()
                self.startTimer()
            }
        }
    }
    
    @objc private func freezePageProgress() {
        // Adding observer only here so continuePageProgress isn't called additionally in the beginning.
        // This observer will be added upon leaving the app and removed upon returning.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(continuePageProgress),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        // Freezing progress depending on the type of content.
        DispatchQueue.main.async {
            if case .image = self.currentPage.content {
                // If it is an image, we will have to completely restart animation upon returning.
                // For smoothness, we hide the image before leaving the app.
                self.stopTimer()
                self.imageView.isHidden = true
            } else {
                // If it is a video, we will just continue playing it upon returning, hence we pause and keep progress.
                self.stopTimer(keepProgress: true)
                self.avPlayer?.pause()
            }
        }
    }
}

// MARK: - Gesture Recognizers
extension OnboardingViewController {
    
    private func setupSideTapGestures() {
        let leftTapGesture = UITapGestureRecognizer(target: self, action: #selector(switchToPreviousPage))
        leftTapGestureView.addGestureRecognizer(leftTapGesture)
        
        let rightTapGesture = UITapGestureRecognizer(target: self, action: #selector(switchToNextPage))
        rightTapGestureView.addGestureRecognizer(rightTapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.3
        view.addGestureRecognizer(longPressGesture)
        
        view.bringSubviewToFront(leftTapGestureView)
        view.bringSubviewToFront(rightTapGestureView)
    }
    
    @objc private func switchToPreviousPage() {
        progressViews.resetProgress(at: currentPageIndex)
        currentPageIndex -= 1
        progressViews.resetProgress(at: currentPageIndex)
        
        stopTimer()
    }
    
    @objc private func switchToNextPage() {
        currentTimerDuration = 0
        progressBarTimer?.invalidate()
        
        if currentPageIndex == pages.count - 1 {
            imageView.layer.removeAllAnimations()
            progressViews.resetProgresses()
            currentPageIndex = 0
        } else {
            UIView.performWithoutAnimation {
                self.progressViews[currentPageIndex].object?.progress = 1
                self.progressViews[currentPageIndex].object?.layoutIfNeeded()
            }
            currentPageIndex += 1
        }
    }
    
    @objc private func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == .ended {
            resumeContentAfterLongPress()
            fadeSecondaryElements(visible: true)
        } else if gestureReconizer.state != .changed {
            pauseContentOnLongPress()
            fadeSecondaryElements(visible: false)
        }
    }
    
    private func pauseContentOnLongPress() {
        DispatchQueue.main.async {
            self.stopTimer(keepProgress: true)
            
            if case .image = self.currentPage.content {
                self.imageView.layer.pause()
            } else {
                self.avPlayer?.pause()
            }
        }
    }
    
    private func resumeContentAfterLongPress() {
        DispatchQueue.main.async {
            self.startTimer()
            
            if case .image = self.currentPage.content {
                self.imageView.layer.resume()
            } else {
                self.avPlayer?.play()
            }
        }
    }
    
    private func fadeSecondaryElements(visible: Bool) {
        UIView.animate(withDuration: 0.2) {
            [self.progressBarStackView,
             self.signUpButton,
             self.loginButton
            ].forEach {
                $0?.alpha = visible ? 1 : 0
            }
        }
    }
}

// MARK: - Gradient Update
extension OnboardingViewController {
    private func updateGradient() {
        if gradientLayer == nil {
            gradientLayer = view.applyGradient(currentPage.gradient)
        }
        
        animateGradientToNextColor()
    }
    
    private func animateGradientToNextColor() {
        let fromColors = gradientLayer?.colors
        let toColors: [CGColor] = currentPage.gradient.colors
        gradientLayer?.colors = currentPage.gradient.colors
        
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "colors")
        
        animation.fromValue = fromColors
        animation.toValue = toColors
        animation.duration = configuration.contentAnimationDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        gradientLayer?.add(animation, forKey:"animateGradient")
    }
}

private extension Array where Element == WeakObject<ProgressView> {
    func resetProgresses() {
        forEach { $0.object?.progress = 0 }
    }
    
    func resetProgress(at index: Int) {
        let progressBar = self[index]
        UIView.performWithoutAnimation {
            progressBar.object?.progress = 0
            progressBar.object?.layoutIfNeeded()
        }
    }
}
