//
//  FAQController.swift
//  St Augustine CHS
//
//  Created by Jonathan Woo on 2019-10-23.
//  Copyright © 2019 St Augustine CHS. All rights reserved.
//

import UIKit

struct cellData{
    var opened = Bool()
    var title = String()
    var sectionData = [String]()
}

class FAQController: UITableViewController{
    
    var tableViewData = [cellData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        tableViewData = [cellData(opened: false, title: "Title 1", sectionData: ["cell1", "cell2", "cell3"]),
                         cellData(opened: false, title: "Title 1", sectionData: ["cell1", "cell2", "cell3"]),
                         cellData(opened: false, title: "Title 1", sectionData: ["cell1", "cell2", "cell3"]),
                         cellData(opened: false, title: "Title 1", sectionData: ["cell1", "cell2", "cell3"])]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSections (in tableView: UITableView) -> Int {
        return tableViewData.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if tableViewData[section].opened == true{
            return tableViewData[section].sectionData.count
        }else{
            return 1
        }
    }
    
    override func tableView(_ tableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        if indexPath.row == 0{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {return UITableViewCell()}
            cell.textLabel?.text = tableViewData[indexPath.section].title
            return cell
        }else{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {return UITableViewCell()}
            cell.textLabel?.text = tableViewData[indexPath.section].sectionData[indexPath.row]
            return cell
        }
    }
    
}
