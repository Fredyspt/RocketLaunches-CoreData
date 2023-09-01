/// Copyright (c) 2023 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import CoreData
import SwiftUI

extension RocketLaunch {
  @NSManaged public var name: String
  @NSManaged public var launchDate: Date
  @NSManaged public var isViewed: Bool
  @NSManaged public var launchpad: String?
  @NSManaged public var notes: String?
  @NSManaged public var tags: Set<RocketLaunchTag>
  @NSManaged public var list: Set<RocketLaunchList>
  
  static func createWith(
    name: String,
    launchDate: Date,
    isViewed: Bool,
    launchPad: String?,
    notes: String?,
    tags: Set<RocketLaunchTag>,
    in list: RocketLaunchList,
    using managedObjectContext: NSManagedObjectContext
  ) {
    let launch = RocketLaunch(context: managedObjectContext)
    launch.name = name
    launch.notes = notes
    launch.tags = tags
    launch.isViewed = isViewed
    launch.launchDate = launchDate
    launch.launchpad = launchPad
    launch.addToList(list)
    
    do {
      try managedObjectContext.save()
    } catch {
      let nsError = error as NSError
      fatalError("Failed to save object to store. \(nsError), \(nsError.userInfo)")
    }
  }
  
  static func basicFetchRequest() -> FetchRequest<RocketLaunch> {
    FetchRequest(entity: RocketLaunch.entity(), sortDescriptors: [])
  }
  
  static func sortedFetchRequest() -> FetchRequest<RocketLaunch> {
    let launchDateSortDescriptor = NSSortDescriptor(key: "launchDate", ascending: true)
    return FetchRequest<RocketLaunch>(entity: RocketLaunch.entity(), sortDescriptors: [launchDateSortDescriptor])
  }
  
  static func fetchRequestSortedByNameAndLaunchDate() -> FetchRequest<RocketLaunch> {
    let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
    let launchDateSortDescriptor = NSSortDescriptor(key: "launchDate", ascending: true)
    return FetchRequest<RocketLaunch>(
      entity: RocketLaunch.entity(),
      sortDescriptors: [
        nameSortDescriptor, // Will sort the list by name first
        launchDateSortDescriptor // For cases that the name is the same, it will sort them by launch date
      ]
    )
  }
  
  static func unViewedLaunchedFetchRequest() -> FetchRequest<RocketLaunch> {
    let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
    let launchDateSortDescriptor = NSSortDescriptor(key: "launchDate", ascending: true)
    let isViewedPredicate = NSPredicate(format: "%K == %@", "isViewed", NSNumber(value: false)) // %K replaces a keypath on the fetched result, whilst %@ substitues an object value type, hence needing to wrap the boolean in an NSNumber object type.
    return FetchRequest(entity: RocketLaunch.entity(), sortDescriptors: [nameSortDescriptor, launchDateSortDescriptor], predicate: isViewedPredicate)
  }
  
  static func launches(in list: RocketLaunchList) -> FetchRequest<RocketLaunch> {
    let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
    let launchDateSortDescriptor = NSSortDescriptor(key: "launchDate", ascending: true)
    // Since a rocket launch can have multiple lists associated, using the ANY keyword will search
    // for the title of ANY of the lists the launch has.
    let listPredicate = NSPredicate(format: "ANY %K == %@", "list.title", list.title!)
    let isViewedPredicate = NSPredicate(format: "%K == %@", "isViewed", NSNumber(value: false))
    let compoundedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [listPredicate, isViewedPredicate])
    return FetchRequest<RocketLaunch>(
      entity: RocketLaunch.entity(),
      sortDescriptors: [nameSortDescriptor, launchDateSortDescriptor],
      predicate: compoundedPredicate
    )
  }
}

// MARK: Generated accessors for list
extension RocketLaunch {
  @objc(addListObject:)
  @NSManaged public func addToList(_ value: RocketLaunchList)

  @objc(removeListObject:)
  @NSManaged public func removeFromList(_ value: RocketLaunchList)

  @objc(addList:)
  @NSManaged public func addToList(_ values: NSSet)

  @objc(removeList:)
  @NSManaged public func removeFromList(_ values: NSSet)
}

extension RocketLaunch: Identifiable { }
