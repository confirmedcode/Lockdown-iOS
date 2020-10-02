// The MIT License (MIT)
//
// Copyright (c) 2017-2020 Alexander Grebenyuk (github.com/kean).

#if os(iOS) || os(tvOS)
import UIKit

internal protocol LayoutItem { // `UIView`, `UILayoutGuide`
    var superview: UIView? { get }
}

extension UIView: LayoutItem {}
extension UILayoutGuide: LayoutItem {
    internal var superview: UIView? { owningView }
}
#elseif os(macOS)
import AppKit

internal protocol LayoutItem { // `NSView`, `NSLayoutGuide`
    var superview: NSView? { get }
}

extension NSView: LayoutItem {}
extension NSLayoutGuide: LayoutItem {
    internal var superview: NSView? { owningView }
}
#endif

internal extension LayoutItem { // Align methods are available via `LayoutAnchors`
    @nonobjc var anchors: LayoutAnchors<Self> { LayoutAnchors(base: self) }
}

// MARK: - LayoutAnchors

internal struct LayoutAnchors<Base> {
    internal let base: Base
}

internal extension LayoutAnchors where Base: LayoutItem {

    // MARK: Anchors

    var top: Anchor<AnchorType.Edge, AnchorAxis.Vertical> { Anchor(base, .top) }
    var bottom: Anchor<AnchorType.Edge, AnchorAxis.Vertical> { Anchor(base, .bottom) }
    var left: Anchor<AnchorType.Edge, AnchorAxis.Horizontal> { Anchor(base, .left) }
    var right: Anchor<AnchorType.Edge, AnchorAxis.Horizontal> { Anchor(base, .right) }
    var leading: Anchor<AnchorType.Edge, AnchorAxis.Horizontal> { Anchor(base, .leading) }
    var trailing: Anchor<AnchorType.Edge, AnchorAxis.Horizontal> { Anchor(base, .trailing) }

    var centerX: Anchor<AnchorType.Center, AnchorAxis.Horizontal> { Anchor(base, .centerX) }
    var centerY: Anchor<AnchorType.Center, AnchorAxis.Vertical> { Anchor(base, .centerY) }

    var firstBaseline: Anchor<AnchorType.Baseline, AnchorAxis.Vertical> { Anchor(base, .firstBaseline) }
    var lastBaseline: Anchor<AnchorType.Baseline, AnchorAxis.Vertical> { Anchor(base, .lastBaseline) }

    var width: Anchor<AnchorType.Dimension, AnchorAxis.Horizontal> { Anchor(base, .width) }
    var height: Anchor<AnchorType.Dimension, AnchorAxis.Vertical> { Anchor(base, .height) }

    // MARK: Anchor Collections

    var edges: AnchorCollectionEdges { AnchorCollectionEdges(item: base) }
    var center: AnchorCollectionCenter { AnchorCollectionCenter(x: centerX, y: centerY) }
    var size: AnchorCollectionSize { AnchorCollectionSize(width: width, height: height) }
}

#if os(iOS) || os(tvOS)
internal extension LayoutAnchors where Base: UIView {
    var margins: LayoutAnchors<UILayoutGuide> { base.layoutMarginsGuide.anchors }
    var safeArea: LayoutAnchors<UILayoutGuide> { base.safeAreaLayoutGuide.anchors }
}
#endif

// MARK: - Anchors

// phantom types
internal enum AnchorAxis {
    internal class Horizontal {}
    internal class Vertical {}
}

internal enum AnchorType {
    internal class Dimension {}
    internal class Alignment {}
    internal class Center: Alignment {}
    internal class Edge: Alignment {}
    internal class Baseline: Alignment {}
}

/// An anchor represents one of the view's layout attributes (e.g. `left`,
/// `centerX`, `width`, etc). Use the anchor’s methods to construct constraints.
internal struct Anchor<Type, Axis> { // type and axis are phantom types
    fileprivate let item: LayoutItem
    fileprivate let attribute: NSLayoutConstraint.Attribute
    fileprivate let offset: CGFloat
    fileprivate let multiplier: CGFloat

    fileprivate init(_ item: LayoutItem, _ attribute: NSLayoutConstraint.Attribute, offset: CGFloat = 0, multiplier: CGFloat = 1) {
        self.item = item; self.attribute = attribute; self.offset = offset; self.multiplier = multiplier
    }

    /// Returns a new anchor offset by a given amount.
    ///
    /// - note: Consider using a convenience operator instead: `view.anchors.top + 10`.
    internal func offsetting(by offset: CGFloat) -> Anchor<Type, Axis> {
        Anchor<Type, Axis>(item, attribute, offset: self.offset + offset, multiplier: self.multiplier)
    }

