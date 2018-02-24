//
//  FilesFlowViewController.swift
//  FilesBrowser
//
//  Created by Amir Abbas on 12/5/1396 AP.
//  Copyright © 1396 AP Mousavian. All rights reserved.
//

import UIKit
import FilesProvider

public enum AnchorView {
    case barButtonItem(button: UIBarButtonItem)
    indirect case viewWithFrame(view: UIView, frame: CGRect)
    indirect case view(view: UIView)
}

public protocol FilesViewController: class {
    var current: FileObject? { get }
    var files: [FileObject] { get set }
}

public protocol FilesFlowControllerDelegate: class {
    func filesFlow(_ filesVC: FilesFlowViewController, presentViewcontroller: UIViewController)
    func filesFlow(_ filesVC: FilesFlowViewController, presentFile: FileObject, anchor: AnchorView)
}

public protocol FilesViewControllerDelegate: class {
    func filesView(_ filesVC: FilesViewController, didSelected file: FileObject, anchor: AnchorView)
    
    func filesView(_ filesVC: FilesViewController, canLoadImageFor file: FileObject) -> Bool
    func filesView(_ filesVC: FilesViewController, loadImageFor file: FileObject,
                   completionHandler:  @escaping (UIImage?) -> Void)
    func filesView(_ filesVC: FilesViewController, availabledImageFor file: FileObject) -> UIImage?
    func filesView(_ filesVC: FilesViewController, cancelLoadImageFor file: FileObject)
    
    func filesView(_ filesVC: FilesViewController, delete file: FileObject, anchor: AnchorView)
    func filesView(_ filesVC: FilesViewController, copy file: FileObject, anchor: AnchorView)
    func filesView(_ filesVC: FilesViewController, move file: FileObject, anchor: AnchorView)
}

public enum LoadingStatus {
    case notLoaded
    case loading
    case succeed
    case failed
}

public enum presentingStyle {
    case simpleTableView
}

public class FilesFlowViewController: UIViewController, FilesViewControllerDelegate, FileProviderDelegate, FailedViewControllerDelegate {
    public let provider: FileProvider
    public let current: FileObject?
    public weak var delegate: FilesFlowControllerDelegate?
    
    public var loadingStatus: LoadingStatus = .notLoaded
    weak var currentPresentedController: FilesViewController?
    var filesList: [FileObject] = []
    
    init(provider: FileProvider, current: FileObject?, delegate: FilesFlowControllerDelegate?) {
        self.provider = provider
        self.current = current
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        loadFiles()
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        self.imagesCache.removeAll()
    }
    
    func loadFiles() {
        switch loadingStatus {
        case .notLoaded, .failed:
            transition(child: LoadingViewController())
            currentPresentedController = nil
        default:
            break
        }
        
        loadingStatus = .loading
        provider.contentsOfDirectory(path: current?.path ?? "") { (files, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.loadingStatus = .failed
                    self.transition(child: FailedViewController(message: error.localizedDescription))
                    self.currentPresentedController = nil
                }
            }
            
            DispatchQueue.main.async {
                self.loadingStatus = .succeed
                self.filesList = files
                self.reloadFiles()
            }
        }
    }
    
    fileprivate func reloadFiles() {
        guard loadingStatus == .succeed else { return }
        if let currentPresentedController = currentPresentedController {
            currentPresentedController.files = filesList
        } else {
            togglePresentation()
        }
    }
    
    fileprivate func togglePresentation() {
        let tableVC = FilesTableViewController(current: self.current, files: filesList, delegate: self)
        self.currentPresentedController = tableVC
        self.transition(child: tableVC)
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
    
    public func filesView(_ filesVC: FilesViewController, didSelected file: FileObject, anchor: AnchorView) {
        if file.isDirectory {
            let directoryVC = FilesFlowViewController(provider: provider, current: file, delegate: delegate)
            delegate?.filesFlow(self, presentViewcontroller: directoryVC)
        } else {
            delegate?.filesFlow(self, presentFile: file, anchor: anchor)
        }
    }
    
    public func filesView(_ filesVC: FilesViewController, delete file: FileObject, anchor: AnchorView) {
        provider.removeItem(path: file.path, completionHandler: nil)
    }
    
    public func filesView(_ filesVC: FilesViewController, copy file: FileObject, anchor: AnchorView) {
        //
    }
    
    public func filesView(_ filesVC: FilesViewController, move file: FileObject, anchor: AnchorView) {
        //
    }
    
    public func filesView(_ filesVC: FilesViewController, canLoadImageFor file: FileObject) -> Bool {
        return (provider as? ExtendedFileProvider)?.thumbnailOfFileSupported(path: file.path) ?? false
    }
    
    var pathsAreFetching: Set<String> = []
    var imagesCache: [String: UIImage] = [:]
    
    public func filesView(_ filesVC: FilesViewController, availabledImageFor file: FileObject) -> UIImage? {
        return imagesCache[file.path]
    }

    public func filesView(_ filesVC: FilesViewController, loadImageFor file: FileObject, completionHandler: @escaping (UIImage?) -> Void) {
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
    
    public func filesView(_ filesVC: FilesViewController, cancelLoadImageFor file: FileObject) {
        //
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
