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

public enum SettingType {
    case serverUrl
    case roomName
    case help
    
    
    var description: String {
        switch self {
        case .serverUrl:
            return "Server URL"
        case .roomName:
            return "Room Name"
        case .help:
            return "Help"
        }
    }
    
    var icon: UIImage {
        let azure = #colorLiteral(red: 0.05, green:0.49, blue:0.98, alpha:1.00)
        let size:CGFloat = 25
        switch self {
        case .serverUrl:
            return IFMaterialDesignIcons.image(withType: IFMaterialDesignIconsType.IFMDIPen.rawValue, color: azure, fontSize: size)
        case .roomName:
            return IFMaterialDesignIcons.image(withType: IFMaterialDesignIconsType.IFMDIGroup.rawValue, color: azure, fontSize: size)
        case .help:
            return IFMaterialDesignIcons.image(withType: IFMaterialDesignIconsType.IFMDIHelp.rawValue, color: azure, fontSize: size)
        }
    }
    
    var title: String? {
        switch self {
        case .serverUrl:
            return "Server URL"
        case .roomName:
            return "Room Name"
        case .help:
            return "Help"
        }
    }
    
    var message: String? {
        switch self {
        case .serverUrl:
            return "Server url to connect to expert"
        case .roomName:
            return "Room name to join"
        case .help:
            return "Show help"
        }
    }
    
    var detail: String? {
        switch self {
        case .serverUrl:
            return store.ts.state.serverUrl
        case .roomName:
            return store.ts.state.roomName
        case .help:
            return "Remote assistance help"
        }
    }
}



class SettingsViewController: UIViewController,QRCodeScannerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var alertStyle: UIAlertController.Style = .alert

    let dataSource: [SettingType] = [
        .serverUrl,
        .roomName,
        .help,
    ]
    
    func qrCodeScannerResponse(code: String) {
        let url = URL(string: code)
        let domain = (url?.host)
        let port = (url?.port)
        if let domain = domain {
            var portStr = ""
            if let port = port {
                portStr = ":\(String(port))"
            }
            let action = TSSetServerURL(serverUrl: "https://\(domain)\(portStr)")
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
            
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        self.navigationController?.navigationBar.barTintColor = azure
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    @IBAction func scanUrlButtonClick(_ sender: Any) {
        let nvc = QRCodeSCanner()
        nvc.delegate = self
        self.navigationController?.pushViewController(nvc, animated: true)
    }
    
    
    func alert(type: SettingType) {
        let alertController = SuperAlertController.init(style: self.alertStyle, source: self.view, title: type.title, message: type.message, tintColor: azure)

        switch type {
        case .serverUrl, .roomName:
            alertController.addOneTextField(configuration: { (textField) in
                textField.borderStyle = .roundedRect
                textField.keyboardType = .default
                textField.placeholder = type.title
                textField.text = type.detail
                textField.clearButtonMode = .whileEditing
            })
        default:
            break
        }
        
        self.addActions(for: type, to: alertController)
        
        alertController.show(animated: true, vibrate: false, completion: nil)
    }
    
    func addActions(for type: SettingType, to alertController: SuperAlertController) {
        alertController.addAction(image: nil, title: "Done", color: azure, style: .default, isEnabled: true, handler: {(action:UIAlertAction!) in
            self.updateSetting(type: type, alertController: alertController)
        })
        alertController.addAction(image: nil, title: "Cancel", color: azure, style: .cancel, isEnabled: true, handler: nil)
    }
    
    func updateSetting(type: SettingType, alertController: SuperAlertController) {
        switch type {
        case .serverUrl:
            if let textController = alertController.contentViewController as? OneTextFieldViewController {
                let action = TSSetServerURL(serverUrl: textController.textField.text!)
                store.ts.dispatch(action)
            }
        case .roomName:
            if let textController = alertController.contentViewController as? OneTextFieldViewController {
                let action = TSSetRoomName(roomName: textController.textField.text!)
                store.ts.dispatch(action)
            }
        default:
            break
        }
     }
}

extension SettingsViewController : UITableViewDelegate, UITableViewDataSource {
    
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
        switch (type) {
        case .help:
            if let url = URL(string: "\(store.ts.state.serverUrl)/help") {
                UIApplication.shared.openURL(url)
            }
        default:
            alert(type: type)
        }
    }

}

extension SettingsViewController : StoreSubscriber {
    func newState(state: TSState) {
        tableView.reloadData()
        //tableView.invalidateIntrinsicContentSize()
        //tableView.layoutIfNeeded()
    }
}
