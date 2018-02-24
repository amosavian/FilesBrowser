//
//  FilesFlowDelegate.swift
//  FilesBrowser
//
//  Created by Amir Abbas on 12/5/1396 AP.
//  Copyright © 1396 AP Mousavian. All rights reserved.
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

public protocol FilesFlowControllerDelegate: class {
    func filesFlow(_ filesVC: FilesFlowViewController, presentFile file: FileObject, anchor: AnchorView)
    func filesFlow(_ filesVC: FilesFlowViewController, selectionChangedTo files: [FileObject])
    func filesFlow(_ filesVC: FilesFlowViewController, updateToolbarItems items: [UIBarButtonItem])
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
