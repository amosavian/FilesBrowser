//
//  FilesBrowserDelegates
//  FilesBrowser
//
//  Copyright © 2018 Mousavian. All rights reserved.
//

import Foundation
import FilesProvider

public protocol FilesViewControllerType: class {
    var current: FileObject? { get }
    var files: [FileObject] { get set }
    var presentingIndexPath: IndexPath? { get set }
    var selectedFiles: [FileObject] { get set }
    var selectedIndices: [Int] { get set }
}

public protocol FilesBrowserControllerDelegate: class {
    func filesBrowser(_ filesBrowser: FilesBrowserController, present file: FileObject, anchor: AnchorView)
    func filesBrowser(_ filesBrowser: FilesBrowserController, selectionChangedTo files: [FileObject])
    
    func filesBrowser(_ filesBrowser: FilesBrowserController, filesListUpdated files: [FileObject])
    func filesBrowser(_ filesBrowser: FilesBrowserController, loadingStatusDidBecame status: FilesBrowserController.LoadingStatus)
}

internal protocol FilesViewControllerDelegate: class {
    func filesView(_ filesVC: FilesViewControllerType, didSelected file: FileObject, anchor: AnchorView)
    func filesView(_ filesVC: FilesViewControllerType, didDeselected file: FileObject, anchor: AnchorView)
    
    func filesView(_ filesVC: FilesViewControllerType, canLoadImageFor file: FileObject) -> Bool
    func filesView(_ filesVC: FilesViewControllerType, loadImageFor file: FileObject,
                   completionHandler:  @escaping (UIImage?) -> Void)
    func filesView(_ filesVC: FilesViewControllerType, availabledImageFor file: FileObject) -> UIImage?
    func filesView(_ filesVC: FilesViewControllerType, cancelLoadImageFor file: FileObject)
    
    func filesView(_ filesVC: FilesViewControllerType, delete file: FileObject, anchor: AnchorView)
    func filesView(_ filesVC: FilesViewControllerType, copy file: FileObject, anchor: AnchorView)
    func filesView(_ filesVC: FilesViewControllerType, move file: FileObject, anchor: AnchorView)
}
