//
//  ImportBlockListViewController.swift
//  LockdownSandbox
//
//  Created by Aliaksandr Dvoineu on 3.04.23.
//

import UIKit

final class ImportBlockListViewController: UIViewController {
    
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
    
    @objc func selectFromFiles() {
        
        // TODO: access to users Document folder
    }
    
    @objc func blockPastedDomains() {
        
        // TODO: future implementation according to the requirements
    }
}
