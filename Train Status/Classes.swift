//
//  Classes.swift
//  Train Status
//
//  Created by Garry Yeung on 2020/11/11.
//  Copyright © 2020 Garry Yeung. All rights reserved.
//

import Foundation
import UIKit

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

class TrainRoute {
	let trainNumber: String
	let trainType: String
	let endingStation: String
	let direction: Int
	let trainLine: String
	let wheelChair: Bool
	let bike: Bool
	var routeStations: [Station]?
	
	init(trainNumber: String, trainType: String, endingStation: String, direction: Int, trainLine: String, wheelChair: Bool, bike: Bool) {
		self.trainType =  trainType
		self.trainNumber = trainNumber
		self.endingStation = endingStation
		self.direction = direction
		self.trainLine = trainLine
		self.wheelChair = wheelChair
		self.bike = bike
	}
}

class Station {
	let stationId: String
	let stationName: String
	let stopSequence: Int
	let arrivalTime: String
	let departureTime: String
	
	var isCurrentStation: Bool = false
	var isDepartureStation: Bool = false
	var isDestinationStation: Bool = false
	
	var trainWithStationStatus: TrainLivePosition.Status = .None
	
	init(stationId: String, stationName: String, stopSequence: Int, arrivalTime: String, departureTime: String) {
		self.stationId = stationId
		self.stationName = stationName
		self.stopSequence = stopSequence
		self.arrivalTime = arrivalTime
		self.departureTime = departureTime
	}
}

class TrainLivePosition {
	let stationId: String
	let stationName: String
	let stationStatus: Status
	let delayTime: Int
	
	init(stationId: String, stationName: String, stationStatus: Status, delayTime: Int) {
		self.stationId = stationId
		self.stationName = stationName
		self.stationStatus = stationStatus
		self.delayTime = delayTime
	}
	
	enum Status: Int {
		case Approaching	= 0
		case AtStation		= 1
		case Departed		= 2
		case None			= 3
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
