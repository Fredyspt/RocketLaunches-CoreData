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

import CoreData

enum LaunchError: Error {
  case batchInsertError
}

struct PersistenceController {
  static let shared = PersistenceController()
  
  /// Once populated, will allow you to load dummy data into the preview canvas in Xcode.
  static var preview: PersistenceController = {
    let result = PersistenceController(inMemory: true)
    let viewContext = result.container.viewContext
    
    for i in 0..<10 {
      let newLaunch = RocketLaunch(context: viewContext)
      newLaunch.launchDate = Date()
      newLaunch.name = "Launch \(i + 1)"
      let newList = RocketLaunchList(context: viewContext)
      newList.title = "Sample List"
      newLaunch.list = newList
    }
    
        let launchLinks = SpaceXLinks(context: viewContext)
        launchLinks.patch = [:]
        launchLinks.patch?["small"] = "https://imgur.com/BrW201S.png"
        launchLinks.patch?["large"] = "https://imgur.com/573IfGk.png"
    
        launchLinks.reddit = [:]
        launchLinks.reddit?["campaign"] = "https://www.reddit.com/r/spacex/comments/jhu37i/starlink_general_discussion_and_deployment_thread/"
        launchLinks.reddit?["launch"] = "https://www.reddit.com/r/spacex/comments/t0yksi/rspacex_starlink_411_launch_discussion_and/"
        launchLinks.reddit?["media"] = nil
        launchLinks.reddit?["recovery"] = "https://www.reddit.com/r/spacex/comments/k2ts1q/rspacex_fleet_updates_discussion_thread/"
    
        launchLinks.flickr = [:]
        launchLinks.flickr?["small"] = []
        launchLinks.flickr?["original"] = []
    
        launchLinks.presskit = nil
        launchLinks.webcast = "https://youtu.be/nnVOfKOzXHE"
        launchLinks.youtubeId = "nnVOfKOzXHE"
        launchLinks.article = nil
        launchLinks.wikipedia = "https://en.wikipedia.org/wiki/Starlink"
    
        let spaceXLaunch = SpaceXLaunch(context: viewContext)
        spaceXLaunch.name = "Starlink 4-11 (v1.5)"
        spaceXLaunch.links = launchLinks
        spaceXLaunch.dateUtc = "2022-02-25T17:12:00.000Z"
        spaceXLaunch.flightNumber = 151
    
    do {
      try viewContext.save()
    } catch {
      let nsError = error as NSError
      fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
    return result
  }()
  
  /// Given a Data Model, this class creates the underlined Managed Object Model,
  /// the Managed Object Context, and the Persistent Store Coordinator for you.
  let container: NSPersistentContainer
  
  init(inMemory: Bool = false) {
    // The name is used to named the persistent container, but it's
    // also used to look up the name of the NSManagedObjectModel object
    // used with the NSPersistentContainer object.
    // Using the same name as the data model will wnsure that the managedObject
    // model will use the models you defined in the .xcdatamodel file
    container = NSPersistentContainer(name: "RocketLaunches")
    
    if inMemory {
      container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
    }
    
    container.loadPersistentStores { _, error in
      if let error = error as? NSError {
        fatalError("Unresolved error \(error), \(error.userInfo )")
      }
    }
    
    // Allow CoreData to work asynchronously, these properties define some
    // rules when merging data from various threads.
    container.viewContext.automaticallyMergesChangesFromParent = true
    // This will help differentiate other context that might be created later on.
    container.viewContext.name = "viewContext"
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    container.viewContext.undoManager = nil
    container.viewContext.shouldDeleteInaccessibleFaults = true
  }
  
  static func fetchSpaceXLaunches() async throws {
    let launches = try await SpaceXAPI.getAllLaunches()
    do {
      try PersistenceController.shared.importLaunches(from: launches, to: "All")
    } catch {
      print("error is \(error)")
    }
    
    let upcomingLaunches = try await SpaceXAPI.getUpcomingLaunches()
    do {
      try PersistenceController.shared.importLaunches(from: upcomingLaunches, to: "Upcoming")
    } catch {
      print("error is \(error)")
    }
    
    let pastLaunches = try await SpaceXAPI.getPastLaunches()
    do {
      try PersistenceController.shared.importLaunches(from: pastLaunches, to: "Past")
    } catch {
      print("error is \(error)")
    }
    
    let latestLaunches = try await SpaceXAPI.getLatestLaunch()
    do {
      try PersistenceController.shared.importLaunches(from: latestLaunches, to: "Latest")
    } catch {
      print("error is \(error)")
    }
  }
  
  static func createSpaceXLaunchLists() async throws {
    let context = shared.container.newBackgroundContext()
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    try await context.perform {
      let fetchRequest = SpaceXLaunchList.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "title == %@", ["All"])
      var results = try context.fetch(fetchRequest)
      if results.isEmpty {
        let list = SpaceXLaunchList(context: context )
        list.title = "All"
      }
      
      fetchRequest.predicate = NSPredicate(format: "title == %@", ["Upcoming"])
      results = try context.fetch(fetchRequest)
      if results.isEmpty {
        let list = SpaceXLaunchList(context: context )
        list.title = "Upcoming"
      }
      fetchRequest.predicate = NSPredicate(format: "title == %@", ["Past"])
      results = try context.fetch(fetchRequest)
      if results.isEmpty {
        let list = SpaceXLaunchList(context: context )
        list.title = "Past"
      }
      fetchRequest.predicate = NSPredicate(format: "title == %@", ["Latest"])
      results = try context.fetch(fetchRequest)
      if results.isEmpty {
        let list = SpaceXLaunchList(context: context )
        list.title = "Latest"
      }
      try context.save()
    }
  }
  
