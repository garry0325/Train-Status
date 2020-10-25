//
//  Initial+CoreDataProperties.swift
//  
//
//  Created by Garry Yeung on 2020/10/26.
//
//

import Foundation
import CoreData


extension Initial {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Initial> {
        return NSFetchRequest<Initial>(entityName: "Initial")
    }

    @NSManaged public var notInitialUse: Bool

}
