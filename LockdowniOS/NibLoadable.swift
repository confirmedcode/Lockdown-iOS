//
//  NibLoadable.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 9/5/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
// 

import Foundation
import UIKit

public protocol NibLoadable: AnyObject {
  /// The nib file to use to load a new instance of the View designed in a XIB
  static var nib: UINib { get }
}

// MARK: Default implementation
public extension NibLoadable {
  /// By default, use the nib which have the same name as the name of the class,
  /// and located in the bundle of that class
  static var nib: UINib {
    return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
  }
}

// MARK: Support for instantiation from NIB
public extension NibLoadable where Self: UIView {
  /**
   Returns a `UIView` object instantiated from nib
   - returns: A `NibLoadable`, `UIView` instance
   */
  static func loadFromNib() -> Self {
    guard let view = nib.instantiate(withOwner: nil, options: nil).first as? Self else {
      fatalError("The nib \(nib) expected its root view to be of type \(self)")
    }
    return view
  }
}
