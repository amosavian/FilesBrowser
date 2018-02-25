//
//  FilesViewController.swift
//  FilesBrowserDemo
//
//  Created by Amir Abbas on 12/5/1396 AP.
//  Copyright © 1396 AP Mousavian. All rights reserved.
//

import UIKit
import FilesProvider
import FilesBrowser
import QuickLook

class FilesViewController: UIViewController, FilesBrowserControllerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    var browserController: FilesBrowserController
    
    var quickLook: QLPreviewController?
    var quickLookItems: [(file: FileObject, anchor: AnchorView?)] = []
    
    init(browserController: FilesBrowserController) {
        self.browserController = browserController
        let bundle = Bundle(for: FilesViewController.self)
        super.init(nibName: nil, bundle: bundle)
        self.navigationItem.title = browserController.title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        browserController.delegate = self
        self.transition(child: browserController)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isToolbarHidden = false
    }
    override func viewWillDisappear(_ animated: Bool) {
        //navigationController?.isToolbarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        for vc in self.childViewControllers {
            vc.setEditing(editing, animated: animated)
        }
        super.setEditing(editing, animated: animated)
    }
    
    func filesBrowser(_ filesVC: FilesBrowserController, present file: FileObject, anchor: AnchorView) {
        if file.isDirectory {
            let browserVC = FilesBrowserController(provider: filesVC.provider, current: file, presentingStyle: filesVC.presentingStyle, delegate: filesVC.delegate)
            browserVC.sort = filesVC.sort
            let filesVC = FilesViewController(browserController: browserVC)
            self.navigationController?.pushViewController(filesVC, animated: true)
        } else if file.url.isFileURL, QLPreviewController.canPreview(file.url.absoluteURL as QLPreviewItem) {
            quickLookItems = [(file, anchor)]
            self.quickLook = QLPreviewController()
            quickLook!.dataSource = self
            quickLook!.delegate = self
            self.present(quickLook!, animated: true, completion: nil)
        }
    }
    
    func filesBrowser(_ filesBrowser: FilesBrowserController, selectionChangedTo files: [FileObject]) {
        //
    }
    
    func filesBrowser(_ filesBrowser: FilesBrowserController, filesListUpdated files: [FileObject]) {
        //
    }
    
    func filesBrowser(_ filesBrowser: FilesBrowserController, loadingStatusDidBecame status: FilesBrowserController.LoadingStatus) {
        switch status {
        case .succeed:
            self.navigationItem.rightBarButtonItem = self.editButtonItem
            self.setToolbarItems(filesBrowser.toolbarItems, animated: true)
        default:
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    // MARK: - QuickLook
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        // QuickLook bug prevents previewing relative urls. So absolute url is being passed
        return quickLookItems[index].file.url.absoluteURL as QLPreviewItem
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return quickLookItems.count
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        quickLookItems = []
    }
    
    /*func previewController(_ controller: QLPreviewController, transitionImageFor item: QLPreviewItem, contentRect: UnsafeMutablePointer<CGRect>) -> UIImage {
        guard let anchor = quickLookItems.first(where: { $0.file.url.absoluteURL == item.previewItemURL })?.anchor else {
            return UIImage()
        }
        
        switch anchor {
        case .view(view: let view), .viewWithFrame(view: let view, frame: _):
            for subview in view.subviews where subview is UIImageView {
                return (subview as! UIImageView).image ?? UIImage()
            }
        default:
            break
        }
        return UIImage()
    }*/
    
    func previewController(_ controller: QLPreviewController, transitionViewFor item: QLPreviewItem) -> UIView? {
        guard let anchor = quickLookItems.first(where: { $0.file.url.absoluteURL == item.previewItemURL })?.anchor else {
            return nil
        }
        
        switch anchor {
        case .view(view: let view):
            var view = view
            // Passing image view instead of entire cell
            for subview in view.subviews where subview is UIImageView {
                view = subview
                break
            }
            return view
        case .viewWithFrame(view: let view, frame: _):
            return view
        default:
            return nil
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
