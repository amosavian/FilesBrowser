//
//  ProvidersTableViewController.swift
//  FilesBrowserDemo
//
//  Created by Amir Abbas on 12/5/1396 AP.
//  Copyright © 1396 AP Mousavian. All rights reserved.
//

import UIKit
import FilesProvider
import FilesBrowser

class ProvidersTableViewController: UITableViewController {
    
    let providers: [String] = [
        "Documents",
        WebDAVFileProvider.type,
        "FTP Passive",
        "FTP Active",
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        navigationItem.title = "Providers"
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let contents = try? FileManager.default.contentsOfDirectory(at: docURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
        if let contents = contents, contents.count == 0 {
            try? FileManager.default.createDirectory(at: docURL.appendingPathComponent("Sample Folder"), withIntermediateDirectories: true, attributes: nil)
            try? "Hello world!".data(using: .utf8)?.write(to: docURL.appendingPathComponent("Sample File.txt"))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isToolbarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return providers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "providerType", for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = providers[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch providers[indexPath.row] {
        case "Documents":
            let provider = LocalFileProvider()
            let flowVC = FilesFlowViewController(provider: provider, current: nil, presentingStyle: .simpleTableView, delegate: nil)
            let filesVC = FilesViewController(flowViewController: flowVC)
            self.navigationController?.pushViewController(filesVC, animated: true)
        case WebDAVFileProvider.type:
            let url: URL? = nil
            let user: String? = nil
            let pass: String? = nil
            askCredentials(defaultServer: url, defaultUser: user, defaultPassword: pass, completionHandler: { (url, user, pass) in
                let credential = !user.isEmpty ? URLCredential(user: user, password: pass, persistence: .forSession) : nil
                guard let url = url,  let provider = WebDAVFileProvider(baseURL: url, credential: credential) else {
                    return
                }
               
                let flowVC = FilesFlowViewController(provider: provider, current: nil, presentingStyle: .simpleTableView, delegate: nil)
                let filesVC = FilesViewController(flowViewController: flowVC)
                self.navigationController?.pushViewController(filesVC, animated: true)
            })
        case "FTP Passive":
            let url = URL(string: "ftp://speedtest.tele2.net")!
            askCredentials(defaultServer: url, completionHandler: { (url, user, pass) in
                let credential = !user.isEmpty ? URLCredential(user: user, password: pass, persistence: .forSession) : nil
                guard let url = url, let provider = FTPFileProvider(baseURL: url, passive: true, credential: credential) else {
                    return
                }
                let flowVC = FilesFlowViewController(provider: provider, current: nil, presentingStyle: .simpleTableView, delegate: nil)
                let filesVC = FilesViewController(flowViewController: flowVC)
                self.navigationController?.pushViewController(filesVC, animated: true)
            })
        case "FTP Active":
            let url = URL(string: "ftp://speedtest.tele2.net")!
            askCredentials(defaultServer: url, completionHandler: { (url, user, pass) in
                let credential = !user.isEmpty ? URLCredential(user: user, password: pass, persistence: .forSession) : nil
                guard let url = url, let provider = FTPFileProvider(baseURL: url, passive: false, credential: credential) else {
                    return
                }
                let flowVC = FilesFlowViewController(provider: provider, current: nil, presentingStyle: .simpleTableView, delegate: nil)
                let filesVC = FilesViewController(flowViewController: flowVC)
                self.navigationController?.pushViewController(filesVC, animated: true)
            })
        default:
            break
        }
    }
    
    func askCredentials(defaultServer: URL? = nil, defaultUser: String? = nil, defaultPassword: String? = nil, completionHandler: @escaping (_ server: URL?, _ user: String, _ passwd: String) -> Void) {
        let alert = UIAlertController(title: "Enter credentials", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { [unowned alert] _ in
            let url = alert.textFields![0].text.flatMap(URL.init(string:))
            let user = alert.textFields![1].text ?? ""
            let pass = alert.textFields![2].text ?? ""
            completionHandler(url, user, pass)
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        alert.addTextField { (textField) in
            textField.text = defaultServer?.absoluteString
            textField.placeholder = "server address"
            textField.keyboardType = .URL
        }
        alert.addTextField { (textField) in
            textField.text = defaultUser
            textField.placeholder = "username"
            textField.keyboardType = .emailAddress
        }
        alert.addTextField { (textField) in
            textField.text = defaultPassword
            textField.placeholder = "password"
            textField.isSecureTextEntry = true
        }
        
        self.present(alert, animated: true, completion: nil)
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
