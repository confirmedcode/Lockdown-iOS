//
//  LockdownFirewallWidget.swift
//  LockdownFirewallWidget
//
//  Created by Oleg Dreyman on 25.09.2020.
//  Copyright © 2020 Confirmed Inc. All rights reserved.
//

import WidgetKit
import SwiftUI

struct FirewallProvider: TimelineProvider {
    func placeholder(in context: Context) -> FirewallEntry {
        FirewallEntry(date: Date(), size: context.displaySize, isFirewallEnabled: false, dayMetricsString: "--")
    }

    func getSnapshot(in context: Context, completion: @escaping (FirewallEntry) -> ()) {
        let entry = FirewallEntry(date: Date(), size: context.displaySize, isFirewallEnabled: LatestKnowledge.isFirewallEnabled, dayMetricsString: getDayMetricsString(commas: true))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [FirewallEntry] = []
        
        let currentDate = Date()
        let entry = FirewallEntry(date: Date(), size: context.displaySize, isFirewallEnabled: LatestKnowledge.isFirewallEnabled, dayMetricsString: getDayMetricsString(commas: true))
        entries.append(entry)

        let timeline = Timeline(
            entries: entries,
            policy: .after(Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!)
        )
        completion(timeline)
    }
}

struct FirewallEntry: TimelineEntry {
    let date: Date
    let size: CGSize
    let isFirewallEnabled: Bool
    let dayMetricsString: String
    
    var buttonColor: Color {
        if isFirewallEnabled {
            return .confirmedBlue
        } else {
            return Color(.systemGray)
        }
    }
}

struct LockdownFirewallWidgetEntryView : View {
    var entry: FirewallProvider.Entry

    var body: some View {
        VStack(spacing: 0) {
            LoadingCircle(
                tunnelState: TunnelState(
                    color: entry.buttonColor,
                    circleColor: entry.buttonColor
                ),
                side: entry.size.height,
                link: "lockdown://toggleFirewall"
            )
            .padding(EdgeInsets(top: 12, leading: 0, bottom: 2, trailing: 0))
            if entry.isFirewallEnabled {
                StatusLabel(text: NSLocalizedString("FIREWALL ON", comment: ""), color: .confirmedBlue)
            } else {
                StatusLabel(text: NSLocalizedString("FIREWALL OFF", comment: ""), color: .flatRed)
            }
            if entry.size.height < 160 {
                Spacer().frame(minHeight: 4)
            } else {
                Spacer()
            }
            Link(destination: URL(string: "lockdown://showMetrics")!, label: {
                VStack(spacing: 0) {
                    Text(entry.dayMetricsString)
                        .font(.system(size: 21, weight: .semibold))
                    Text(NSLocalizedString("Blocked Today", comment: ""))
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.bottom, 12)
            })
        }.frame(width: entry.size.height, height: entry.size.height)
    }
}

struct VPNProvider: TimelineProvider {
    func placeholder(in context: Context) -> VPNEntry {
        VPNEntry(date: Date(), size: context.displaySize, isVPNEnabled: false, vpnRegion: VPNRegion())
    }

    func getSnapshot(in context: Context, completion: @escaping (VPNEntry) -> ()) {
        let entry = VPNEntry(date: Date(), size: context.displaySize, isVPNEnabled: LatestKnowledge.isVPNEnabled, vpnRegion: getSavedVPNRegion())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [VPNEntry] = []
        
        let currentDate = Date()
        let entry = VPNEntry(date: Date(), size: context.displaySize, isVPNEnabled: LatestKnowledge.isVPNEnabled, vpnRegion: getSavedVPNRegion())
        entries.append(entry)

        let timeline = Timeline(
            entries: entries,
            policy: .after(Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!)
        )
        completion(timeline)
    }
}

struct VPNEntry: TimelineEntry {
    let date: Date
    let size: CGSize
    let isVPNEnabled: Bool
    let vpnRegion: VPNRegion
    
    var buttonColor: Color {
        if isVPNEnabled {
            return .confirmedBlue
        } else {
            return Color(.systemGray)
        }
    }
}

struct LockdownVPNWidgetEntryView : View {
    var entry: VPNProvider.Entry
    
    var body: some View {
        VStack(spacing: 0) {
            LoadingCircle(
                tunnelState: TunnelState(
                    color: entry.buttonColor,
                    circleColor: entry.buttonColor
                ),
                side: entry.size.height,
                link: "lockdown://toggleVPN"
            )
            .padding(EdgeInsets(top: 12, leading: 0, bottom: 2, trailing: 0))
            if entry.isVPNEnabled {
                StatusLabel(text: NSLocalizedString("TUNNEL ON", comment: ""), color: .confirmedBlue)
            } else {
                StatusLabel(text: NSLocalizedString("TUNNEL OFF", comment: ""), color: .flatRed)
            }
            if entry.size.height < 160 {
                Spacer().frame(minHeight: 4)
            } else {
                Spacer()
            }
            Link(destination: URL(string: "lockdown://changeVPNregion")!, label: {
                VStack(spacing: 0) {
                    Text(entry.vpnRegion.regionFlagEmoji)
                        .font(.system(size: 21, weight: .semibold))
                    Text(entry.vpnRegion.regionDisplayNameShort)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.bottom, 12)
            })
        }.frame(width: entry.size.height, height: entry.size.height)
    }
}

struct CombinedWidgetView: View {
    let firewall: FirewallEntry
    let vpn: VPNEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            LockdownFirewallWidgetEntryView(entry: firewall)
            LockdownVPNWidgetEntryView(entry: vpn)
        }
        .frame(minWidth: firewall.size.width, minHeight: firewall.size.height)
    }
}

@main
struct LockdownWidgetBundle: WidgetBundle {
    
    @WidgetBundleBuilder
    var body: some Widget {
        LockdownFirewallWidget()
        LockdownVPNWidget()
        LockdownCombinedWidget()
    }
}

struct LockdownFirewallWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "LockdownFirewallWidget",
            provider: FirewallProvider(),
            content: { entry in
                ZStack {
                    Color.panelBackground
                    LockdownFirewallWidgetEntryView(entry: entry)
                }
            }
        )
        .configurationDisplayName("Firewall")
        .supportedFamilies([.systemSmall])
    }
}

struct LockdownVPNWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "LockdownVPNWidget",
            provider: VPNProvider(),
            content: { entry in
                ZStack {
                    Color.panelBackground
                    LockdownVPNWidgetEntryView(entry: entry)
                }
            }
        )
        .configurationDisplayName("Secure Tunnel")
        .supportedFamilies([.systemSmall])
    }
}

struct LockdownCombinedWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "LockdownCombinedWidget",
            provider: CombinedProvider(main: FirewallProvider(), supplemental: VPNProvider()),
            content: { entry in
                ZStack {
                    Color.panelBackground
                    CombinedWidgetView(firewall: entry.main, vpn: entry.supplemental)
                }
            }
        )
        .configurationDisplayName("Firewall + Tunnel")
        .supportedFamilies([.systemMedium])
    }
}
