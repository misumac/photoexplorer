//
//  PanelState.swift
//  PhotoExplorer
//
//  Created by Mihai on 2/25/16.
//  Copyright © 2016 Mihai. All rights reserved.
//

import Foundation

class PanelStateViewModel {
    fileprivate var infoState = InfoPanelState.showingExif
    fileprivate var infoHidden = false
    
    func panelState() -> InfoPanelState {
        return self.infoState
    }
    
    func setPanelState(_ state: InfoPanelState) {
        self.infoState = state
    }
    
    func panelHidden() -> Bool {
        return self.infoHidden
    }
    
    func setPanelHidden(_ hidden: Bool) {
        self.infoHidden = hidden
    }
}
