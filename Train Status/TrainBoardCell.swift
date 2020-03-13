//
//  TrainBoardCell.swift
//  Train Status
//
//  Created by Garry Yeung on 2020/3/12.
//  Copyright © 2020 Garry Yeung. All rights reserved.
//

import UIKit

class TrainBoardCell: UITableViewCell {
	
	@IBOutlet var numberLabel: UILabel!
	@IBOutlet var destinationLabel: UILabel!
	@IBOutlet var typeLabel: UILabel!
	@IBOutlet var lineLabel: UILabel!
	@IBOutlet var timeLabel: UILabel!
	@IBOutlet var delayLabel: UILabel!
	
	@IBOutlet var upcomingIndicator: UIImageView!
	@IBOutlet var departedDim: UIView!
	
	
	var trainNumber = "200" {
		didSet {
			numberLabel.text = trainNumber
		}
	}
	var trainType = "莒光" {
		didSet {
			switch trainType {
			case "自強", "普悠瑪", "太魯閣":
				typeLabel.textColor = .systemRed
			case "莒光":
				typeLabel.textColor = .systemOrange
			default:
				typeLabel.textColor = .systemBlue
			}
			typeLabel.text = trainType
		}
	}
	var destination = "新左營" {
		didSet {
			destinationLabel.text = destination
		}
	}
	var line = "山線" {
		didSet {
			lineLabel.text = line
		}
	}
	var departure = Date() {
		didSet {
			let formatter = DateFormatter()
			formatter.dateFormat = "HH:mm"
			timeLabel.text = formatter.string(from: departure)
		}
	}
	var delay: Int = 0 {
		didSet {
			if(delay == 0) {
				delayLabel.textColor = .white
				delayLabel.text = "準點"
			}
			else {
				delayLabel.textColor = .systemRed
				delayLabel.text = String(format: "晚%d分", delay)
			}
		}
	}
	var degreeOfIndicator: Int = 0 {
		didSet {
			switch(degreeOfIndicator) {
			case 0:
				upcomingIndicator.isHidden = true
			case 1, 2:
				upcomingIndicator.isHidden = false
			default:
				break
			}
		}
	}
	var departed: Bool = false {
		didSet {
			departedDim.alpha = departed ? 0.5:0.0
		}
	}
	
	override func awakeFromNib() {
		
		super.awakeFromNib()
		// Initialization code
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		// Configure the view for the selected state
	}
	
}
