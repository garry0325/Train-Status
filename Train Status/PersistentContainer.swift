//
//  PersistentContainer.swift
//  Train Status
//
//  Created by Garry Yeung on 2020/10/25.
//  Copyright © 2020 Garry Yeung. All rights reserved.
//

import UIKit
import CoreData

class PersistentContainer: NSPersistentContainer {
	func saveContext(backgroundContext: NSManagedObjectContext? = nil) {
		let context = backgroundContext ?? viewContext
		guard context.hasChanges else { return }
		do {
			try context.save()
		} catch let error as NSError {
			print("Error: \(error), \(error.userInfo)")
		}
	}
}
