//
//  ImportBlockListViewController.swift
//  LockdownSandbox
//
//  Created by Aliaksandr Dvoineu on 3.04.23.
//

import UIKit
import UniformTypeIdentifiers
import MobileCoreServices

final class ImportBlockListViewController: UIViewController, UIDocumentPickerDelegate {
    
    // MARK: - Properties
    
    var importCompletion: (() -> ())?
    
    var titleName = "Import Block List"
    
    private lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView()
        view.rightNavButton.setTitle(NSLocalizedString("CANCEL", comment: ""), for: .normal)
        view.titleLabel.text = titleName
        view.rightNavButton.tintColor = .tunnelsBlue
        view.rightNavButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return view
    }()
    
    private lazy var importDomainsTitle: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Import Domains from file", comment: "")
        label.textColor = .label
        label.font = fontBold15
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private lazy var importDomainsText: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Take control of your browsing experience! Import your own custom block list and say goodbye to pesky trackers for good. Simply select the file with the domains you want to block and import it. It's that easy!", comment: "")
        label.textColor = .label
        label.font = fontRegular14
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private lazy var selectFromFilesButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = .tunnelsBlue
        button.layer.cornerRadius = 28
        button.setTitle(NSLocalizedString("Select from Files", comment: ""), for: .normal)
        button.titleLabel?.font = fontBold15
        button.addTarget(self, action: #selector(selectFromFiles), for: .touchUpInside)
        return button
    }()
    
    private lazy var pasteFromClipboardTitle: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Paste multiple domains from clipboard", comment: "")
        label.textColor = .label
        label.font = fontBold15
        label.textColor = .label
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    
    private lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = .gray
        return view
    }()
    
    private lazy var pasteFromClipboardText: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("You can copy existing data from a spreadsheet (like and Excel workbook or Google Sheet) and paste it in the field below.", comment: "")
        label.textColor = .label
        label.font = fontRegular14
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private lazy var pasteFromClipboardTextfield: UITextField = {
        let textFieled = UITextField()
        textFieled.textColor = .label
        textFieled.font = fontRegular14
        textFieled.textColor = .label
        textFieled.textAlignment = .left
        textFieled.contentVerticalAlignment = .top
        textFieled.borderStyle = .line
        return textFieled
    }()
    
    private lazy var blockPastedDomainsButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = .gray
        button.layer.cornerRadius = 28
        button.setTitle(NSLocalizedString("Block Pasted Domains", comment: ""), for: .normal)
        button.titleLabel?.font = fontBold15
        button.addTarget(self, action: #selector(blockPastedDomains), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        configureUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Configure UI
    func configureUI() {
        view.addSubview(navigationView)
        navigationView.anchors.leading.pin()
        navigationView.anchors.trailing.pin()
        navigationView.anchors.top.safeAreaPin()
        
        view.addSubview(importDomainsTitle)
        importDomainsTitle.anchors.leading.marginsPin()
        importDomainsTitle.anchors.trailing.marginsPin()
        importDomainsTitle.anchors.top.spacing(30, to: navigationView.anchors.bottom)
        
        view.addSubview(importDomainsText)
        importDomainsText.anchors.leading.marginsPin()
        importDomainsText.anchors.trailing.marginsPin()
        importDomainsText.anchors.top.spacing(16, to: importDomainsTitle.anchors.bottom)
        
        view.addSubview(selectFromFilesButton)
        selectFromFilesButton.anchors.leading.marginsPin()
        selectFromFilesButton.anchors.trailing.marginsPin()
        selectFromFilesButton.anchors.top.spacing(20, to: importDomainsText.anchors.bottom)
        selectFromFilesButton.anchors.height.equal(56)
    }
}

    // MARK: - Private functions
extension ImportBlockListViewController {
    
    @objc func cancel() {
        let viewController = BlockListViewController()
        viewController.reloadCustomBlockedLists()
        dismiss(animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        guard let url = urls.first else {
            return
        }
        
        guard let data = try? Data(contentsOf: url) else { return }
        
        do {
            let exportedList = try JSONDecoder().decode(UserBlockListsGroup.self, from: data)
            var allData = getBlockedLists()
            allData.userBlockListsDefaults[exportedList.name] = exportedList
            let encodedData = try? JSONEncoder().encode(allData)
            defaults.set(encodedData, forKey: kUserBlockedLists)
            
            importCompletion?()
            dismiss(animated: true) {
                let alert = UIAlertController(title: NSLocalizedString("Success!", comment: ""),
                                              message: NSLocalizedString("The list has been imported successfully. You can start blocking the list's domains", comment: ""),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: ""),
                                              style: .default,
                                              handler: nil))
                UIApplication.getTopMostViewController()?.present(alert, animated: true, completion: nil)
            }
            
        } catch {
            dismiss(animated: true) {
                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                              message: NSLocalizedString("Unable to import the list. Please try again or contact support for assistance", comment: ""),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: ""),
                                              style: .default,
                                              handler: nil))
                UIApplication.getTopMostViewController()?.present(alert, animated: true, completion: nil)
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func selectFromFiles() {
        
        if #available(iOS 14.0, *) {
            let supportedFiles: [UTType] = [UTType.data]
            
            let controller = UIDocumentPickerViewController(forOpeningContentTypes: supportedFiles, asCopy: true)
            
            controller.delegate = self
            controller.modalPresentationStyle = .formSheet
            controller.allowsMultipleSelection = false
            present(controller, animated: true)
        }
    }
    
    @objc func blockPastedDomains() {
        
        // TODO: future implementation according to the requirements
    }
}
