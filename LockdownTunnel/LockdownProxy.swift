import Foundation
import NEKit

/// The HTTP proxy server.
public final class LockdownProxy: GCDProxyServer {
    /**
     Create an instance of HTTP proxy server.
     
     - parameter address: The address of proxy server.
     - parameter port:    The port of proxy server.
     */
    override public init(address: IPAddress?, port: NEKit.Port) {
        super.init(address: address, port: port)
    }
    
    /**
     Handle the new accepted socket as a HTTP proxy connection.
     
     - parameter socket: The accepted socket.
     */
    override public func handleNewGCDSocket(_ socket: GCDTCPSocket) {
        let defaults = Global.sharedUserDefaults()
        
        let metricsEnabled = defaults.bool(forKey: "LockdownMetricsEnabled")
        if metricsEnabled {
            if metricsEnabled {
                let date = Date()
                let calendar = Calendar.current
                
                //set total
                let kTotalMetrics = "LockdownTotalMetrics"
                let total = defaults.integer(forKey: kTotalMetrics)
                defaults.set(Int(total + 1), forKey: kTotalMetrics)
                
                //set this hour
                let kDayMetrics = "LockdownDayMetrics"
                let kActiveDay = "LockdownActiveDay"
                
                let currentDay = calendar.component(.day, from: date)
                if currentDay != defaults.integer(forKey: kActiveDay) { //reset metrics on new day
                    defaults.set(0, forKey: kDayMetrics)
                    defaults.set(currentDay, forKey: kActiveDay)
                }
                
                let day = defaults.integer(forKey: kDayMetrics)
                defaults.set(Int(day + 1), forKey: kDayMetrics)
                
                //set this week
                let kWeekMetrics = "LockdownWeekMetrics"
                let kActiveWeek = "LockdownActiveWeek"
                
                let currentWeek = calendar.component(.weekOfYear, from: date)
                if currentWeek != defaults.integer(forKey: kActiveWeek) { //reset metrics on new day
                    defaults.set(0, forKey: kWeekMetrics)
                    defaults.set(currentWeek, forKey: kActiveWeek)
                }
                
                let weekly = defaults.integer(forKey: kWeekMetrics)
                defaults.set(Int(weekly + 1), forKey: kWeekMetrics)
                
            }
        }
        
    }
}