    /// Returns a new anchor with a given multiplier.
    ///
    /// - note: Consider using a convenience operator instead: `view.anchors.height * 2`.
    internal func multiplied(by multiplier: CGFloat) -> Anchor<Type, Axis> {
        Anchor<Type, Axis>(item, attribute, offset: self.offset * multiplier, multiplier: self.multiplier * multiplier)
    }
}

internal func + <Type, Axis>(anchor: Anchor<Type, Axis>, offset: CGFloat) -> Anchor<Type, Axis> {
    anchor.offsetting(by: offset)
}

internal func - <Type, Axis>(anchor: Anchor<Type, Axis>, offset: CGFloat) -> Anchor<Type, Axis> {
    anchor.offsetting(by: -offset)
}

internal func * <Type, Axis>(anchor: Anchor<Type, Axis>, multiplier: CGFloat) -> Anchor<Type, Axis> {
    anchor.multiplied(by: multiplier)
}

// MARK: - Anchors (AnchorType.Alignment)

internal extension Anchor where Type: AnchorType.Alignment {
    @discardableResult func equal<Type: AnchorType.Alignment>(_ anchor: Anchor<Type, Axis>, constant: CGFloat = 0) -> NSLayoutConstraint {
        Constraints.constrain(self, anchor, constant: constant, relation: .equal)
    }

    @discardableResult func greaterThanOrEqual<Type: AnchorType.Alignment>(_ anchor: Anchor<Type, Axis>, constant: CGFloat = 0) -> NSLayoutConstraint {
        Constraints.constrain(self, anchor, constant: constant, relation: .greaterThanOrEqual)
    }

    @discardableResult func lessThanOrEqual<Type: AnchorType.Alignment>(_ anchor: Anchor<Type, Axis>, constant: CGFloat = 0) -> NSLayoutConstraint {
        Constraints.constrain(self, anchor, constant: constant, relation: .lessThanOrEqual)
    }
}

// MARK: - Anchors (AnchorType.Dimension)

internal extension Anchor where Type: AnchorType.Dimension {
    @discardableResult func equal<Type: AnchorType.Dimension, Axis>(_ anchor: Anchor<Type, Axis>, constant: CGFloat = 0) -> NSLayoutConstraint {
        Constraints.constrain(self, anchor, constant: constant, relation: .equal)
    }

    @discardableResult func greaterThanOrEqual<Type: AnchorType.Dimension, Axis>(_ anchor: Anchor<Type, Axis>, constant: CGFloat = 0) -> NSLayoutConstraint {
        Constraints.constrain(self, anchor, constant: constant, relation: .greaterThanOrEqual)
    }

    @discardableResult func lessThanOrEqual<Type: AnchorType.Dimension, Axis>(_ anchor: Anchor<Type, Axis>, constant: CGFloat = 0) -> NSLayoutConstraint {
        Constraints.constrain(self, anchor, constant: constant, relation: .lessThanOrEqual)
    }
}

// MARK: - Anchors (AnchorType.Dimension)

extension Anchor where Type: AnchorType.Dimension {
    @discardableResult internal func equal(_ constant: CGFloat) -> NSLayoutConstraint {
        Constraints.constrain(item: item, attribute: attribute, relatedBy: .equal, constant: constant)
    }

    @discardableResult internal func greaterThanOrEqual(_ constant: CGFloat) -> NSLayoutConstraint {
        Constraints.constrain(item: item, attribute: attribute, relatedBy: .greaterThanOrEqual, constant: constant)
    }

    @discardableResult internal func lessThanOrEqual(_ constant: CGFloat) -> NSLayoutConstraint {
        Constraints.constrain(item: item, attribute: attribute, relatedBy: .lessThanOrEqual, constant: constant)
    }
}

// MARK: - Anchors (AnchorType.Edge)

extension Anchor where Type: AnchorType.Edge {
    /// Pins the edge to the respected edges of the given container.
    @discardableResult internal func pin(to container: LayoutItem? = nil, inset: CGFloat = 0) -> NSLayoutConstraint {
        let isInverted = [.trailing, .right, .bottom].contains(attribute)
        return Constraints.constrain(self, toItem: container ?? item.superview!, attribute: attribute, constant: (isInverted ? -inset : inset))
    }

    /// Adds spacing between the current anchors.
    @discardableResult internal func spacing<Type: AnchorType.Edge>(_ spacing: CGFloat, to anchor: Anchor<Type, Axis>, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let isInverted = (attribute == .bottom && anchor.attribute == .top) ||
            (attribute == .right && anchor.attribute == .left) ||
            (attribute == .trailing && anchor.attribute == .leading)
        return Constraints.constrain(self, anchor, constant: isInverted ? -spacing : spacing, relation: isInverted ? relation.inverted : relation)
    }
}

