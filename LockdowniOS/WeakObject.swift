//
//  WeakObject.swift
//  Lockdown
//
//  Created by Aliaksandr Dvoineu on 4.05.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

final class WeakObject<T: AnyObject> {
    
    weak var object : T?
    
    init (_ object: T) {
        self.object = object
    }
}
