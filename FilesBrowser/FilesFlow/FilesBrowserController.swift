//
//  FilesBrowserController.swift
//  FilesBrowser
//
//  Copyright © 2018 Mousavian. All rights reserved.
//

import UIKit
import FilesProvider

public enum AnchorView {
    case barButtonItem(button: UIBarButtonItem)
    indirect case viewWithFrame(view: UIView, frame: CGRect)
    indirect case view(view: UIView)
}

var docic = UIDocumentInteractionController()

public class FilesBrowserController: UIViewController, FilesViewControllerType, FilesViewControllerDelegate, FileProviderDelegate, FailedViewControllerDelegate {
    
    public enum LoadingStatus {
        case notLoaded
        case loading
        case succeed
        case failed
    }
    
    public enum PresentingStyle {
        case simpleTableView
    }
    
    public let provider: FileProvider
    public let current: FileObject?
    public weak var delegate: FilesBrowserControllerDelegate?
    
    public var sort: FileObjectSorting?
    public var filterHandler: ((_ isIncluded: FileObject) -> Bool)?
    
    public var loadingStatus: LoadingStatus = .notLoaded {
        didSet {
            delegate?.filesBrowser(self, loadingStatusDidBecame: loadingStatus)
        }
    }
    
    public var files: [FileObject] = [] {
        didSet {
            delegate?.filesBrowser(self, filesListUpdated: files)
        }
    }
    
    public var presentingStyle: PresentingStyle {
        didSet {
            guard oldValue != presentingStyle else { return }
            self.togglePresentation(to: self.presentingStyle)
        }
    }
    
    public var selectedFiles: [FileObject] {
        get {
            return currentPresentedController?.selectedFiles ?? []
        }
        set {
            currentPresentedController?.selectedFiles = newValue
        }
    }
    
    public var selectedIndices: [Int] {
        get {
            return currentPresentedController?.selectedIndices ?? []
        }
        set {
            currentPresentedController?.selectedIndices = newValue
        }
    }
    
    weak var currentPresentedController: FilesViewControllerType?
    
    public init(provider: FileProvider, current: FileObject?, presentingStyle: PresentingStyle, delegate: FilesBrowserControllerDelegate?) {
        self.provider = provider
        self.current = current
        self.presentingStyle = presentingStyle
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        self.title = current?.name ?? provider.type
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        provider.delegate = self
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        loadFiles()
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        self.imagesCache.removeAll()
    }
    
    public override func setEditing(_ editing: Bool, animated: Bool) {
        for vc in self.childViewControllers {
            vc.setEditing(editing, animated: animated)
        }
        super.setEditing(editing, animated: animated)
    }
    
    public var presentingIndexPath: IndexPath? {
        get {
            return currentPresentedController?.presentingIndexPath
        }
        set {
            currentPresentedController?.presentingIndexPath = self.presentingIndexPath
        }
    }
    
