//
//  ItemsVC.swift
//  CodeReader
//
//  Created by Sayantan Chakraborty on 04/05/17.
//  Copyright © 2017 Sayantan Chakraborty. All rights reserved.
//

import UIKit
import CoreData

class ItemsVC: UIViewController,UITableViewDataSource,UITableViewDelegate {

    @IBOutlet weak var itemtbl: UITableView!
    var items : [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let refreshControl = UIRefreshControl()
        let title = NSLocalizedString("Pull To Refresh", comment: "Pull to Refresh")
        refreshControl.attributedTitle = NSAttributedString(string: title)
        refreshControl.addTarget(self, action: #selector(ItemsVC.fetchData), for: .valueChanged)
        itemtbl.refreshControl = refreshControl
        
        getProductsData()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func fetchData(){
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Products")
        
        do {
            items = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        itemtbl.reloadData()
        itemtbl.refreshControl?.endRefreshing()
    }
    
    // MARK: - Table View Datasource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemsCell", for: indexPath)
        let product = items[indexPath.row]
        cell.textLabel?.text = product.value(forKeyPath: "productDescription") as? String
        return cell
    }
    
    // MARK: - Button Actions
    
    @IBAction func addItems(_ sender: UIButton) {
        let scanVc = BarCodeScanner()
        scanVc.isActionAdd = true
        scanVc.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        scanVc.modalTransitionStyle = .coverVertical
        present(scanVc, animated: true, completion: nil)
    }
    
    @IBAction func removeItems(_ sender: UIButton) {
        let scanVc = BarCodeScanner()
        scanVc.isActionAdd = false
        scanVc.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        scanVc.modalTransitionStyle = .coverVertical
        present(scanVc, animated: true, completion: nil)
    }
    
    // MARK: - Bluemix Calls
    
    func getProductsData(){
        let url = URL(string: "https://autobillingsystem.mybluemix.net/listproduct")
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            guard error == nil else{
                print(error?.localizedDescription ?? "Error")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                print(json)
                
            }catch let error as NSError{
                print(error)
            }
        }
        
        task.resume()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
