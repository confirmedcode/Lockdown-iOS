//
//  CombinedProvider.swift
//  LockdownFirewallWidgetExtension
//
//  Created by Oleg Dreyman on 28.09.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import Foundation
import WidgetKit

struct CombinedProvider<Main: TimelineProvider, Supplemental: TimelineProvider>: TimelineProvider {
    
    let main: Main
    let supplemental: Supplemental
    
    struct Entry: TimelineEntry {
        var main: Main.Entry
        var supplemental: Supplemental.Entry
        
        var date: Date {
            return min(main.date, supplemental.date)
        }
    }
    
    func placeholder(in context: Context) -> Entry {
        let leftPlaceholder = main.placeholder(in: context)
        let rightPlaceholder = supplemental.placeholder(in: context)
        
        return Entry(main: leftPlaceholder, supplemental: rightPlaceholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        var leftSnapshot: Main.Entry?
        var rightSnapshot: Supplemental.Entry?
        let group = DispatchGroup()
        
        group.enter()
        main.getSnapshot(in: context) { (leftEntry) in
            leftSnapshot = leftEntry
            group.leave()
        }
        
        group.enter()
        supplemental.getSnapshot(in: context) { (rightEntry) in
            rightSnapshot = rightEntry
            group.leave()
        }
        
        dispatchPrecondition(condition: .onQueue(.main))
        group.notify(queue: .main) {
            completion(Entry(main: leftSnapshot!, supplemental: rightSnapshot!))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var leftTimeline: Timeline<Main.Entry>?
        var rightTimeline: Timeline<Supplemental.Entry>?
        let group = DispatchGroup()
        
        group.enter()
        main.getTimeline(in: context) { (leftEntry) in
            leftTimeline = leftEntry
            group.leave()
        }
        
        group.enter()
        supplemental.getTimeline(in: context) { (rightEntry) in
            rightTimeline = rightEntry
            group.leave()
        }
        
        dispatchPrecondition(condition: .onQueue(.main))
        group.notify(queue: .main) {
            let zippedEntries = zip(leftTimeline!.entries, rightTimeline!.entries)
            let timeline = Timeline<Entry>(entries: zippedEntries.map({ Entry.init(main: $0, supplemental: $1) }), policy: leftTimeline!.policy)
            completion(timeline)
        }
    }
}
