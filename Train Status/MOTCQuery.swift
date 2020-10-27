//
//  MOTCQuery.swift
//  TourTour
//
//  Created by Garry Yeung on 2020/3/10.
//  Copyright © 2020 Garry Yeung. All rights reserved.
//

import Foundation
import CryptoKit

class MOTCQuery {
	let furtherestTrainTime: Double = 60 * 60
	let timeoutForRequest = 10.0
	let timeoutForResource = 15.0
	
	static let shared = MOTCQuery()
	
	let appID = "1baabcfdb12a4d88bd4b19c7a2c3fd23"
	let appKey = "4hYdvDltMul8kJTyx2CbciPeM1k"
	
	var authDateFormatter = DateFormatter()
	var authTimeString: String!
	var authorization: String!
	
	var urlConfig = URLSessionConfiguration.default
	
	init() {
		authDateFormatter = DateFormatter()
		authDateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ww zzz"
		authDateFormatter.locale = Locale(identifier: "en_US")
		authDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
		
		urlConfig.timeoutIntervalForRequest = timeoutForRequest
		urlConfig.timeoutIntervalForResource = timeoutForResource
	}
	
	func authentication() {
		//	Prepare authentication for MOTC website
		self.authTimeString = authDateFormatter.string(from: Date())
		
		let signDate = String(format: "x-date: %@", self.authTimeString)
		let key = SymmetricKey(data: Data(self.appKey.utf8))
		let hmac = HMAC<SHA256>.authenticationCode(for: Data(signDate.utf8), using: key)
		let base64HmacString = Data(hmac).base64EncodedString()
		
		self.authorization = "hmac username=\"\(self.appID)\", algorithm=\"hmac-sha256\", headers=\"x-date\", signature=\"\(base64HmacString)\""
	}
	
