//
//  RouteDetailViewController.swift
//  Train Status
//
//  Created by Garry Yeung on 2020/11/11.
//  Copyright © 2020 Garry Yeung. All rights reserved.
//

import UIKit

class RouteDetailViewController: UIViewController {

	var train: Train?
	var trainRoute: TrainRoute?
	var trainLivePosition: TrainLivePosition?
	var currentStationCode: String?
	
	@IBOutlet var labelBackgroundView: UIView!
	@IBOutlet var trainNumberLabel: UILabel!
	@IBOutlet var destinationLabel: UILabel!
	@IBOutlet var bicycleImage: UIImageView!
	@IBOutlet var wheelchairImage: UIImageView!
	@IBOutlet var routeDetailTableView: UITableView!
	@IBOutlet var activityIndicatorView: UIActivityIndicatorView!
	
	var isBicycleAvailable = false {
		didSet {
			bicycleImage.isHidden = !isBicycleAvailable
		}
	}
	var isWheelchairAvailable = false {
		didSet {
			wheelchairImage.isHidden = !isWheelchairAvailable
		}
	}
	
	var autoScrollPosition: Int = 0
	
	
	var autoRefreshTimer: Timer?
	let semaphore = DispatchSemaphore(value: 0)
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		activityIndicatorView.startAnimating()
		
		routeDetailTableView.delegate = self
		routeDetailTableView.dataSource = self
		
		routeDetailTableView.contentInset = UIEdgeInsets(top: 30.0, left: 0.0, bottom: 30.0, right: 0.0)
		
		configureInitialInformation()
		
		constructStationSequence()
		autoRefresh()
		autoRefreshTimer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(autoRefresh), userInfo: nil, repeats: true)
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		autoRefreshTimer!.invalidate()
	}
	
	func configureInitialInformation() {
		/*
		switch train?.trainType {
		case "自強", "普悠瑪", "太魯閣":
			labelBackgroundView.backgroundColor = UIColor(red: 90/255, green: 0.0, blue: 0.0, alpha: 1.0)
		case "莒光":
			labelBackgroundView.backgroundColor = UIColor(red: 100/255, green: 40/255, blue: 0.0, alpha: 1.0)
		default:
			labelBackgroundView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 90/255, alpha: 1.0)
		}*/
		
		trainNumberLabel.text = "\(train?.trainType ?? "") \(String(describing: train?.trainNumber ?? ""))"
		destinationLabel.text = "往\(train?.endingStation ?? "")"
		
		bicycleImage.isHidden = true
		wheelchairImage.isHidden = true
	}
	
	func constructStationSequence() {
		DispatchQueue.global(qos: .background).async {
			self.trainRoute = MOTCQuery.shared.queryTrainRoute(trainNumber: self.train!.trainNumber)
			
			self.semaphore.signal()
			
			for i in 0..<self.trainRoute!.routeStations!.count {
				if(self.trainRoute!.routeStations![i].stationId == self.currentStationCode) {
					self.trainRoute!.routeStations![i].isCurrentStation = true
					self.autoScrollPosition = i
					break
				}
			}
			
			DispatchQueue.main.async {
				self.isBicycleAvailable = self.trainRoute!.bike
				self.isWheelchairAvailable = self.trainRoute!.wheelChair
				self.routeDetailTableView.reloadData()
				self.routeDetailTableView.scrollToRow(at: IndexPath(row: self.autoScrollPosition, section: 0), at: .middle, animated: false)
				
				self.activityIndicatorView.stopAnimating()
			}
		}
	}
	
	@objc func autoRefresh() {
		DispatchQueue.global(qos: .background).async {
			self.trainLivePosition = MOTCQuery.shared.queryRealTimeTrainPosition(trainNumber: self.train!.trainNumber)
			
			self.semaphore.wait()
			
			// exclude the case when train is not even departed
			if(self.trainLivePosition?.stationName != "none") {
				for i in 0..<self.trainRoute!.routeStations!.count {
					if(self.trainRoute!.routeStations![i].stationId == self.trainLivePosition?.stationId) {
						self.trainRoute!.routeStations![i].trainWithStationStatus = self.trainLivePosition!.stationStatus
					}
					else {
						self.trainRoute!.routeStations![i].trainWithStationStatus = .None
					}
				}
			}
		}
	}
}

extension RouteDetailViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if(trainRoute == nil || trainRoute!.routeStations == nil) {
			return 0
		}
		
		return trainRoute!.routeStations!.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell") as! RouteDetailTableViewCell
		
		cell.stationName = trainRoute!.routeStations![indexPath.row].stationName
		cell.isCurrentStation = trainRoute!.routeStations![indexPath.row].isCurrentStation
		cell.isDepartureStation = trainRoute!.routeStations![indexPath.row].isDepartureStation
		cell.isDestinationStation = trainRoute!.routeStations![indexPath.row].isDestinationStation
		cell.departTime = trainRoute!.routeStations![indexPath.row].departureTime
		
		cell.trainStatus = trainRoute!.routeStations![indexPath.row].trainWithStationStatus
		cell.delayTime = train!.delayTime
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 40.0
	}
}
