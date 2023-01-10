//
//  WeakObject.swift
//  Lockdown
//
//  Created by Alexander Parshakov on 9/28/22
//  Copyright © 2022 Confirmed Inc. All rights reserved.
//

final class WeakObject<T: AnyObject> {
    
    weak var object : T?
    
    init (_ object: T) {
        self.object = object
    }
}
