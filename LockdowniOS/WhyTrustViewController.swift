//
//  WhyTrustViewController.swift
//  Lockdown
//
//  Created by Johnny Lin on 8/9/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import Foundation
import UIKit

class WhyTrustViewController: BaseViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var pages:[UIViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let page1 = mainStoryboard.instantiateViewController(withIdentifier: "whytrust1")
        let page2 = mainStoryboard.instantiateViewController(withIdentifier: "whytrust2")
        pages = [page1, page2]
        
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(pages.count), height: view.frame.height)
        scrollView.isPagingEnabled = true
        
        for i in 0 ..< pages.count {
            pages[i].view.frame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: view.frame.width, height: view.frame.height)
            scrollView.addSubview(pages[i].view)
        }
        
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        
        scrollView.delegate = self
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
        pageControl.currentPage = Int(pageIndex)
    }
    
}