// MARK: - Anchors (AnchorType.Center)

extension Anchor where Type: AnchorType.Center {
    /// Aligns the axis with a superview axis.
    @discardableResult internal func align(offset: CGFloat = 0) -> NSLayoutConstraint {
        Constraints.constrain(self, toItem: item.superview!, attribute: attribute, constant: offset)
    }
}

// MARK: - AnchorCollectionEdges

internal struct Alignmment {
    internal enum Horizontal {
        case fill, center, leading, trailing
    }
    internal enum Vertical {
        case fill, center, top, bottom
    }

    internal let horizontal: Horizontal
    internal let vertical: Vertical

    internal init(horizontal: Horizontal, vertical: Vertical) {
        (self.horizontal, self.vertical) = (horizontal, vertical)
    }

    internal static let fill = Alignmment(horizontal: .fill, vertical: .fill)
    internal static let center = Alignmment(horizontal: .center, vertical: .center)
    internal static let topLeading = Alignmment(horizontal: .leading, vertical: .top)
    internal static let leading = Alignmment(horizontal: .leading, vertical: .fill)
    internal static let bottomLeading = Alignmment(horizontal: .leading, vertical: .bottom)
    internal static let bottom = Alignmment(horizontal: .fill, vertical: .bottom)
    internal static let bottomTrailing = Alignmment(horizontal: .trailing, vertical: .bottom)
    internal static let trailing = Alignmment(horizontal: .trailing, vertical: .fill)
    internal static let topTrailing = Alignmment(horizontal: .trailing, vertical: .top)
    internal static let top = Alignmment(horizontal: .fill, vertical: .top)
}

internal struct AnchorCollectionEdges {
    fileprivate let item: LayoutItem
    fileprivate var isAbsolute = false

    // By default, edges use locale-specific `.leading` and `.trailing`
    internal func absolute() -> AnchorCollectionEdges {
        AnchorCollectionEdges(item: item, isAbsolute: true)
    }

    #if os(iOS) || os(tvOS)
    internal typealias Axis = NSLayoutConstraint.Axis
    #else
    internal typealias Axis = NSLayoutConstraint.Orientation
    #endif

    @discardableResult internal func pin(to item2: LayoutItem? = nil, insets: EdgeInsets = .zero, axis: Axis? = nil, alignment: Alignmment = .fill) -> [NSLayoutConstraint] {
        let item2 = item2 ?? item.superview!
        let left: NSLayoutConstraint.Attribute = isAbsolute ? .left : .leading
        let right: NSLayoutConstraint.Attribute = isAbsolute ? .right : .trailing
        var constraints = [NSLayoutConstraint]()

        func constrain(attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation, constant: CGFloat) {
            constraints.append(Constraints.constrain(item: item, attribute: attribute, relatedBy: relation, toItem: item2, attribute: attribute, multiplier: 1, constant: constant))
        }

        if axis == nil || axis == .horizontal {
            constrain(attribute: left, relation: alignment.horizontal == .fill || alignment.horizontal == .leading ? .equal : .greaterThanOrEqual, constant: insets.left)
            constrain(attribute: right, relation: alignment.horizontal == .fill || alignment.horizontal == .trailing ? .equal : .lessThanOrEqual, constant: -insets.right)
            if alignment.horizontal == .center {
                constrain(attribute: .centerX, relation: .equal, constant: 0)
            }
        }
        if axis == nil || axis == .vertical {
            constrain(attribute: .top, relation: alignment.vertical == .fill || alignment.vertical == .top ? .equal : .greaterThanOrEqual, constant: insets.top)
            constrain(attribute: .bottom, relation: alignment.vertical == .fill || alignment.vertical == .bottom ? .equal : .lessThanOrEqual, constant: -insets.bottom)
            if alignment.vertical == .center {
                constrain(attribute: .centerY, relation: .equal, constant: 0)
            }
        }
        return constraints
    }
}

// MARK: - AnchorCollectionCenter

internal struct AnchorCollectionCenter {
    fileprivate let x: Anchor<AnchorType.Center, AnchorAxis.Horizontal>
    fileprivate let y: Anchor<AnchorType.Center, AnchorAxis.Vertical>

    /// Centers the view in the superview.
    @discardableResult internal func align() -> [NSLayoutConstraint] {
        [x.align(), y.align()]
    }

