//  DemoTableViewController.swift
//  SSRefresh
//
//  Created by  XMFraker on 2019/4/19
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      DemoTableViewController

import UIKit
import SSRefresh

class DemoTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "TabelViewController"
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "cell")
        
        // test  while close contentInsetAdjustmentBehavior
//        navigationController?.navigationBar.isTranslucent = false
//        if #available(iOS 11.0, *) {
//            tableView.contentInsetAdjustmentBehavior = .never
//        } else {
//            automaticallyAdjustsScrollViewInsets = false
//        }
        
        Language.setPreferredLanguage(.korean)
        
        var config = RefreshControl.Config.default()
        config.text = .header()
        config.contentInsetMargin = .zero
        tableView.sr.addRefresh(on: .top, config: config) { control in
            debugPrint("i am top refresh action")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.tableView.sr.top?.endRefresh()
                self.tableView.sr.bottom?.resetEmptyData()
            }
        }
        
        tableView.sr.addRefresh(on: .bottom) { control in
            debugPrint("i am bottom refresh action")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                control.endRefreshWithEmptyData()
            }
        }

//        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//            self.tableView.sr.top?.beginRefresh()
//        }
        self.tableView.sr.top?.beginRefresh()

        let footerView = UIView.init(frame: .init(x: 0.0, y: 0.0, width: 0.0, height: 34.0))
        tableView.tableFooterView = footerView
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 30
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "row \(indexPath.row)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print("click row \(indexPath.row)")
    }
}
