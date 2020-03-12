//
//  StationSelectionViewController.swift
//  Train Status
//
//  Created by Garry Yeung on 2020/3/12.
//  Copyright © 2020 Garry Yeung. All rights reserved.
//

import UIKit

class StationSelectionViewController: UIViewController {
	
	@IBOutlet var regionTableView: UITableView!
	@IBOutlet var stationTableView: UITableView!
	
	var selectedRegion = -1
	var regionAutoscrollPosition = 0
	var stationAutoscrollPosition = 0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		regionTableView.delegate = self
		regionTableView.dataSource = self
		stationTableView.delegate = self
		stationTableView.dataSource = self
		// Do any additional setup after loading the view.
	}
	
	override func viewDidAppear(_ animated: Bool) {
		let regionAutoscroll = IndexPath(row: regionAutoscrollPosition, section: 0)
		regionTableView.scrollToRow(at: regionAutoscroll, at: .middle, animated: true)
		let stationAutoscroll = IndexPath(row: stationAutoscrollPosition, section: 0)
		stationTableView.scrollToRow(at: stationAutoscroll, at: .middle, animated: true)
	}
}

extension StationSelectionViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if(tableView == self.regionTableView) {
			return TRA.classifiedStationList.count
		}
		else {
			if(selectedRegion == -1) {
				return 0
			}
			return (TRA.classifiedStationList[selectedRegion][1] as! Array<String>).count
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let identifier = (tableView == self.regionTableView) ? "Region":"Station"
		let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as! SelectionCell
		
		if(identifier == "Region") {
			cell.displayString = TRA.classifiedStationList[indexPath.row][0] as! String
		}
		else {
			cell.displayString = (TRA.classifiedStationList[selectedRegion][1] as! Array<String>)[indexPath.row]
			cell.level = TRA.highlight[selectedRegion][indexPath.row]
		}
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if(tableView == self.regionTableView) {
			selectedRegion = indexPath.row
			
			stationTableView.reloadData()
			let autoscroll = IndexPath(row: TRA.mainStationAutoscrollPositions[selectedRegion], section: 0)
			stationTableView.scrollToRow(at: autoscroll, at: .middle, animated: true)
		}
		else {
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SelectedStation"), object: (TRA.classifiedStationList[selectedRegion][1] as! Array<String>)[indexPath.row])
			
			dismiss(animated: true, completion: nil)
		}
	}
}

class SelectionCell: UITableViewCell {
	@IBOutlet var displayUnit: UILabel!
	var displayString = "" {
		didSet {
			displayUnit.text = displayString
		}
	}
	var level = 0 {
		didSet {
			switch level {
			case 0:
				displayUnit.textColor = .black
			case 1:
				displayUnit.textColor = .systemBlue
			case 2:
				displayUnit.textColor = .systemOrange
			default:
				displayUnit.textColor = .black
			}
		}
	}
}
