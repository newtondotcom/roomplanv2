//
//  RootTabView.swift
//  PlanSpace
//
//  Created by Robin Augereau on 17/09/2025.
//

import SwiftUI

struct RootTabView: View {
    @State private var sidebarSelection: SidebarItem? = .projects
    @State private var searchText: String = ""
    @State private var showsSearch: Bool = false
    @FocusState private var searchFocused: Bool

    @State private var newlyCreatedProjectId: UUID? = nil

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
        exploreContainer
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
                ExploreProjectsView(newlyCreatedProjectId: $newlyCreatedProjectId)
            case .favorites:
                ExploreProjectsView(newlyCreatedProjectId: $newlyCreatedProjectId)
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
                                        toggleSearch()
                                    } label: {
                                        Image(systemName: "magnifyingglass")
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
                                        toggleSearch()
                                    } label: {
                                        Image(systemName: "magnifyingglass")
                                    }
                                }
                            }
                    }
                } detail: {
                    NavigationStack {
                        exploreDetail
                            .navigationTitle(sidebarSelection == .favorites ? "Favoris" : "Explorer les projets")
                            .toolbarBackground(Color("BackgroundColor"), for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                            .modifier(SearchPresentationModifier(searchText: $searchText, showsSearch: $showsSearch, searchFocused: _searchFocused))
                    }
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                NavigationStack {
                    ExploreProjectsView(newlyCreatedProjectId: $newlyCreatedProjectId)
                        .navigationTitle("Explorer les projets")
                        .toolbarBackground(Color("BackgroundColor"), for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                Button {
                                    toggleSearch()
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                }
                            }
                        }
                        .modifier(SearchPresentationModifier(searchText: $searchText, showsSearch: $showsSearch, searchFocused: _searchFocused))
                }
            }
        }
    }


    // MARK: - Helpers

    private var isSplitSupported: Bool {
        #if os(macOS)
        false
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }

    private var filteredProjects: [Project] {
        let all = ProjectController.shared.projects
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        return all.filter { project in
            project.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func toggleSearch() {
        withAnimation(.snappy) {
            showsSearch.toggle()
        }
        if showsSearch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                searchFocused = true
            }
        }
    }
}

// MARK: - Search presentation helper

private struct SearchPresentationModifier: ViewModifier {
    @Binding var searchText: String
    @Binding var showsSearch: Bool
    @FocusState var searchFocused: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            Group {
                if showsSearch {
                    content
                        .searchable(text: $searchText,
                                    isPresented: $showsSearch,
                                    placement: .navigationBarDrawer(displayMode: .automatic),
                                    prompt: "Rechercher")
                        .autocorrectionDisabled()
                        .toolbarBackground(Color("BackgroundColor"), for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                        .onChange(of: showsSearch) { _, newValue in
                            if newValue {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    searchFocused = true
                                }
                            }
                        }
                        .focused($searchFocused)
                } else {
                    content
                }
            }
        } else {
            Group {
                if showsSearch {
                    content
                        .searchable(text: $searchText,
                                    placement: .navigationBarDrawer(displayMode: .automatic),
                                    prompt: "Rechercher")
                        .autocorrectionDisabled()
                        .toolbarBackground(Color("BackgroundColor"), for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                        .onChange(of: showsSearch, perform: { newValue in
                            if newValue {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    searchFocused = true
                                }
                            }
                        })
                        .focused($searchFocused)
                } else {
                    content
                }
            }
        }
    }
}
