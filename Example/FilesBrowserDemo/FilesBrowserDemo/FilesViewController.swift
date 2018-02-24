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

class FilesViewController: UIViewController, FilesFlowControllerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    var flowViewController: FilesFlowViewController
    
    var quickLook: QLPreviewController?
    var quickLookItems: [(file: FileObject, anchor: AnchorView?)] = []
    
    init(flowViewController: FilesFlowViewController) {
        self.flowViewController = flowViewController
        let bundle = Bundle(for: FilesViewController.self)
        super.init(nibName: nil, bundle: bundle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        flowViewController.delegate = self
        self.transition(child: flowViewController)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        flowViewController.setEditing(editing, animated: animated)
        super.setEditing(editing, animated: animated)
    }
    
    func filesFlow(_ filesVC: FilesFlowViewController, presentViewcontroller: UIViewController) {
        navigationController?.pushViewController(presentViewcontroller, animated: true)
    }
    
    func filesFlow(_ filesVC: FilesFlowViewController, presentFile: FileObject, anchor: AnchorView) {
        if presentFile.url.isFileURL, QLPreviewController.canPreview(presentFile.url.absoluteURL as QLPreviewItem) {
            quickLookItems = [(presentFile, anchor)]
            self.quickLook = QLPreviewController()
            quickLook!.dataSource = self
            self.present(quickLook!, animated: true, completion: nil)
        }
    }
    
    // MARK: - QuickLook
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return quickLookItems[index].file.url.absoluteURL as QLPreviewItem
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return quickLookItems.count
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        quickLookItems = []
    }
    
    /*func previewController(_ controller: QLPreviewController, transitionImageFor item: QLPreviewItem, contentRect: UnsafeMutablePointer<CGRect>) -> UIImage {
     //
     }*/
    
    func previewController(_ controller: QLPreviewController, transitionViewFor item: QLPreviewItem) -> UIView? {
        guard let anchor = quickLookItems.first(where: { $0.file.url.absoluteURL == item.previewItemURL })?.anchor else {
            return nil
        }
        
        switch anchor {
        case .view(view: let view):
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
