// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
//
// PreviewController.swift
// skip-kit
//
// created by Simone Figlie' on 17/02/25.

#if !SKIP
#if os(iOS)
import Foundation
import SwiftUI
import QuickLook

struct PreviewController: UIViewControllerRepresentable {
    let url: URL
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        
        controller.dataSource = context.coordinator
        
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .done, target: context.coordinator,
                    action: #selector(context.coordinator.dismiss)
                )
        
        let navigationController = UINavigationController(rootViewController: controller)
        
        
        return navigationController
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) { }
}

class Coordinator: QLPreviewControllerDataSource {
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        return parent.url as NSURL
    }
    
    let parent: PreviewController
    
    init(parent: PreviewController) {
        self.parent = parent
    }
    
    func numberOfPreviewItems(in previewController: QLPreviewController) -> Int {
        return 1
    }
    
    @objc func dismiss() {
        parent.isPresented = false
    }
}
#endif
#endif
