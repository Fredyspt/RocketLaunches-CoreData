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
  @NSManaged public var launchPad: String?
  @NSManaged public var notes: String?
  
  static func createWith(
    name: String,
    launchDate: Date,
    isViewed: Bool,
    launchPad: String?,
    notes: String?,
    using managedObjectContext: NSManagedObjectContext
  ) {
    let launch = RocketLaunch(context: managedObjectContext)
    launch.name = name
    launch.notes = notes
    launch.isViewed = isViewed
    launch.launchDate = launchDate
    launch.launchPad = launchPad
    
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
    let isViewedPredicate = NSPredicate(format: "%K == %@", "isViewed", NSNumber(value: false)) // %K replaces a keypath on the fetched result
    return FetchRequest(entity: RocketLaunch.entity(), sortDescriptors: [nameSortDescriptor, launchDateSortDescriptor], predicate: isViewedPredicate)
  }
}

extension RocketLaunch: Identifiable { }
