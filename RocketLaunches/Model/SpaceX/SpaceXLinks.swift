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

struct SpaceXLinksJSON: BatchInsertable {
  var patch: [String: String?]
  var reddit: [String: String?]
  var flickr: [String: [String]]
  var presskit: String?
  var webcast: String?
  var youtubeId: String?
  var article: String?
  var wikipedia: String?
  var id = UUID()

  private enum CodingKeys: String, CodingKey {
    case patch
    case reddit
    case flickr
    case presskit
    case webcast
    case youtubeId = "youtube_id"
    case article
    case wikipedia
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.wikipedia = try container.decode(Optional<String>.self, forKey: .wikipedia)
    self.article = try container.decode(Optional<String>.self, forKey: .article)
    self.youtubeId = try container.decode(Optional<String>.self, forKey: .youtubeId)
    self.webcast = try container.decode(Optional<String>.self, forKey: .webcast)
    self.presskit = try container.decode(Optional<String>.self, forKey: .presskit)
    self.flickr = try container.decode([String: [String]].self, forKey: .flickr)
    self.reddit = try container.decode([String: String?].self, forKey: .reddit)
    self.patch = try container.decode([String: String?].self, forKey: .patch)

    for (key, value) in reddit {
      // swiftlint:disable:next for_where
      if value == nil {
        reddit[key] = ""
      }
    }

    for (key, value) in patch {
      // swiftlint:disable:next for_where
      if value == nil {
        patch[key] = ""
      }
    }
  }

  var dictionaryValue: [String: Any] {
    [
      "patch": patch as Any,
      "reddit": reddit as Any,
      "flickr": flickr as Any,
      "presskit": presskit as Any,
      "webcast": webcast as Any,
      "youtubeid": youtubeId as Any,
      "article": article as Any,
      "wikipedia": wikipedia as Any,
      "id": id
    ]
  }
}