    /// Makes the axis equal to the other collection of axis.
    @discardableResult internal func align<Item: LayoutItem>(with item: Item) -> [NSLayoutConstraint] {
        [x.equal(item.anchors.centerX), y.equal(item.anchors.centerY)]
    }
}

// MARK: - AnchorCollectionSize

internal struct AnchorCollectionSize {
    fileprivate let width: Anchor<AnchorType.Dimension, AnchorAxis.Horizontal>
    fileprivate let height: Anchor<AnchorType.Dimension, AnchorAxis.Vertical>

    /// Set the size of item.
    @discardableResult internal func equal(_ size: CGSize) -> [NSLayoutConstraint] {
        [width.equal(size.width), height.equal(size.height)]
    }

    /// Set the size of item.
    @discardableResult internal func greaterThanOrEqul(_ size: CGSize) -> [NSLayoutConstraint] {
        [width.greaterThanOrEqual(size.width), height.greaterThanOrEqual(size.height)]
    }

    /// Set the size of item.
    @discardableResult internal func lessThanOrEqual(_ size: CGSize) -> [NSLayoutConstraint] {
        [width.lessThanOrEqual(size.width), height.lessThanOrEqual(size.height)]
    }

    /// Makes the size of the item equal to the size of the other item.
    @discardableResult internal func equal<Item: LayoutItem>(_ item: Item, insets: CGSize = .zero, multiplier: CGFloat = 1) -> [NSLayoutConstraint] {
        [width.equal(item.anchors.width * multiplier - insets.width), height.equal(item.anchors.height * multiplier - insets.height)]
    }

    @discardableResult internal func greaterThanOrEqual<Item: LayoutItem>(_ item: Item, insets: CGSize = .zero, multiplier: CGFloat = 1) -> [NSLayoutConstraint] {
        [width.greaterThanOrEqual(item.anchors.width * multiplier - insets.width), height.greaterThanOrEqual(item.anchors.height * multiplier - insets.height)]
    }

    @discardableResult internal func lessThanOrEqual<Item: LayoutItem>(_ item: Item, insets: CGSize = .zero, multiplier: CGFloat = 1) -> [NSLayoutConstraint] {
        [width.lessThanOrEqual(item.anchors.width * multiplier - insets.width), height.lessThanOrEqual(item.anchors.height * multiplier - insets.height)]
    }
}

// MARK: - Constraints

internal final class Constraints {
    /// Returns all of the created constraints.
    internal private(set) var constraints = [NSLayoutConstraint]()

    /// All of the constraints created in the given closure are automatically
    /// activated at the same time. This is more efficient then installing them
    /// one-be-one. More importantly, it allows to make changes to the constraints
    /// before they are installed (e.g. change `priority`).
    ///
    /// - parameter activate: Set to `false` to disable automatic activation of
    /// constraints.
    @discardableResult internal init(activate: Bool = true, _ closure: () -> Void) {
        Constraints._stack.append(self)
        closure() // create constraints
        Constraints._stack.removeLast()
        if activate { NSLayoutConstraint.activate(constraints) }
    }

    /// Creates and automatically installs a constraint.
    fileprivate static func constrain(item item1: Any, attribute attr1: NSLayoutConstraint.Attribute, relatedBy relation: NSLayoutConstraint.Relation = .equal, toItem item2: Any? = nil, attribute attr2: NSLayoutConstraint.Attribute? = nil, multiplier: CGFloat = 1, constant: CGFloat = 0) -> NSLayoutConstraint {
        precondition(Thread.isMainThread, "Align APIs can only be used from the main thread")
        #if os(iOS) || os(tvOS)
        (item1 as? UIView)?.translatesAutoresizingMaskIntoConstraints = false
        #elseif os(macOS)
        (item1 as? NSView)?.translatesAutoresizingMaskIntoConstraints = false
        #endif
        let constraint = NSLayoutConstraint(item: item1, attribute: attr1, relatedBy: relation, toItem: item2, attribute: attr2 ?? .notAnAttribute, multiplier: multiplier, constant: constant)
        _install(constraint)
        return constraint
    }

    /// Creates and automatically installs a constraint between two anchors.
    fileprivate static func constrain<T1, A1, T2, A2>(_ lhs: Anchor<T1, A1>, _ rhs: Anchor<T2, A2>, constant: CGFloat = 0, multiplier: CGFloat = 1, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        constrain(item: lhs.item, attribute: lhs.attribute, relatedBy: relation, toItem: rhs.item, attribute: rhs.attribute, multiplier: (multiplier / lhs.multiplier) * rhs.multiplier, constant: constant - lhs.offset + rhs.offset)
    }

