//
//  TSSettingsViewController.swift
//  teleskele
//
//  Created by Yulius Tjahjadi on 9/27/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import UIKit
import SuperAlertController
import ReSwift
import IconFontKit

let azure = #colorLiteral(red: 0.05, green:0.49, blue:0.98, alpha:1.00)

public enum TSSettingType {
    case serverUrl
    
    var description: String {
        switch self {
        case .serverUrl:
            return "Server URL"
        }
    }
    
    var icon: UIImage {
        let azure = #colorLiteral(red: 0.05, green:0.49, blue:0.98, alpha:1.00)
        let size:CGFloat = 25
        switch self {
        case .serverUrl:
            return IFMaterialDesignIcons.image(withType: IFMaterialDesignIconsType.IFMDIPen.rawValue, color: azure, fontSize: size)
        }
    }
    
    var title: String? {
        switch self {
        case .serverUrl:
            return "Server URL"
        }
    }
    
    var message: String? {
        switch self {
        case .serverUrl:
            return "Server url to connect to expert"
        }
    }
    
    var detail: String? {
        switch self {
        case .serverUrl:
            return store.ts.state.serverUrl
        }
    }
}



class TSSettingsViewController: UIViewController,QRCodeScannerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var alertStyle: UIAlertController.Style = .alert

    let dataSource: [TSSettingType] = [
        .serverUrl
    ]
    
    func qrCodeScannerResponse(code: String) {
        let url = URL(string: code)
        let domain = (url?.host)
        let port = (url?.port)
        if (domain != nil && port != nil) {
            let action = TSSetServerURL(serverUrl: "https://"+domain!+":"+String(port!))
            store.ts.dispatch(action)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()        

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView.init()
        //self.tableView.sizeToFit()
        
        store.ts.subscribe(self)
        
    self.navigationController?.navigationBar.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    self.navigationController?.setNavigationBarHidden(false, animated: true)

        
    }

    @IBAction func scanUrlButtonClick(_ sender: Any) {
        let nvc = QRCodeSCanner()
        nvc.delegate = self
        self.navigationController?.pushViewController(nvc, animated: true)
    }
    
    
    func alert(type: TSSettingType) {
        let alertController = SuperAlertController.init(style: self.alertStyle, source: self.view, title: type.title, message: type.message, tintColor: azure)

        switch type {
        case .serverUrl:
            alertController.addOneTextField(configuration: { (textField) in
                textField.borderStyle = .roundedRect
                textField.keyboardType = .default
                textField.placeholder = type.title
                textField.text = type.detail
                textField.clearButtonMode = .whileEditing
            })
            break
        }
        
        self.addActions(for: type, to: alertController)
        
        alertController.show(animated: true, vibrate: false, completion: nil)
    }
    
    func addActions(for type: TSSettingType, to alertController: SuperAlertController) {
        alertController.addAction(image: nil, title: "Done", color: azure, style: .default, isEnabled: true, handler: {(action:UIAlertAction!) in
            self.updateSetting(type: type, alertController: alertController)
        })
        alertController.addAction(image: nil, title: "Cancel", color: azure, style: .cancel, isEnabled: true, handler: nil)
    }
    
    func updateSetting(type: TSSettingType, alertController: SuperAlertController) {
        switch type {
        case .serverUrl:
            if let textController = alertController.contentViewController as? OneTextFieldViewController {
                let action = TSSetServerURL(serverUrl: textController.textField.text!)
                store.ts.dispatch(action)
            }
        }
     }
}

extension TSSettingsViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ??
            UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let type = dataSource[indexPath.row]
        cell.textLabel?.text = type.description
        cell.detailTextLabel?.text = type.detail
        cell.selectionStyle = .none
        cell.accessoryType = .detailDisclosureButton
        cell.imageView?.image = type.icon
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let type = dataSource[indexPath.row]
        alert(type: type)
    }

}

extension TSSettingsViewController : StoreSubscriber {
    func newState(state: TSState) {
        tableView.reloadData()
        //tableView.invalidateIntrinsicContentSize()
        //tableView.layoutIfNeeded()
    }
}
