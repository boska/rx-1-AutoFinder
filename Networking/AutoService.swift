import Foundation
import RxSwift
import RxCocoa

enum ResponseError: Error {
  case cannotParseJSON
  case noMorePage
}

final class AutoService {
  static let shared = AutoService(baseURL: "https://api.boska.dev/v1/car-types")

  private let session: URLSession
  private let defaultPageSize = 15
  private let apiKey: String
  private let baseURL: String

  init(baseURL: String, session: URLSession = URLSession.shared) {
    self.session = session
    self.baseURL = baseURL
    self.apiKey = Secret.loadFromPlist()?.apiKey ?? ""
  }

  func getManufacturers(on page: Int) -> Observable<[Manufacturer]> {
    let url = URL(string: "\(baseURL)/manufacturer?page=\(page)&pageSize=\(defaultPageSize)&wa_key=\(apiKey)")!
    return session.rx
      .json(url: url)
      .flatMap { json throws -> Observable<[Manufacturer]> in
        guard
          let json = json as? [String: Any],
          let dictionary = json["wkda"] as? [String: String]
          else {
            return Observable.error(ResponseError.cannotParseJSON)
        }
        let manufacturers = dictionary.map({ (key, value) -> Manufacturer in
          Manufacturer(id: key, name: value)
        })
        return manufacturers.isEmpty ? Observable.error(ResponseError.noMorePage) : Observable.just(manufacturers)
    }
  }

  func getMainTypes(with manufacturerID: String, on page: Int) -> Observable<[MainType]> {
    let url = URL(string: "\(baseURL)/main-types?manufacturer=\(manufacturerID)&page=\(page)&pageSize=\(defaultPageSize)&wa_key=\(apiKey)")!
    return session.rx
      .json(url: url)
      .flatMap { json throws -> Observable<[MainType]> in
        guard
          let json = json as? [String: Any],
          let dictionary = json["wkda"] as? [String: String]
          else {
            return Observable.error(ResponseError.cannotParseJSON)
        }
        let models = dictionary.map({ _, value in
          MainType(name: value)
        })
        return models.isEmpty ? Observable.error(ResponseError.noMorePage) : Observable.just(models)
    }
  }
}