  static func getAllLists() -> [RocketLaunchList] {
    let fetchRequest = RocketLaunchList.fetchRequest()
    guard let results = try? shared.container.viewContext.fetch(fetchRequest),
          !results.isEmpty else { return [] }
    return results as [RocketLaunchList]
  }
  
  static func getTestLaunch() -> SpaceXLaunch? {
    let fetchRequest = SpaceXLaunch.fetchRequest()
    fetchRequest.fetchLimit = 1
    guard let results = try? preview.container.viewContext.fetch(fetchRequest),
          let first = results.first else { return nil }
    return first
  }
  
  func importLaunches(from launchCollection: [SpaceXLaunchJSON], to listName: String) throws {
    let taskContext = container.viewContext
    
    // 1. Fetch list that matches the given list name
    var list: SpaceXLaunchList!
    let fetchRequest = SpaceXLaunchList.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "title == %@", listName)
    let results = try taskContext.fetch(fetchRequest)
    if let fetchedList = results.first {
      list = fetchedList
    }
    
    // 2. Batch insert SpaceXLaunches
    let launchesBatchInsertRequest = createBatchInsertLaunchRequest(from: launchCollection)
    if let storeResult = try? taskContext.execute(launchesBatchInsertRequest),
       let batchInsertResult = storeResult as? NSBatchInsertResult,
       let success = batchInsertResult.result as? Bool,
       success {
      return
    } else {
      throw LaunchError.batchInsertError
    }
    
    // 3. Batch insert SpaceXFairings associated with the SpaceXLaunches
    let fairings = launchCollection.map { SpaceXLaunchRelationship(launchId: $0.id, relatedObject: $0.fairings) }
    let fairingsBatchInsertRequest = createBatchInsertRelationshipRequest(from: fairings, for: SpaceXFairings.self)
    if let storeResult = try? taskContext.execute(fairingsBatchInsertRequest),
       let batchInsertResult = storeResult as? NSBatchInsertResult,
       let success = batchInsertResult.result as? Bool,
       success {
      return
    } else {
      throw LaunchError.batchInsertError
    }
    
