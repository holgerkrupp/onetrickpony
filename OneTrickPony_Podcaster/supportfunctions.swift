//
//  supportfunctions.swift
//  DML
//
//  Created by Holger Krupp on 18/02/16.
//  Copyright © 2016 Holger Krupp. All rights reserved.
//

import Foundation
import UIKit

func getvalueforkeyfrompersistentstrrage(key:String) -> AnyObject{

    if let value = NSUserDefaults.standardUserDefaults().objectForKey(key){
        return value
    }else{
        return "no latest episode in NSUserDefaults"
    }
}

func setvalueforkeytopersistentstorrage(key:String, value:AnyObject){
    NSUserDefaults.standardUserDefaults().setObject(value, forKey: key)
}