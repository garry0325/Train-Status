//
//  ViewController.swift
//  Train Status
//
//  Created by Garry Yeung on 2020/3/12.
//  Copyright © 2020 Garry Yeung. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

class ViewController: UIViewController, CLLocationManagerDelegate {
	
	// TODO: no internet connection prompt +
	// TODO: no server response prompt
	// TODO: source -> + https://motc-ptx-api-documentation.gitbook.io/motc-ptx-api-documentation/hui-yuan-shen-qing/membertype
	// TODO: app icon +
	// TODO: change font +
	// TODO: first time prompt + warnings +
	// TODO: use core data +
	// TODO: optimize class MOTCQuery so no need to create instance every time +
	// TODO: code optimization
	// TODO: eliminate warnings
	// TODO: Handle bug when network error returns nil in queryTrainRoute
	// TODO: no station name showing when initial launch and location permission not granted
	
	let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	var lastViewStation: Array<Record>?
	
	var locationManager = CLLocationManager()
	@IBOutlet var stationButton: UIButton!
	@IBOutlet var locationButton: UIButton!
	@IBOutlet var refreshButton: UIButton!
	@IBOutlet var boardTableView: UITableView!
	
	@IBOutlet var segmentControl: UISegmentedControl!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var informationButton: UIButton!
	
	var selectedSegment = 2
	var isUpdatingLocation = false
	
	var boardTrains: [Train] = []
	
	var currentStationCode = "1000" {
		didSet {
			if(currentStationCode == "-1") {
				stationButton.setTitle("附近沒有車站", for: .normal)
			}
			else {
				stationButton.setTitle(TRA.Station[currentStationCode] ?? "", for: .normal)
				updateLastViewStation()
			}
		}
	}
	@IBOutlet var informationButtonToSafeAreaLayout: NSLayoutConstraint!
	var informationButtonToAdBannerLayout: NSLayoutConstraint?
	
	var adBannerView: GADBannerView!
	var headerAdBannerView: GADBannerView!
	var displayAd = true
	var needAdData: Array<Ad> = []
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//UserDefaults.standard.set(["zh_TW"], forKey: "AppleLanguages")
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		
		boardTableView.delegate = self
		boardTableView.dataSource = self
		boardTableView.contentInset = UIEdgeInsets(top: 15.0, left: 0.0, bottom: 150.0, right: 0.0)
		
