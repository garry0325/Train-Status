//
//  ViewController.swift
//  Train Status
//
//  Created by Garry Yeung on 2020/3/12.
//  Copyright © 2020 Garry Yeung. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

class ViewController: UIViewController, CLLocationManagerDelegate {
	
	// TODO: no internet connection prompt
	// TODO: no server response prompt
	// TODO: Acknowledgement -> https://motc-ptx-api-documentation.gitbook.io/motc-ptx-api-documentation/hui-yuan-shen-qing/membertype
	// TODO: 免責聲明
	// TODO: app icon
	// TODO: change font
	// TODO: maybe global variables
	// TODO: first time prompt + warnings
	// TODO: use core data
	// TODO: optimize class MOTCQuery so no need to create instance every time
	
	var locationManager = CLLocationManager()
	@IBOutlet var stationButton: UIButton!
	@IBOutlet var locationButton: UIButton!
	@IBOutlet var refreshButton: UIButton!
	@IBOutlet var boardTableView: UITableView!
	
	@IBOutlet var adBannerView: GADBannerView!
	
	
	@IBOutlet var segmentControl: UISegmentedControl!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	
	var selectedSegment = 2
	var isUpdatingLocation = false
	
	var boardTrains: [Train] = []
	
	var currentStationCode = "1000" {
		didSet {
			stationButton.setTitle(TRA.Station[currentStationCode] ?? "", for: .normal)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		UserDefaults.standard.set(["zh_TW"], forKey: "AppleLanguages")
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		
		boardTableView.delegate = self
		boardTableView.dataSource = self
		
		boardTableView.allowsSelection = false
		
		segmentControl.selectedSegmentIndex = 2
		segmentControl.addTarget(self, action: #selector(changeSegment), for: .valueChanged)
		
		// my banner ad id: ca-app-pub-5814041924860954/6968493215
		// test banner ad id: ca-app-pub-3940256099942544/2934735716
		self.adBannerView.adUnitID = "ca-app-pub-5814041924860954/6968493215"
		self.adBannerView.rootViewController = self
		self.adBannerView.load(GADRequest())
				
		dismissActivityIndicator()
		
		// Monitor network connection
		NetworkConnection().startMonitoring()
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateManualStation), name: NSNotification.Name("SelectedStation"), object: nil)
		// Because when app is reopen from background, the animation stops
		NotificationCenter.default.addObserver(self, selector: #selector(backFromBackground), name: UIApplication.didBecomeActiveNotification, object: nil)
		
		_ = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(autoRefresh), userInfo: nil, repeats: true)
		
		presentActivityIndicator()
		checkLocationServicePermission()
	}
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc func updateManualStation(notification: Notification) {
		locationManager.stopUpdatingLocation()
		isUpdatingLocation = false
		
		let station = notification.object as! String
		currentStationCode = TRA.StationCode[station]!
		
		locationButton.tintColor = .gray
		
		queryMOTC()
	}
	
	@IBAction func updateTrainBoard(_ sender: Any) {
		queryMOTC()
	}
	
