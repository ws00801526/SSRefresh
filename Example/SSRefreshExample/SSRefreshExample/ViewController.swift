//
//  ViewController.swift
//  SwiftyRefresh
//
//  Created by ws00801526 on 04/19/2019.
//  Copyright (c) 2019 ws00801526. All rights reserved.
//

import UIKit
import SSRefresh

class ViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        scrollView.sr.addRefresh(on: .left) { control in
            debugPrint("i am left action")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                control.endRefresh()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pushTableController(_ sender: UIButton) {
        
        let controller = DemoTableController(nibName: nil, bundle: nil)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func pushTableViewController(_ sender: UIButton) {
        
        let controller = DemoTableViewController(nibName: nil, bundle: nil)
        navigationController?.pushViewController(controller, animated: true)
    }
}