    // 3.1 Establish relationship between saved fairings and SpaceXLaunch
    for relationship in fairings {
      guard let fairing = relationship.relatedObject as? SpaceXFairingsJSON else { continue }
      
      let fairingsFetchRequest = SpaceXFairings.fetchRequest()
      fairingsFetchRequest.predicate = NSPredicate(format: "id == %@", argumentArray: [fairing.id])
      
      let launchesFetchRequest = SpaceXLaunch.fetchRequest()
      launchesFetchRequest.predicate = NSPredicate(format: "id == %@", argumentArray: [relationship.launchId])
      
      let fetchedFairings = try taskContext.fetch(fairingsFetchRequest)
      let fetchedLaunches = try taskContext.fetch(launchesFetchRequest)
      
      guard !fetchedFairings.isEmpty,
            !fetchedLaunches.isEmpty
      else { continue }
      
      let matchedFairing = fetchedFairings[0]
      let matchedLaunch = fetchedLaunches[0]
      matchedFairing.launch = matchedLaunch
    }
    
    try taskContext.save()
    
    // 4. Batch insert SpaceXLinks associates with the SpaceXLaunches
    let links = launchCollection.map { SpaceXLaunchRelationship(launchId: $0.id, relatedObject: $0.links) }
    let linksBatchInsertRequest = createBatchInsertRelationshipRequest(from: links, for: SpaceXLinks.self)
    if let storeResult = try? taskContext.execute(linksBatchInsertRequest),
       let batchInsertResult = storeResult as? NSBatchInsertResult,
       let success = batchInsertResult.result as? Bool,
       success {
      return
    } else {
      throw LaunchError.batchInsertError
    }
    
    // 4.1 Establish the relationship between saved links and launches
    for relationship in links {
      guard let link = relationship.relatedObject as? SpaceXLinksJSON else { continue }
      
      let linksFetchRequest = SpaceXLinks.fetchRequest()
      linksFetchRequest.predicate = NSPredicate(format: "id == %@", argumentArray: [link.id])
      
      let launchesFetchRequest = SpaceXLaunch.fetchRequest()
      launchesFetchRequest.predicate = NSPredicate(format: "id == %@", argumentArray: [relationship.launchId])
      
      let fetchedLinks = try taskContext.fetch(linksFetchRequest)
      let fetchedLaunches = try taskContext.fetch(launchesFetchRequest)
      
      guard !fetchedLinks.isEmpty,
            !fetchedLaunches.isEmpty
      else { continue }
      
      fetchedLinks[0].launch = fetchedLaunches[0]
      fetchedLaunches[0].addToSpaceXList(list)
    }
    
    try taskContext.save()
        
  }
  
  private func createBatchInsertLaunchRequest(from launchCollection: [SpaceXLaunchJSON]) -> NSBatchInsertRequest {
    var index = 0
    let total = launchCollection.count
    
    // Core Data will call the provided dictionaryHandler until it returns true, then it stops and saves the data
    let batchInsertRequest = NSBatchInsertRequest(
      entity: SpaceXLaunch.entity(),
      dictionaryHandler: { dictionary in
        guard index < total else { return true }
        
        dictionary.addEntries(from: launchCollection[index].dictionaryValue as [AnyHashable: Any])
        index += 1
        
        return false
      }
    )
    
    return batchInsertRequest
  }
  
  private func createBatchInsertRelationshipRequest<E: NSManagedObject>(from relationshipCollection: [SpaceXLaunchRelationship], for type: E.Type) -> NSBatchInsertRequest {
    var index = 0
    let total = relationshipCollection.count
    
    let batchInsertRequest = NSBatchInsertRequest(
      entity: E.entity(),
      dictionaryHandler: { dictionary in
        guard index < total else { return true }
        
        guard let value = relationshipCollection[index].relatedObject else {
          index += 1
          return false
        }
        
        dictionary.addEntries(from: value.dictionaryValue as [AnyHashable: Any])
        index += 1
        
        return false
      }
    )
    
    return batchInsertRequest
  }
}
