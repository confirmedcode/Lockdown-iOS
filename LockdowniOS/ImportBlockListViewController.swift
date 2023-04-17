//
//  ImportBlockListViewController.swift
//  LockdownSandbox
//
//  Created by Aliaksandr Dvoineu on 3.04.23.
//

import UIKit
import UniformTypeIdentifiers

final class ImportBlockListViewController: UIViewController, UIDocumentPickerDelegate {
    
    // MARK: - Properties
    
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
private extension ImportBlockListViewController {
    
    @objc func cancel() {
        dismiss(animated: true)
    }
    
    // returns your application folder
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    //  list name validation code method
    func isValidListName(text: String) -> Bool {
        let regEx = "^[a-zA-Z0-9]{1,20}$"
        return text.range(of: "\(regEx)", options: .regularExpression) != nil
    }
    
    @objc func selectFromFiles() {
        
        let alertController = UIAlertController(title: "Create New List", message: nil, preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                guard let self else { return }
                
                addBlockedList(listName: text)
                let path = self.getDocumentsDirectory().absoluteString.replacingOccurrences(of: "file://", with: "shareddocuments://")
                let url = URL(string: path)!
                
                UIApplication.shared.open(url)
                
            }
        }
        
        saveAction.isEnabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (_) in
            guard let self else { return }
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("List Name", comment: "")
        }
        
        NotificationCenter.default.addObserver(
            forName: UITextField.textDidChangeNotification,
            object: alertController.textFields?.first,
            queue: .main) { (notification) -> Void in
                guard let textFieldText = alertController.textFields?.first?.text else { return }
                saveAction.isEnabled = self.isValidListName(text: textFieldText) && !textFieldText.isEmpty
            }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
        
        
        
        
        
        

    }
    
    @objc func blockPastedDomains() {
        
        // TODO: future implementation according to the requirements
    }
}
