//
//  WakingAppViewController.swift
//  RemoteAssistance
//
//  Created by Yulius Tjahjadi on 12/18/19.
//  Copyright © 2019 FXPAL. All rights reserved.
//

import UIKit
import ARKit

class WakingAppViewController : ARViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegate(self);
        let projectPath = Bundle.main.path(forResource: "test", ofType: "wa");
//        let projectPath = Bundle.main.path(forResource: "carter-test", ofType: "wa");
        loadProject(projectPath);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        unloadCurrentProject();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension WakingAppViewController : WAEngineDelegate {
    func onProjectLoaded(_ loadSuccessful: Bool, _ projectName: String!, _ projectFilepath: String!, _ trackType: String!) {
        if(loadSuccessful) {
            NSLog("Project %@ loaded successfully", projectName);
        }
    }
    
   func onSceneLoaded(_ loadSuccessful: Bool,_ targetImageBytes: Data!) {
        if(loadSuccessful) {
            NSLog("Scene loaded successfully");
        }
    }
}