    /// Creates and automatically installs a constraint between an anchor and
    /// a given item.
    fileprivate static func constrain<T1, A1>(_ lhs: Anchor<T1, A1>, toItem item2: Any?, attribute attr2: NSLayoutConstraint.Attribute?, constant: CGFloat = 0, multiplier: CGFloat = 1, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        constrain(item: lhs.item, attribute: lhs.attribute, relatedBy: relation, toItem: item2, attribute: attr2, multiplier: multiplier / lhs.multiplier, constant: constant - lhs.offset)
    }

    private static var _stack = [Constraints]() // this is what enabled constraint auto-installing

    private static func _install(_ constraint: NSLayoutConstraint) {
        if let group = _stack.last {
            group.constraints.append(constraint)
        } else {
            constraint.isActive = true
        }
    }
}

extension Constraints {
    @discardableResult internal convenience init<A: LayoutItem>(for a: A, _ closure: (LayoutAnchors<A>) -> Void) {
        self.init { closure(a.anchors) }
    }

    @discardableResult internal convenience init<A: LayoutItem, B: LayoutItem>(for a: A, _ b: B, _ closure: (LayoutAnchors<A>, LayoutAnchors<B>) -> Void) {
        self.init { closure(a.anchors, b.anchors) }
    }

    @discardableResult internal convenience init<A: LayoutItem, B: LayoutItem, C: LayoutItem>(for a: A, _ b: B, _ c: C, _ closure: (LayoutAnchors<A>, LayoutAnchors<B>, LayoutAnchors<C>) -> Void) {
        self.init { closure(a.anchors, b.anchors, c.anchors) }
    }

    @discardableResult internal convenience init<A: LayoutItem, B: LayoutItem, C: LayoutItem, D: LayoutItem>(for a: A, _ b: B, _ c: C, _ d: D, _ closure: (LayoutAnchors<A>, LayoutAnchors<B>, LayoutAnchors<C>, LayoutAnchors<D>) -> Void) {
        self.init { closure(a.anchors, b.anchors, c.anchors, d.anchors) }
    }
}

// MARK: - Misc

#if os(iOS) || os(tvOS)
internal typealias EdgeInsets = UIEdgeInsets
#elseif os(macOS)
internal typealias EdgeInsets = NSEdgeInsets

internal extension NSEdgeInsets {
    static let zero = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
}
#endif

extension NSLayoutConstraint.Relation {
    fileprivate var inverted: NSLayoutConstraint.Relation {
        switch self {
        case .greaterThanOrEqual: return .lessThanOrEqual
        case .lessThanOrEqual: return .greaterThanOrEqual
        case .equal: return self
        @unknown default: return self
        }
    }
}

extension EdgeInsets {
    fileprivate func inset(for attribute: NSLayoutConstraint.Attribute, edge: Bool = false) -> CGFloat {
        switch attribute {
        case .top: return top; case .bottom: return edge ? -bottom : bottom
        case .left, .leading: return left
        case .right, .trailing: return edge ? -right : right
        default: return 0
        }
    }
}

// MARK: - Extensions

extension Anchor where Type: AnchorType.Edge {
    @discardableResult internal func safeAreaPin(inset: CGFloat = 0) -> NSLayoutConstraint {
        pin(to: item.superview!.safeAreaLayoutGuide, inset: inset)
    }
    
    @discardableResult internal func readableContentPin(inset: CGFloat = 0) -> NSLayoutConstraint {
        pin(to: item.superview!.readableContentGuide, inset: inset)
    }
    
    @discardableResult internal func marginsPin(inset: CGFloat = 0) -> NSLayoutConstraint {
        pin(to: item.superview!.layoutMarginsGuide, inset: inset)
    }
}

extension AnchorCollectionEdges {
    @discardableResult internal func safeAreaPin(insets: EdgeInsets = .zero, axis: Axis? = nil, alignment: Alignmment = .fill) -> [NSLayoutConstraint] {
        pin(to: item.superview!.safeAreaLayoutGuide, insets: insets, axis: axis, alignment: alignment)
    }
    
    @discardableResult internal func readableContentPin(insets: EdgeInsets = .zero, axis: Axis? = nil, alignment: Alignmment = .fill) -> [NSLayoutConstraint] {
        pin(to: item.superview!.readableContentGuide, insets: insets, axis: axis, alignment: alignment)
    }
    
    @discardableResult internal func marginsPin(insets: EdgeInsets = .zero, axis: Axis? = nil, alignment: Alignmment = .fill) -> [NSLayoutConstraint] {
        pin(to: item.superview!.layoutMarginsGuide, insets: insets, axis: axis, alignment: alignment)
    }
}
