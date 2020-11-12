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
			departTimeLabel.font = isCurrentStation ? UIFont.systemFont(ofSize: 19.0, weight: .bold):UIFont.systemFont(ofSize: 17.0, weight: .regular)
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