	func queryStationBoard(stationCode: String) -> [Train] {
		var trainList: [Train] = []
		let semaphore = DispatchSemaphore(value: 0)
		
		// Because API returns only time(no date) from each train, so need to append date in order to compare with current time
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
		formatter.timeZone = TimeZone(abbreviation: "UTC+8")
		let formatter2 = DateFormatter()
		formatter2.dateFormat = "yyyy-MM-dd"
		formatter2.timeZone = TimeZone(abbreviation: "UTC+8")
		
		authentication()
		
		let url = URL(string: "https://ptx.transportdata.tw/MOTC/v2/Rail/TRA/LiveBoard/Station/\(stationCode)?$format=JSON")!
		var request = URLRequest(url: url)
		request.setValue(authTimeString, forHTTPHeaderField: "x-date")
		request.setValue(authorization, forHTTPHeaderField: "Authorization")
		let session = URLSession(configuration: urlConfig)
		let task = session.dataTask(with: request) { (data, response, error) in
			if let error = error {
				print("Error: \(error.localizedDescription)")
				
				DispatchQueue.main.async {
					ErrorAlert.presentErrorAlert(title: "網路錯誤", message: "網路連線不穩 請稍後再試")
				}
			}
			else if let response = response as? HTTPURLResponse,
				let data = data {
				if(response.statusCode == 200) {
					let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
					for rawTrain in rawReturned! {
						let train = rawTrain as [String: Any]
						
						let trainTypeCode = train["TrainTypeCode"] as! String
						let trainNumber = train["TrainNo"] as! String
						let direction = (train["Direction"] as! Int == 0) ? "順行":"逆行"
						let trainLine: String
						switch train["TripLine"] as! Int {
						case 0:
							trainLine = ""
						case 1:
							trainLine = "山線"
						case 2:
							trainLine = "海線"
						default:
							trainLine = ""
						}
						let endingStation = (train["EndingStationName"] as! [String: Any])["Zh_tw"] as! String
						let departure = train["ScheduledDepartureTime"] as! String
						let delay = train["DelayTime"] as! Int
						
						let trainType: String
						switch trainTypeCode {
						case "1":
							trainType = TrainClass.Taroko
						case "2":
							trainType = TrainClass.Puyuma
						case "3":
							trainType = TrainClass.TzeChiang
						case "4":
							trainType = TrainClass.ChuKuang
						case "5":
							trainType = TrainClass.FuXing
						case "6":
							trainType = TrainClass.Local
						case "7":
							trainType = TrainClass.Ordinary
						case "10":
							trainType = TrainClass.LocalExpress
						default:
							trainType = TrainClass.None
						}
						
						let departureTime = formatter.date(from: String(format: "%@ %@", formatter2.string(from: Date()), departure))
						
						//print(String(format: "%@%@\t往%@\t%@\t%@\t%@\t延誤%d分", trainType, trainNumber, endingStation, trainLine, direction, departure, delay))
						
						let calendar = Calendar.current
						let updatedTime = calendar.date(byAdding: .minute, value: delay, to: departureTime!)
						let interval = updatedTime!.timeIntervalSince(Date())
						var degree = 0
						if(-30 <= interval && interval <= 90) {
							degree = 1
						}
						else if(90 < interval && interval < 300) {
							degree = 2
						}
						
						if(-300 <= interval && interval <= self.furtherestTrainTime) {	// filter out departed train
							let depart = (interval <= -30) ? true:false
							trainList.append(Train(type: trainType, number: trainNumber, ending: endingStation, direction: direction, line: trainLine, departure: departureTime!, delay: delay, degreeOfIndicator: degree, departed: depart))
						}
					}
				}
				else {
					print("Response not 200")
					DispatchQueue.main.async {
						ErrorAlert.presentErrorAlert(title: "網路錯誤 \(response.statusCode)", message: "請稍後再試")
					}
				}
			}
			semaphore.signal()
		}
		
		// Due to some specific trains do not show up from the API above, the following API is used to compensate
		let url2 = URL(string: "https://ptx.transportdata.tw/MOTC/v3/Rail/TRA/DailyStationTimetable/Today/Station/\(stationCode)?$select=Direction%2C%20TimeTables&$format=JSON")!
		request = URLRequest(url: url2)
		request.setValue(authTimeString, forHTTPHeaderField: "x-date")	// this line should not be excluded
		request.setValue(authorization, forHTTPHeaderField: "Authorization")	// this line should not be excluded
		let session2 = URLSession(configuration: urlConfig)
		let task2 = session2.dataTask(with: request) { (data, response, error) in
			if let error = error {
				print("MOTC query error: \(error.localizedDescription)")
				DispatchQueue.main.async {
					ErrorAlert.presentErrorAlert(title: "網路錯誤", message: "網路連線不穩 請稍後再試")
				}
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [String: Any])["StationTimetables"] as? [[String: Any]]
					
					let currentTime = Date()
					formatter.dateFormat = "yyyy-MM-dd HH:mm"	// above API has HH:mm:ss, so change here
					
					for rawDirection in rawReturned! {
						let direction = (rawDirection["Direction"] as! Int == 0) ? "順行":"逆行"
						let rawTrain = rawDirection["TimeTables"] as! [[String: Any]]
						for train in rawTrain {
							let departure = train["DepartureTime"] as! String
							let departureTime = formatter.date(from: String(format: "%@ %@", formatter2.string(from: Date()), departure))
							let interval = departureTime!.timeIntervalSince(currentTime)
							
							if(interval > self.furtherestTrainTime) {
								break
							}
							if(interval < -300){
								continue
							}
							
							let trainNumber = train["TrainNo"] as! String
							if let _ = trainList.firstIndex(where: {$0.trainNumber == trainNumber}) {
								continue	// exclude trains that already added from the API above
							}
							
							let trainTypeCode = train["TrainTypeCode"] as! String
							let endingStation = (train["DestinationStationName"] as! [String: Any])["Zh_tw"] as! String
							
							let trainType: String
							switch trainTypeCode {
							case "1":
								trainType = TrainClass.Taroko
							case "2":
								trainType = TrainClass.Puyuma
							case "3":
								trainType = TrainClass.TzeChiang
							case "4":
								trainType = TrainClass.ChuKuang
							case "5":
								trainType = TrainClass.FuXing
							case "6":
								trainType = TrainClass.Local
							case "7":
								trainType = TrainClass.Ordinary
							case "10":
								trainType = TrainClass.LocalExpress
							default:
								trainType = TrainClass.None
							}
							
							//print(String(format: "%@%@\t往%@\t%@\t%@\t延誤%d分 從時刻表加入", trainType, trainNumber, endingStation, direction, departure, 0))
							
							var degree = 0
							if(-30 <= interval && interval <= 90) {
								degree = 1
							}
							else if(90 < interval && interval < 300) {
								degree = 2
							}
							let depart = (interval <= -30) ? true:false
							trainList.append(Train(type: trainType, number: trainNumber, ending: endingStation, direction: direction, line: "", departure: departureTime!, delay: 0, degreeOfIndicator: degree, departed: depart))
						}
					}
				}
				else {
					print("Response not 200")
					DispatchQueue.main.async {
						ErrorAlert.presentErrorAlert(title: "網路錯誤 \(response.statusCode)", message: "請稍後再試")
					}
				}
			}
			semaphore.signal()
		}
		
		task.resume()
		semaphore.wait()
		task2.resume()
		semaphore.wait()
		
		// sort the trainList
		trainList.sort(by: {$0.departureTime <= $1.departureTime})
		
		return trainList
	}
}

class Train {
	let trainType: String
	let trainNumber: String
	let endingStation: String
	let direction: String
	let trainLine: String
	let departureTime: Date
	let delayTime: Int
	let departed: Bool
	
	let degreeOfIndicator: Int
	
	init(type: String, number: String, ending: String, direction: String, line: String, departure: Date, delay: Int, degreeOfIndicator: Int, departed: Bool) {
		self.trainType			= type
		self.trainNumber		= number
		self.endingStation		= ending
		self.direction			= direction
		self.trainLine			= line
		self.departureTime		= departure
		self.delayTime			= delay
		self.degreeOfIndicator	= degreeOfIndicator
		self.departed			= departed
	}
}

enum TrainClass {
	static let None			= ""
	static let Standard		= "標準廂"
	static let Business		= "商務廂"
	static let NonReserved	= "自由座"
	static let Taroko		= "太魯閣"
	static let Puyuma		= "普悠瑪"
	static let TzeChiang	= "自強"
	static let ChuKuang		= "莒光"
	static let FuXing		= "復興"
	static let Local		= "區間"
	static let LocalExpress	= "區間快"
	static let Ordinary		= "普快"
}