		segmentControl.selectedSegmentIndex = 2
		segmentControl.addTarget(self, action: #selector(changeSegment), for: .valueChanged)
		
		stationButton.titleLabel?.adjustsFontSizeToFitWidth = true
		
		informationButton.layer.shadowColor = UIColor.white.cgColor
		
		configureAdBanner()
		
		checkAdRemoval()
		
		if(checkInitial()) {
			presentWelcomeWarning()
		}
		else {
			fetchLastViewStation()
			initialSetup()
			checkLocationServicePermission()
		}
	}
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	func initialSetup() {
		if(displayAd) {
			self.headerAdBannerView.frame = CGRect(x: 0, y: 0, width: headerAdBannerView.frame.width, height: 60.0)
			self.adBannerView.load(GADRequest())
			self.headerAdBannerView.load(GADRequest())
		}
		
		
		dismissActivityIndicator()
		
		// Monitor network connection
		NetworkConnection().startMonitoring()
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateManualStation), name: NSNotification.Name("SelectedStation"), object: nil)
		// Because when app is reopen from background, the animation stops
		NotificationCenter.default.addObserver(self, selector: #selector(backFromBackground), name: UIApplication.didBecomeActiveNotification, object: nil)
		
		_ = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(autoRefresh), userInfo: nil, repeats: true)
		
		NotificationCenter.default.addObserver(self, selector: #selector(removeAdSuccess), name: NSNotification.Name("RemoveAd"), object: nil)
		
		presentActivityIndicator()
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
			//presentActivityIndicator()
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
					
					//print(address)
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
		
		if(minimumDistance == 1000000) {
			locationButton.imageView?.tintColor = .gray
			locationButton.tintColor = .gray
			currentStationCode = "-1"
			self.boardTrains = []
			self.boardTableView.reloadData()
		} else {
			locationButton.imageView?.tintColor = .systemBlue
			locationButton.tintColor = .systemBlue
			currentStationCode = nearestStation
			queryMOTC()
		}
	}
	
	func queryMOTC() {
		presentActivityIndicator()
		
		let queue = DispatchQueue(label: "MOTC")
		queue.async {
			self.boardTrains = MOTCQuery.shared.queryStationBoard(stationCode: self.currentStationCode)
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
	
	func fetchLastViewStation() {
		do {
			lastViewStation = try context.fetch(Record.fetchRequest()) as? [Record]
			if let lastViewStation = lastViewStation {
				if(lastViewStation.count > 0) {
					if let station = lastViewStation[lastViewStation.count - 1].lastViewStation {
						self.currentStationCode = station
					}
					else {
						print("recorded lastViewStation is nil")
					}
				}
			}
			else {
				print("lastViewStation fetch returned nil")
			}
		} catch {
			print("Error fetching lastViewStation")
		}
	}
	
	func updateLastViewStation() {
		var record: Record?
		if(lastViewStation == nil || lastViewStation!.count == 0) {
			record = Record(context: self.context)
		}
		else {
			record = lastViewStation![lastViewStation!.count - 1]
		}
		record?.lastViewStation = self.currentStationCode
		do {
			try self.context.save()
		}
		catch {
			print("Error saving lastViewStation")
		}
	}
	
	func checkInitial() -> Bool {
		var initialUse: Bool?
		do {
			let initial = try context.fetch(Initial.fetchRequest()) as! [Initial]
			if(initial.count > 0 && initial[initial.count - 1].notInitialUse == true) {
				initialUse = false
			}
			else {
				initialUse = true
			}
		} catch {
			print("Error fetching Initial")
			initialUse = true
		}
		
		return (initialUse ?? true) ? true:false
	}
	
	func presentWelcomeWarning() {
	
		DispatchQueue.main.async {
			let welcomeAlert = UIAlertController(title: "溫馨提示", message: "請使用者以參考表定發車時間為主，勿因列車顯示延誤而更動行程。\n資料來源：交通部PTX平臺", preferredStyle: .alert)
			let okAction = UIAlertAction(title: "我知道了", style: .default, handler: {_ in
				let newInitial = Initial(context: self.context)
				newInitial.notInitialUse = true
				do {
					try self.context.save()
				} catch {
					print("Error saving Initial")
				}
				
				self.initialSetup()
				self.dismissActivityIndicator()
				self.locationManager.requestWhenInUseAuthorization()
			})
			welcomeAlert.addAction(okAction)
			self.present(welcomeAlert, animated: true, completion: nil)
		}
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		if(CLLocationManager.locationServicesEnabled() &&
			(CLLocationManager.authorizationStatus() == .authorizedAlways ||
			CLLocationManager.authorizationStatus() == .authorizedWhenInUse)){
			
			locationManager.startUpdatingLocation()
			isUpdatingLocation = true
		}
		// if put 'else' here, the alertController would present unintended situation
	}
	
	func configureAdBanner() {
		let adSize = (Int.random(in: 0...5) == 3) ? kGADAdSizeLargeBanner:kGADAdSizeBanner
		
		adBannerView = GADBannerView(adSize: adSize)
		
		adBannerView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(adBannerView)
		view.addConstraints([NSLayoutConstraint(item: adBannerView!, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: adBannerView!, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0.0)])
		self.adBannerView.isHidden = true
		adBannerView.delegate = self
		adBannerView.adUnitID = "ca-app-pub-5814041924860954/6593980317"
		#warning("test banner id NOTICE THE NUMBERS BEFORE SLASH")
		adBannerView.rootViewController = self
		
		informationButtonToAdBannerLayout = NSLayoutConstraint(item: informationButton!, attribute: .bottom, relatedBy: .equal, toItem: adBannerView, attribute: .top, multiplier: 1.0, constant: -15.0)
		
		// my new banner ad id: ca-app-pub-5814041924860954/6593980317
		// header banner ad id: ca-app-pub-5814041924860954/6968493215
		// test banner ad id: ca-app-pub-3940256099942544/2934735716
		// F413ED9C-BBA4-4E3D-803F-84D6789B0B93
		
		headerAdBannerView = GADBannerView()
		boardTableView.tableHeaderView = headerAdBannerView
		boardTableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: boardTableView.frame.width, height: 0)
		boardTableView.tableHeaderView?.isHidden = true
		headerAdBannerView.delegate = self
		headerAdBannerView.adUnitID = "ca-app-pub-5814041924860954/6968493215"
		headerAdBannerView.rootViewController = self
	}
	
	@objc func removeAdSuccess() {
		let msg = displayAd ? "移除廣告":"復原廣告"
		ErrorAlert.presentErrorAlert(title: msg, message: "")
		
		do {
			needAdData = try context.fetch(Ad.fetchRequest()) as! [Ad]
			needAdData[needAdData.count - 1].needAd = !displayAd
			try self.context.save()
		}
		catch {
			print("Error saving context remove ad")
		}
	}
	
	func checkAdRemoval() {
		do {
			needAdData = try context.fetch(Ad.fetchRequest()) as! [Ad]
			if(needAdData.count > 0 && needAdData[needAdData.count - 1].needAd == false) {
				print("No need ad")
				displayAd = false
			}
			else {
				if(needAdData.count == 0) {
					let ad = Ad(context: self.context)
					ad.needAd = true
					try self.context.save()
				}
				print("Need Ad")
				displayAd = true
			}
		} catch {
			print("Error fetching or storing needAd")
			displayAd = true
		}
	}
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if(boardTrains.count == 0) {
			return 0
		}
		
		return boardTrains.count	// increase the rows in order to compensate hiding on iPhone X+
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		if(indexPath.row < boardTrains.count) {
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
		else {
			let cell = TrainBoardCell()
			cell.backgroundColor = .black
			
			return cell
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let routeDetailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "RouteDetailVC") as! RouteDetailViewController
		
		let sourceView = (tableView.cellForRow(at: indexPath) as! TrainBoardCell).typeLabel
		let sourceRect = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: (sourceView?.frame.size)!)
		
		routeDetailVC.train = boardTrains[indexPath.row]
		routeDetailVC.currentStationCode = currentStationCode
		
		routeDetailVC.modalPresentationStyle = .popover
		routeDetailVC.preferredContentSize = CGSize(width: 220.0, height: 500.0)
		routeDetailVC.popoverPresentationController?.delegate = self
		routeDetailVC.popoverPresentationController?.sourceView = sourceView
		routeDetailVC.popoverPresentationController?.sourceRect = sourceRect
		routeDetailVC.popoverPresentationController?.permittedArrowDirections = .left
		
		self.present(routeDetailVC, animated: true, completion: nil)
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
		
		if(segue.identifier == "StationSelection") {
			let destination = segue.destination as! StationSelectionViewController
			
			destination.popoverPresentationController?.delegate = self
			
			let positionInList = (TRA.stationPositionInList[currentStationCode] ?? TRA.stationPositionInList["1000"])!
			destination.preferredContentSize = CGSize(width: 200, height: 350)
			destination.regionAutoscrollPosition = positionInList[0]
			destination.stationAutoscrollPosition = positionInList[1]
			destination.selectedRegion = positionInList[0]
		}
		
		else if(segue.identifier == "About") {
			let destination = segue.destination as! AboutViewController
			
			destination.popoverPresentationController?.delegate = self
			
			destination.preferredContentSize = CGSize(width: 350, height: 220)
		}
	}
	
	func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
		return .none
	}
}

extension ViewController: GADBannerViewDelegate {
	func adViewWillPresentScreen(_ bannerView: GADBannerView) {
		print("Ad will present")
	}
	
	func adViewDidRecordImpression(_ bannerView: GADBannerView) {
		print("Ad impression recorded")
	}
	
	func adViewDidReceiveAd(_ bannerView: GADBannerView) {
		
		if(bannerView == self.adBannerView) {
			print("Banner Ad loaded successfully")
			self.adBannerView.isHidden = false
			
			informationButtonToSafeAreaLayout.isActive = false
			informationButtonToAdBannerLayout?.isActive = true
		} else {
			print("Header Ad loaded successfully")
			boardTableView.tableHeaderView?.isHidden = false
		}
	}
	
	func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
		
		if(bannerView == self.adBannerView) {
			print("Banner Ad failed to load. \(error.localizedDescription) code: \(error.code)")
			informationButtonToSafeAreaLayout.isActive = true
			informationButtonToAdBannerLayout?.isActive = false
		} else {
			print("Header Ad failed to load. \(error.localizedDescription) code: \(error.code)")
			boardTableView.tableHeaderView?.isHidden = true
		}
	}
}
