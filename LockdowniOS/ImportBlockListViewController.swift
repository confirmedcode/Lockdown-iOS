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
    
    var newListName = ""
    
    private lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView()
        view.rightNavButton.setTitle(NSLocalizedString("CANCEL", comment: ""), for: .normal)
        view.titleLabel.text = titleName
        view.rightNavButton.tintColor = .tunnelsBlue
        view.rightNavButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Import Domains from file", comment: "")
        label.textColor = .label
        label.font = fontBold17
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private lazy var descriptionParagraph1: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Take control of your browsing experience! Import your own custom block list and say goodbye to pesky trackers for good.", comment: "")
        label.textColor = .label
        label.font = fontRegular14
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private lazy var descriptionParagraph2: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = fontRegular14
        let highlightedText = "comma-separated values (.csv)"
        label.text = NSLocalizedString("Simply select the \(highlightedText) file with the domains you want to block and import it. It's that easy!", comment: "")
        label.highlight(highlightedText, font: UIFont.boldLockdownFont(size: 14))
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
        button.setImage(UIImage(named: "icn_csv_file"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        button.titleLabel?.font = fontBold17
        button.addTarget(self, action: #selector(selectFromFiles), for: .touchUpInside)
        return button
    }()
    
    private lazy var descriptionParagraph3: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("* The .csv file should contain a single column of domains and/or sub-domains. NO headers, NO additional columns, and NO URLs.", comment: "")
        label.textColor = .label
        label.font = fontRegular14
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private lazy var vStackView: UIStackView = {
        let stackView  = UIStackView()
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionParagraph1)
        stackView.addArrangedSubview(descriptionParagraph2)
        stackView.addArrangedSubview(selectFromFilesButton)
        stackView.addArrangedSubview(descriptionParagraph3)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .equalSpacing
        stackView.spacing = 24
        return stackView
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
        
        view.addSubview(vStackView)
        vStackView.anchors.top.spacing(48, to: navigationView.anchors.bottom)
        vStackView.anchors.leading.marginsPin()
        vStackView.anchors.trailing.marginsPin()
        
        selectFromFilesButton.anchors.leading.marginsPin()
        selectFromFilesButton.anchors.trailing.marginsPin()
        selectFromFilesButton.anchors.height.equal(56)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showCreateList()
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
 
        do {
            let content = csvProcessing(data: try String(contentsOf: url, encoding: .utf8))
            
            if !content.isEmpty {
                var allData = getBlockedLists()
                
                let importedList = UserBlockListsGroup(name: newListName, domains: content)
                
                allData.userBlockListsDefaults[importedList.name] = importedList
                
                let encodedData = try? JSONEncoder().encode(allData)
                defaults.set(encodedData, forKey: kUserBlockedLists)
                
                importCompletion?()
            }
            
            dismiss(animated: true) {
                if !content.isEmpty {
                    let alert = UIAlertController(title: NSLocalizedString("Success!", comment: ""),
                                                  message: NSLocalizedString("The list has been imported successfully. You can start blocking the list's domains", comment: ""),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: ""),
                                                  style: .default,
                                                  handler: nil))
                    UIApplication.getTopMostViewController()?.present(alert, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""),
                                                  message: NSLocalizedString("Your list of domains is empty or in the wrong format", comment: ""),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: ""),
                                                  style: .default,
                                                  handler: nil))
                    UIApplication.getTopMostViewController()?.present(alert, animated: true, completion: nil)
                }
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
    
    func showCreateList() {
        let alertController = UIAlertController(title: "Create New List", message: nil, preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                
                guard let self else { return }
                self.newListName = text
                addBlockedList(listName: self.newListName)
            }
        }
        
        saveAction.isEnabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] (_) in
            guard let self else { return }
            self.dismiss(animated: true)
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("List Name", comment: "")
        }
        
        NotificationCenter.default.addObserver(
            forName: UITextField.textDidChangeNotification,
            object: alertController.textFields?.first,
            queue: .main) { (notification) -> Void in
                guard let textFieldText = alertController.textFields?.first?.text else { return }
                saveAction.isEnabled = textFieldText.isValid(.listName)
            }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
        
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        
        dismiss(animated: true, completion: nil)
    }
    
    func csvProcessing(data: String) -> Set<String> {
        var domains = Set<String>()
        var arrayOfDomains = [String]()
        
        if data.contains("\r\n") {
            arrayOfDomains = data.components(separatedBy: "\r\n")
        } else if data.contains("\r") {
            arrayOfDomains = data.components(separatedBy: "\r")
        } else if data.contains("\n") {
            arrayOfDomains = data.components(separatedBy: "\n")
        } else if data.contains(",") {
            arrayOfDomains = data.components(separatedBy: ",")
        }
        
        for domain in arrayOfDomains {
            if domain.isValid(.domainName) {
                domains.insert(domain)
            }
        }
        
        return domains
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
