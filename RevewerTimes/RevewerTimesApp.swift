//
//  RevewerTimesApp.swift
//  RevewerTimes
//
//  Created by Aikawa Kenta on 2020/09/26.
//

import ComposableArchitecture
import SwiftUI

@main
struct RevewerTimesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(
                    initialState: ReviewerState(),
                    reducer: reviewerReducer.debug(),
                    environment: ReviewerEnvironment(
                        githubApiClient: GitHubAPIClient.live,
                        mainQueue: DispatchQueue.main.eraseToAnyScheduler()
                    )
                )
            )
        }
    }
}
