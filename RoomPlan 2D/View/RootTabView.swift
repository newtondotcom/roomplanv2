//
//  RootTabView.swift
//  RoomPlan 2D
//
//  Created by Robin Augereau on 17/09/2025.
//

import SwiftUI

struct RootTabView: View {
    @State private var selection: Tab = .explore
    @State private var sidebarSelection: SidebarItem? = .projects

    enum Tab: Hashable {
        case explore
        case new
    }

    enum SidebarItem: Hashable, Identifiable, CaseIterable {
        case projects
        case favorites

        var id: Self { self }

        var title: String {
            switch self {
            case .projects: return "Projets"
            case .favorites: return "Favoris"
            }
        }

        var systemImage: String {
            switch self {
            case .projects: return "folder"
            case .favorites: return "star"
            }
        }
    }

    var body: some View {
        // iOS / iPadOS: TabView avec barres translucides
        TabView(selection: $selection) {
            exploreContainer
                .tabItem {
                    Label("Explorer", systemImage: "folder")
                }
                .tag(Tab.explore)

            newContainer
                .tabItem {
                    Label("Nouveau", systemImage: "plus.circle")
                }
                .tag(Tab.new)
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

    // MARK: - Sidebar (iPadOS)

    private var sidebar: some View {
        List(SidebarItem.allCases, selection: $sidebarSelection) { item in
            Label(item.title, systemImage: item.systemImage)
                .tag(item as SidebarItem?)
        }
    }

    // MARK: - Explorer detail (shared)

    private var exploreDetail: some View {
        Group {
            switch sidebarSelection {
            case .projects, .none:
                ExploreProjectsView()
            case .favorites:
                ExploreProjectsView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    // Placeholder: tri
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
            }
        }
    }

    // MARK: - Explorer (iOS adaptive: Split on iPad, Stack on iPhone)

    @ViewBuilder
    private var exploreContainer: some View {
        Group {
            if isSplitSupported {
                NavigationSplitView {
                    if #available(iOS 17.0, *) {
                        sidebar
                            .navigationTitle("Explorer")
                            .toolbarTitleDisplayMode(.automatic)
                            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                            .toolbar {
                                ToolbarItemGroup(placement: .primaryAction) {
                                    Button {
                                        // Placeholder: filtrer
                                    } label: {
                                        Image(systemName: "line.3.horizontal.decrease.circle")
                                    }
                                    Button {
                                        // Placeholder: rechercher
                                    } label: {
                                        Image(systemName: "magnifyingglass")
                                    }
                                    Button {
                                        // Placeholder: ajouter un projet
                                    } label: {
                                        Image(systemName: "plus.circle")
                                    }
                                }
                            }
                    } else {
                        sidebar
                            .navigationTitle("Explorer")
                            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                            .toolbar {
                                ToolbarItemGroup(placement: .primaryAction) {
                                    Button {
                                        // Placeholder: filtrer
                                    } label: {
                                        Image(systemName: "line.3.horizontal.decrease.circle")
                                    }
                                    Button {
                                        // Placeholder: rechercher
                                    } label: {
                                        Image(systemName: "magnifyingglass")
                                    }
                                    Button {
                                        // Placeholder: ajouter un projet
                                    } label: {
                                        Image(systemName: "plus.circle")
                                    }
                                }
                            }
                    }
                } detail: {
                    NavigationStack {
                        exploreDetail
                            .navigationTitle(sidebarSelection == .favorites ? "Favoris" : "Explorer les projets")
                            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                    }
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                NavigationStack {
                    ExploreProjectsView()
                        .navigationTitle("Explorer les projets")
                        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                Button {
                                    // Placeholder: filtrer
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                }
                                Button {
                                    // Placeholder: rechercher
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                }
                                Button {
                                    // Placeholder: ajouter un projet
                                } label: {
                                    Image(systemName: "plus.circle")
                                }
                            }
                        }
                }
            }
        }
    }

    // MARK: - New Project (NavigationStack everywhere on iOS; macOS handled above)

    #if !os(macOS)
    private var newContainer: some View {
        NavigationStack {
            WelcomeView()
                .navigationTitle("Nouveau projet")
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            // Placeholder: aide
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                    }
                }
        }
    }
    #endif

    // MARK: - Helpers

    private var isSplitSupported: Bool {
        #if os(macOS)
        false
        #else
        // iPad split view; iPhone fallback
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }
}
