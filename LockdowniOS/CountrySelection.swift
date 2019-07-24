//
//  CountrySelection.swift
//  ConfirmediOS
//
//  Copyright © 2018 Confirmed Inc. All rights reserved.
//
// Flags - https://www.behance.net/gallery/11709619/181-Flat-World-Flags

import UIKit

class CountrySelection: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: - ACTION
    func initializeCountries(_ vpnView : UIView) {
        var vpnFrame = vpnView.frame
        vpnFrame.origin.y = vpnView.frame.size.height
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = vpnFrame
        tableView.frame.size.height -= 74
        
        loadEndpoints()
        
        tableView.rowHeight = 80
        vpnView.addSubview(tableView)
        super.awakeFromNib()
        
        tableView.reloadData()
    }
    
    func loadEndpoints() {
        items.removeAll()
        items = (VPNController.shared.currentProtocol?.supportedRegions)!
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    
    //MARK: - TABLEVIEW
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            return 80
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: .changeCountry, object: items[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.textLabel?.textColor = UIColor.white
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.textLabel?.textColor = UIColor.init(white: 0.25, alpha: 1.0)
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = CountryTableViewCell.init()//tableView.dequeueReusableCell(withIdentifier: "Cell")
        let meta = regionMetadata[items[indexPath.row]]!
        
        cell.imageView?.image = UIImage.init(named: meta.flagImagePath)
        if UI_USER_INTERFACE_IDIOM() == .pad {
            cell.textLabel?.font = UIFont.init(name: "Montserrat-Regular", size: 16)
        }
        else {
            cell.textLabel?.font = UIFont.init(name: "Montserrat-Regular", size: 14)
        }
        cell.textLabel?.textColor = UIColor.init(white: 0.25, alpha: 1.0)
        cell.imageView?.contentMode = .scaleToFill
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.tunnelsBlueColor
        cell.selectedBackgroundView = bgColorView
        
        
        cell.textLabel?.text = meta.countryName
        return cell
    }
    
    //MARK: - VARIABLES
    var items = [ServerRegion]() // = []
    let tableView = UITableView()
}
