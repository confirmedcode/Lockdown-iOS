//
//  SelectCountryViewController.swift
//  Lockdown
//
//  Created by Pavel Vilbik on 27.06.23.
//  Copyright © 2023 Confirmed Inc. All rights reserved.
//

import UIKit

protocol SelectCountryViewModelProtocol {
    var countries: [Country] { get }
    var selectedCountry: Country? { get set }
    func bind(_ view: SelectCountryViewController)
    func donePressed()
    var title: String { get }
}

class SelectCountryViewController: UIViewController {
    
    // MARK: - models
    
    private let staticTableView = StaticTableView()
    var viewModel: SelectCountryViewModelProtocol?

    // MARK: - views
    
    private lazy var navigationView: ConfiguredNavigationView = {
        let view = ConfiguredNavigationView(accentColor: .darkText)
        view.titleLabel.textColor = .label
        view.leftNavButton.setTitle(NSLocalizedString("DONE", comment: ""), for: .normal)
        view.leftNavButton.addTarget(self, action: #selector(doneClicked), for: .touchUpInside)
        view.leftNavButton.tintColor = .tunnelsBlue
        view.rightNavButton.setTitle(NSLocalizedString("CANCEL", comment: ""), for: .normal)
        view.rightNavButton.addTarget(self, action: #selector(cancelClicked), for: .touchUpInside)
        view.rightNavButton.tintColor = .tunnelsBlue
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        updateView()
        viewModel?.bind(self)
    }
    
    // MARK: - Configure UI
    private func configureUI() {
        view.backgroundColor = .panelSecondaryBackground
        
        view.addSubview(navigationView)
        navigationView.anchors.leading.pin()
        navigationView.anchors.trailing.pin()
        navigationView.anchors.top.safeAreaPin()
        
        addTableView(staticTableView) { tableView in
            staticTableView.anchors.top.spacing(0, to: navigationView.anchors.bottom)
            staticTableView.anchors.leading.pin()
            staticTableView.anchors.trailing.pin()
            staticTableView.anchors.bottom.pin()
        }
        
        staticTableView.backgroundColor = .clear
        staticTableView.deselectsCellsAutomatically = true
        staticTableView.separatorStyle = .none
        navigationView.titleLabel.text = viewModel?.title
    }
    
    func updateView() {
        staticTableView.clear()
        viewModel?.countries.forEach { country in
            staticTableView.addRowCell { cell in
                let view = CountryView()
                view.titleLabel.text = country.title
                view.emojiLabel.text = country.emojiSymbol
                view.checkMark.isHidden = country != viewModel?.selectedCountry
                view.didSelect = { [weak self] in
                    self?.viewModel?.selectedCountry = country
                }
                cell.backgroundColor = .clear
                cell.backgroundView?.backgroundColor = .clear
                cell.contentView.backgroundColor = .clear
                cell.addSubview(view)
                view.anchors.edges.pin(insets: .init(top: 5, left: 2, bottom: 5, right: 2))
            }
        }
        
        staticTableView.reloadData()
    }

    
    // MARK: - actions
    
    @objc private func doneClicked() {
        viewModel?.donePressed()
    }
    
    @objc func cancelClicked() {
        dismiss(animated: true)
    }
}