	@IBAction func getCurrentLocation(_ sender: Any) {
		checkLocationServicePermission()
		if(isUpdatingLocation) {
			queryMOTC()
		}
		else {
			presentActivityIndicator()
			locationManager.startUpdatingLocation()
			isUpdatingLocation = true
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		let userLocation: CLLocation = locations[locations.count-1]
		CLGeocoder().reverseGeocodeLocation(userLocation) { (placemark, error) in
			if(error != nil) {
				print("error")
			} else {
				if let placemark = placemark?[0] {
					var address = ""
					address = address + (placemark.postalCode ?? "")
					address = address + (placemark.subAdministrativeArea ?? "")
					address = address + (placemark.locality ?? "")
					
					print(address)
				}
			}
		}
		findNearestTRAStation(longitude: Double(userLocation.coordinate.longitude), latitude: Double(userLocation.coordinate.latitude))
	}
	
	func findNearestTRAStation(longitude: Double, latitude: Double) {
		var nearestStation = ""
		var minimumDistance: Double = 1000000
		for (stationCode, value) in StationInfo {
			let info = value as [String: Any]
			let stationLongitude = info["Longitude"] as! Double
			let stationLatitude = info["Latitude"] as! Double
			let stationLocation = CLLocation.init(latitude: stationLatitude, longitude: stationLongitude)
			let userLocation = CLLocation.init(latitude: latitude, longitude: longitude)
			let distance = stationLocation.distance(from: userLocation)
			
			if(distance < minimumDistance) {
				nearestStation = stationCode
				minimumDistance = distance
			}
		}
		
		locationButton.imageView?.tintColor = .systemBlue
		locationButton.tintColor = .systemBlue
		currentStationCode = nearestStation
		queryMOTC()
	}
	
	func queryMOTC() {
		presentActivityIndicator()
		
		let queue = DispatchQueue(label: "MOTC")
		queue.async {
			let query = MOTCQuery(stationCode: self.currentStationCode)
			self.boardTrains = query.queryStationBoard()
			self.filterOutBoard()
			
			DispatchQueue.main.async {
				self.boardTableView.reloadData()
				self.dismissActivityIndicator()
			}
		}
	}
	
	@objc func changeSegment(sender: UISegmentedControl) {
		selectedSegment = segmentControl.selectedSegmentIndex
		queryMOTC()
	}
	
	func filterOutBoard() {
		switch selectedSegment {
		case 0:
			boardTrains = boardTrains.filter { $0.direction == "逆行" }
		case 1:
			boardTrains = boardTrains.filter { $0.direction == "順行" }
		default:
			break
		}
	}
	
	func presentActivityIndicator() {
		refreshButton.isHidden = true
		activityIndicator.startAnimating()
	}
	func dismissActivityIndicator() {
		activityIndicator.stopAnimating()
		refreshButton.isHidden = false
	}
	
	@objc func backFromBackground(sender: AnyObject) {
		queryMOTC()
	}
	
	@objc func autoRefresh() {
		locationManager.stopUpdatingLocation()
		isUpdatingLocation = false
		queryMOTC()
	}
	
	func checkLocationServicePermission() {
		dismissActivityIndicator()
		locationManager.requestWhenInUseAuthorization()
		
		if(CLLocationManager.locationServicesEnabled() &&
			(CLLocationManager.authorizationStatus() == .authorizedAlways ||
			CLLocationManager.authorizationStatus() == .authorizedWhenInUse)){
			
			locationManager.startUpdatingLocation()
			isUpdatingLocation = true
		}
		else {
			isUpdatingLocation = false
			locationButton.tintColor = .gray
			print("Location permission not granted")
			promptLocationServicePermission()
		}
	}
	
	func promptLocationServicePermission() {
		let locationServiceAlert = UIAlertController(title: "請開啟定位服務", message: "設定 > 隱私 > 定位服務", preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
		let settingsAction = UIAlertAction(title: "設定", style: .default, handler: {_ in
			guard let settingsLocationPermissionUrl = URL(string: UIApplication.openSettingsURLString) else {
						return
					}
					print(settingsLocationPermissionUrl)
					if UIApplication.shared.canOpenURL(settingsLocationPermissionUrl) {
						UIApplication.shared.open(settingsLocationPermissionUrl, completionHandler: { (success) in
							print("Settings opened: \(success)") // Prints true
						})
					}
		})
		
		locationServiceAlert.addAction(settingsAction)
		locationServiceAlert.addAction(cancelAction)
		
		present(locationServiceAlert, animated: true, completion: nil)
	}
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		//		if(section == 0) {
		//			return 1
		//		}
		//		else {
		return boardTrains.count
		//}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "BoardTrain") as! TrainBoardCell
		cell.trainNumber		= boardTrains[indexPath.row].trainNumber
		cell.trainType			= boardTrains[indexPath.row].trainType
		cell.destination		= boardTrains[indexPath.row].endingStation
		cell.line				= boardTrains[indexPath.row].trainLine
		cell.departure			= boardTrains[indexPath.row].departureTime
		cell.delay				= boardTrains[indexPath.row].delayTime
		cell.degreeOfIndicator	= boardTrains[indexPath.row].degreeOfIndicator
		cell.departed			= boardTrains[indexPath.row].departed
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let tempCell = cell as! TrainBoardCell
		
		switch (tempCell.degreeOfIndicator) {
		case 1:
			tempCell.upcomingIndicator.alpha = 0.0
			UIView.animate(withDuration: 0.2, delay: 0.0, options: [.repeat, .autoreverse], animations: {
				tempCell.upcomingIndicator.alpha = 1.0
			}, completion: nil)
		case 2:
			tempCell.upcomingIndicator.alpha = 0.0
			UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat, .autoreverse], animations: {
				tempCell.upcomingIndicator.alpha = 1.0
			}, completion: nil)
		default:
			break
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 44.0
	}
}

extension ViewController: UIPopoverPresentationControllerDelegate {
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let destination = segue.destination as! StationSelectionViewController
		
		destination.popoverPresentationController?.delegate = self
		
		if(segue.identifier == "StationSelection") {
			destination.preferredContentSize = CGSize(width: 200, height: 350)
			destination.regionAutoscrollPosition = TRA.stationPositionInList[currentStationCode]![0]
			destination.stationAutoscrollPosition = TRA.stationPositionInList[currentStationCode]![1]
			destination.selectedRegion = TRA.stationPositionInList[currentStationCode]![0]
		}
	}
	
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		return .none
	}
}
