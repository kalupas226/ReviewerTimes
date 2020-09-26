//
//  ContentView.swift
//  RevewerTimes
//
//  Created by Aikawa Kenta on 2020/09/26.
//

import ComposableArchitecture
import SwiftUI


struct ReviewerState: Equatable {
    var reviewerTimes: [String: Int] = [:]
    var reviewers: [RequestedReviewers.Reviewer] = []
    var isLoading = false
}

enum ReviewerAction: Equatable {
    case reviewersResponse(Result<[RequestedReviewers], GitHubAPIClient.Failure>)
    case getReviewers
}

struct ReviewerEnvironment {
    var githubApiClient: GitHubAPIClient
    var mainQueue: AnySchedulerOf<DispatchQueue>
}

let reviewerReducer = Reducer<ReviewerState, ReviewerAction, ReviewerEnvironment> { state, action, environment in
    switch action {
    // ここ汚いですが許してください
    case let .reviewersResponse(.success(responses)):
        var reviewers: [RequestedReviewers.Reviewer] = []
        for response in responses {
            reviewers.append(contentsOf: response.requestedReviewers)
        }
        let orderedSet: NSOrderedSet = NSOrderedSet(array: reviewers)
        state.reviewers = orderedSet.array as! [RequestedReviewers.Reviewer]

        var reviewerTimes: [String: Int] = [:]
        for reviewer in reviewers {
            reviewerTimes[reviewer.login, default: 0] += 1
        }
        state.reviewerTimes = reviewerTimes
        state.isLoading = false
        return .none
        
    case .getReviewers:
        state.isLoading = true
        return environment.githubApiClient
            .reviewers()
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(ReviewerAction.reviewersResponse)
        
    case let .reviewersResponse(.failure(error)):
        state.reviewerTimes = [:]
        return .none
    }
}

struct ContentView: View {
    let store: Store<ReviewerState, ReviewerAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                Button(action: {
                    viewStore.send(.getReviewers)
                }) {
                    Text("Get Reviewer Times Button")
                }
                if viewStore.reviewers.isEmpty && viewStore.isLoading {
                    ProgressView()
                    Spacer()
                } else {
                    List {
                        ForEach(viewStore.reviewers, id: \.self) { reviewer in
                            HStack {
                                Text(reviewer.login)
                                Text("\(viewStore.reviewerTimes[reviewer.login]!)")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let store = Store(
            initialState: ReviewerState(),
            reducer: reviewerReducer,
            environment: ReviewerEnvironment(
                githubApiClient: GitHubAPIClient(
                    reviewers: { () -> Effect<[RequestedReviewers], GitHubAPIClient.Failure> in
                        Effect(value: [
                            RequestedReviewers(requestedReviewers: [RequestedReviewers.Reviewer(login: "hoge")]),
                            RequestedReviewers(requestedReviewers: [
                                RequestedReviewers.Reviewer(login: "kalupas"),
                                RequestedReviewers.Reviewer(login: "hoge")
                            ]),
                            RequestedReviewers(requestedReviewers: [
                                RequestedReviewers.Reviewer(login: "maria"),
                                RequestedReviewers.Reviewer(login: "kalupas"),
                                RequestedReviewers.Reviewer(login: "hoge")
                            ]),
                            RequestedReviewers(requestedReviewers: [
                                RequestedReviewers.Reviewer(login: "marianu"),
                                RequestedReviewers.Reviewer(login: "hoge")
                            ])
                        ])
                    }),
                mainQueue: DispatchQueue.main.eraseToAnyScheduler()
            )
        )
        
        return ContentView(store: store)
    }
}
