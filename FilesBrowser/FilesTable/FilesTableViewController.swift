//
//  FilesTableViewController.swift
//  FilesBrowser
//
//  Copyright © 2018 Mousavian. All rights reserved.
//

import UIKit
import MobileCoreServices
import FilesProvider

class FilesTableViewController: UITableViewController, UITableViewDataSourcePrefetching, FilesViewControllerType {
    
    unowned var delegate: FilesViewControllerDelegate
    let current: FileObject?
    var files: [FileObject] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    var presentingIndexPath: IndexPath? {
        get {
            return tableView.indexPathsForVisibleRows?.first
        }
        set {
            presentingIndexPath.map {
                self.tableView.scrollToRow(at: $0, at: .top, animated: false)
            }
        }
    }
    
    var selectedFiles: [FileObject] {
        get {
            return selectedIndices.map({ files[$0] })
        }
        set {
            let selected = newValue.flatMap({ files.index(of: $0) })
            self.selectedIndices = selected
        }
    }
    
    var selectedIndices: [Int] {
        get {
            return tableView.indexPathsForSelectedRows?.map({ $0.item }) ?? []
        }
        set {
            for itemIndex in 0..<files.count {
                let indexPath = IndexPath(item: itemIndex, section: 0)
                if newValue.contains(itemIndex) {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                } else {
                    tableView.deselectRow(at: indexPath, animated: false)
                }
            }
        }
    }
    
    public init(current: FileObject?, files: [FileObject], delegate: FilesViewControllerDelegate) {
        self.current = current
        self.files = files
        self.delegate = delegate
        super.init(style: .plain)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.title = current?.name
        let bundle = Bundle(for: FileTableViewCell.self)
        tableView.register(UINib(nibName: "FileTableViewCell", bundle: bundle), forCellReuseIdentifier: "fileTableCell")
        tableView.estimatedRowHeight = 66
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsMultipleSelection = false
        tableView.allowsMultipleSelectionDuringEditing = true
        if #available(iOS 10.0, *) {
            tableView.prefetchDataSource = self
        }
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileTableCell", for: indexPath) as! FileTableViewCell
        let file = files[indexPath.row]
        
        // Configure the cell...
        cell.fileName.text = file.name
        let typeDesc = file.isDirectory ? "Folder" : file.size.formatByte
        let dateDesc = (file.modifiedDate?.format(dateStyle: .medium, timeStyle: .none, separator: "")).map { ", \($0)" } ?? ""
        cell.fileDescription.text = "\(typeDesc)\(dateDesc)"
        
        let bundle = Bundle(for: FilesTableViewController.self)
        if file.isDirectory {
            cell.fileImageView.image = UIImage.init(named: "GeneralFolder", in: bundle, compatibleWith: nil)
        } else {
            cell.fileImageView.image = UIImage.init(named: "GeneralFile", in: bundle, compatibleWith: nil)
            let fileExtension = (file.name as NSString).pathExtension
            let uti = (UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeRetainedValue() ?? kUTTypeData) as String
            docic.name = "dummy"
            docic.uti = uti
            if docic.icons.count > 0, let cgimage = docic.icons.last?.cgImage {
                let nicon = UIImage(cgImage: cgimage)
                cell.fileImageView.image = nicon
            }
        }
        
        cell.accessoryType = file.isDirectory ? .detailDisclosureButton : .detailButton
        
        if let imageCached = delegate.filesView(self, availabledImageFor: file) {
            cell.fileImageView.image = imageCached
        } else if delegate.filesView(self, canLoadImageFor: file) {
            delegate.filesView(self, loadImageFor: file, completionHandler: { _ in
                // Use cached image
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [indexPath], with: .none)
                }
            })
        }
        
        return cell
    }
    
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.isEditing {
            return
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        let file = files[indexPath.row]
        delegate.filesView(self, didSelected: file, anchor: .view(view: cell.contentView))
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let file = files[indexPath.row]
            guard delegate.filesView(self, canLoadImageFor: file) else {
                continue
            }
            delegate.filesView(self, loadImageFor: file, completionHandler: { _ in
                return
            })
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let file = files[indexPath.row]
            delegate.filesView(self, cancelLoadImageFor: file)
        }
    }
    
    public override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let file = files[indexPath.row]
        
        let deleteAction = UITableViewRowAction.init(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { (rwowAction, indexPath) in
            let file = self.files[indexPath.row]
            let cell = tableView.cellForRow(at: indexPath)
            self.delegate.filesView(self, delete: file, anchor: AnchorView.view(view: cell ?? self.view))
        }
        
        var actions = [UITableViewRowAction]()
        if !file.isReadOnly {
            actions.append(deleteAction)
        }
        return actions
    }
    
    // MARK: - Toolbar
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}