    func loadFiles() {
        switch loadingStatus {
        case .notLoaded, .failed:
            transition(duration: 0.0, child: LoadingViewController())
            currentPresentedController = nil
        default:
            break
        }
        
        loadingStatus = .loading
        provider.contentsOfDirectory(path: current?.path ?? "") { (files, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.setToolbarItems([], animated: true)
                    self.loadingStatus = .failed
                    let failedVC = FailedViewController(message: error.localizedDescription)
                    failedVC.delegate = self
                    self.transition(child: failedVC)
                    self.currentPresentedController = nil
                }
                return
            }
            
            let sorted = self.sort?.sort(files) ?? files
            let filtered = self.filterHandler.map( { sorted.filter($0) } ) ?? sorted
            
            DispatchQueue.main.async {
                self.setToolbarItems(self.instantiateToolbarItems(), animated: true)
                self.loadingStatus = .succeed
                self.files = filtered
                self.reloadFiles()
            }
        }
    }
    
    fileprivate func reloadFiles() {
        guard loadingStatus == .succeed else { return }
        if let currentPresentedController = currentPresentedController,
            currentPresentedController.current == current, !files.isEmpty {
            currentPresentedController.files = self.files
        } else {
            togglePresentation(to: nil)
        }
    }
    
    fileprivate func togglePresentation(to style: PresentingStyle?) {
        guard !files.isEmpty else {
            let nofileVC = CommentViewController(message: NSLocalizedString("No file exists.", comment: "Files view"))
            self.transition(child: nofileVC)
            return
        }
        
        let presentingIndexPath = self.presentingIndexPath
        switch style {
        case .simpleTableView?:
            let tableVC = FilesTableViewController(current: self.current, files: files, delegate: self)
            self.currentPresentedController = tableVC
            tableVC.presentingIndexPath = presentingIndexPath
            self.transition(duration: 0.0, child: tableVC)
        case .none:
            togglePresentation(to: self.presentingStyle)
        }
    }
    
    internal func failedViewControllerTryAgainTapped(_ failedVC: FailedViewController) {
        loadFiles()
    }
    
    public func fileproviderSucceed(_ fileProvider: FileProviderOperations, operation: FileOperationType) {
        let monitored = (provider as? FileProviderMonitor)?.isRegisteredForNotification(path: self.current?.path ?? "") ?? false
        if !monitored {
            guard self.loadingStatus != .loading else { return }
            DispatchQueue.main.async {
                self.loadFiles()
            }
        }
    }
    
    public func fileproviderFailed(_ fileProvider: FileProviderOperations, operation: FileOperationType, error: Error) {
        let alert = UIAlertController.init(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    public func fileproviderProgress(_ fileProvider: FileProviderOperations, operation: FileOperationType, progress: Float) {
        let percentDesc = NumberFormatter.localizedString(from: progress as NSNumber, number: .percent)
        print(operation.actionDescription, percentDesc)
    }
    
    public func filesView(_ filesVC: FilesViewControllerType, didSelected file: FileObject, anchor: AnchorView) {
        if self.isEditing {
            delegate?.filesBrowser(self, selectionChangedTo: self.selectedFiles)
        } else {
            delegate?.filesBrowser(self, present: file, anchor: anchor)
        }
    }
    
    func filesView(_ filesVC: FilesViewControllerType, didDeselected file: FileObject, anchor: AnchorView) {
        if self.isEditing {
            delegate?.filesBrowser(self, selectionChangedTo: self.selectedFiles)
        }
    }
    
    func filesView(_ filesVC: FilesViewControllerType, createFolder name: String) {
        
    }
    
    func filesView(_ filesVC: FilesViewControllerType, delete file: FileObject, anchor: AnchorView) {
        provider.removeItem(path: file.path, completionHandler: nil)
    }
    
    func filesView(_ filesVC: FilesViewControllerType, copy file: FileObject, anchor: AnchorView) {
        //
    }
    
    func filesView(_ filesVC: FilesViewControllerType, move file: FileObject, anchor: AnchorView) {
        //
    }
    
    func filesView(_ filesVC: FilesViewControllerType, canLoadImageFor file: FileObject) -> Bool {
        return (provider as? ExtendedFileProvider)?.thumbnailOfFileSupported(path: file.path) ?? false
    }
    
    var pathsAreFetching: Set<String> = []
    var imagesCache: [String: UIImage] = [:]
    
    func filesView(_ filesVC: FilesViewControllerType, availabledImageFor file: FileObject) -> UIImage? {
        return imagesCache[file.path]
    }

    func filesView(_ filesVC: FilesViewControllerType, loadImageFor file: FileObject, completionHandler: @escaping (UIImage?) -> Void) {
        if pathsAreFetching.contains(file.path) {
            return
        }
        
        let dimension = CGSize(width: 64, height: 64)
        pathsAreFetching.insert(file.path)
        _=(provider as? ExtendedFileProvider)?.thumbnailOfFile(path: file.path, dimension: dimension, completionHandler: { (image, error) in
            DispatchQueue.main.async {
                self.imagesCache[file.path] = image
                completionHandler(image)
                self.pathsAreFetching.remove(file.path)
            }
        })
    }
    
    func filesView(_ filesVC: FilesViewControllerType, cancelLoadImageFor file: FileObject) {
        //
    }
    
    var toolbarAddButton: UIBarButtonItem?
    var toolbarActionButton: UIBarButtonItem?
    var toolbarTrashButton: UIBarButtonItem?
    
    func instantiateToolbarItems() -> [UIBarButtonItem] {
        toolbarAddButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createFolder(_:)))
        toolbarActionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(action(_:)))
        toolbarTrashButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(trash(_:)))
        //trashBtn.tintColor = .red
        let space = UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        return [toolbarAddButton!, space, toolbarActionButton!, space, toolbarTrashButton!]
    }
    
    @objc func createFolder(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Create New Folder", message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { [unowned alert] _ in
            if let name = alert.textFields![0].text, !name.isEmpty {
                self.provider.create(folder: name, at: self.current?.path ?? "", completionHandler: nil)
            }
        }))
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Folder name", comment: "New folder placeholder")
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func action(_ sender: UIBarButtonItem) {
        //
    }
    
    @objc func trash(_ sender: UIBarButtonItem) {
        for file in self.selectedFiles {
            provider.removeItem(path: file.path, completionHandler: nil)
        }
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
