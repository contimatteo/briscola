//
//  ResultsController.swift
//  Briscola-Multiplayer
//
//  Created by Matteo Conti on 06/01/2020.
//  Copyright © 2020 Matteo Conti. All rights reserved.
//

import Foundation
import UIKit

class ResultsController: UIViewController {
    
    public var gameInstance: GameHandler = GameHandler.init();
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        print("\n \n trump card name -> \(gameInstance.trumpCard!.name)");
    }
}
