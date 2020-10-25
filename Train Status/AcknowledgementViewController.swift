//
//  AcknowledgementViewController.swift
//  Train Status
//
//  Created by Garry Yeung on 2020/10/25.
//  Copyright © 2020 Garry Yeung. All rights reserved.
//

import UIKit

class AcknowledgementViewController: UIViewController {

	@IBOutlet var versionLabel: UILabel!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		versionLabel.text = "版本：" + (Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
