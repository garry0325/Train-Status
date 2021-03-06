//
//  RouteDetailTableViewCell.swift
//  Train Status
//
//  Created by Garry Yeung on 2020/11/11.
//  Copyright © 2020 Garry Yeung. All rights reserved.
//

import UIKit

class RouteDetailTableViewCell: UITableViewCell {
	
	var stationName = "" {
		didSet {
			stationNameLabel.text = stationName
		}
	}
	
	var isCurrentStation = false {
		didSet {
			currentStationIndicatorView.isHidden = !isCurrentStation
			stationNameLabel.font = isCurrentStation ? UIFont.systemFont(ofSize: 20.0, weight: .bold):UIFont.systemFont(ofSize: 17.0, weight: .regular)
			departTimeLabel.font = isCurrentStation ? UIFont.monospacedDigitSystemFont(ofSize: 19.0, weight: .bold):UIFont.monospacedDigitSystemFont(ofSize: 17.0, weight: .regular)
			delayTimeLabel.isHidden = !isCurrentStation
		}
	}
	var isDepartureStation = false {
		didSet {
			routeLineUp.isHidden = isDepartureStation
		}
	}
	var isDestinationStation = false {
		didSet {
			routeLineBottom.isHidden = isDestinationStation
		}
	}
	var departTime = "" {
		didSet {
			departTimeLabel.text = departTime
		}
	}
	var delayTime = 0 {
		didSet {
			if(delayTime > 0) {
				delayTimeLabel.text = "晚\(delayTime)分"
				
				delayTimeLabel.frame = NSString(string: delayTimeLabel.text!).boundingRect(with: CGSize(width: 78.0, height: delayTimeLabel.frame.height), options: [.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font :UIFont.systemFont(ofSize: 12)], context: nil)
			}
			else {
				delayTimeLabel.text = ""
			}
		}
	}
	var trainStatus: TrainLivePosition.Status = .Departed {
		didSet {
			switch trainStatus {
			case .Approaching, .AtStation:
				trainAtStationImage.isHidden = false
				trainDepartStationImage.isHidden = true
			case .Departed:
				trainAtStationImage.isHidden = true
				trainDepartStationImage.isHidden = false
			default:
				trainAtStationImage.isHidden = true
				trainDepartStationImage.isHidden = true
			}
		}
	}

	@IBOutlet var stationNameLabel: UILabel!
	@IBOutlet var stationNodeView: UIImageView!
	@IBOutlet var currentStationIndicatorView: UIImageView!
	@IBOutlet var departTimeLabel: UILabel!
	@IBOutlet var delayTimeLabel: UILabel!
	@IBOutlet var trainAtStationImage: UIImageView!
	@IBOutlet var trainDepartStationImage: UIImageView!
	@IBOutlet var routeLineUp: UIImageView!
	@IBOutlet var routeLineBottom: UIImageView!
	
	
    override func awakeFromNib() {
        super.awakeFromNib()
		
		currentStationIndicatorView.tintColor = .white
		currentStationIndicatorView.layer.borderColor = UIColor.systemBlue.cgColor
		currentStationIndicatorView.layer.cornerRadius = currentStationIndicatorView.frame.width / 2
		currentStationIndicatorView.layer.borderWidth = 5.0
		currentStationIndicatorView.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
