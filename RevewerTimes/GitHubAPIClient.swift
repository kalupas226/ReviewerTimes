//
//  GitHubAPIClient.swift
//  RevewerTimes
//
//  Created by Aikawa Kenta on 2020/09/26.
//

import ComposableArchitecture
import Foundation

// MARK: API models

struct RequestedReviewers: Decodable, Equatable {
    let requestedReviewers: [Reviewer]
    
    struct Reviewer: Decodable, Equatable, Hashable {
        let login: String
    }
    
    private enum CodingKeys: String, CodingKey {
        case requestedReviewers = "requested_reviewers"
    }
}

// MARK: API client interface

struct GitHubAPIClient {
    var reviewers: () -> Effect<[RequestedReviewers], Failure>
    
    struct Failure: Error, Equatable {}
}

// MARK: Live API implementation
// API(https://docs.github.com/en/free-pro-team@latest/rest/reference/pulls#list-pull-requests)
extension GitHubAPIClient {
    static let live = GitHubAPIClient(
        reviewers: { () -> Effect<[RequestedReviewers], Failure> in
            // your owner
            let owner = ""
            // your repo
            let repo = ""
            var components = URLComponents(string: "https://api.github.com/repos/\(owner)/\(repo)/pulls")!
            components.queryItems = [URLQueryItem(name: "state", value: "all"), URLQueryItem(name: "per_page", value: "100")]
            
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            // enter your token
            request.setValue("", forHTTPHeaderField: "Authorization")
            
            return URLSession.shared.dataTaskPublisher(for: request)
                .map { data, _ in data }
                .decode(type: [RequestedReviewers].self, decoder: JSONDecoder())
                .mapError { _ in Failure() }
                .eraseToEffect()
        }
    )
}
