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
    @State private var searchText: String = ""
    @State private var showsSearch: Bool = false
    @FocusState private var searchFocused: Bool

    enum Tab: Hashable {
        case explore
        case new
        case settings
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

            settingsContainer
                .tabItem {
                    Label("Réglages", systemImage: "gearshape")
                }
                .tag(Tab.settings)
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
                // For now, same view; you can change filtering logic to favorites later.
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
                                        // Trigger search presentation
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
                                        // Trigger search presentation
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
                    ExploreProjectsView()
                        .navigationTitle("Explorer les projets")
                        .toolbarBackground(Color("BackgroundColor"), for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                Button {
                                    // Trigger search presentation
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

    // MARK: - New Project (NavigationStack everywhere on iOS; macOS handled above)

    #if !os(macOS)
    private var newContainer: some View {
        NavigationStack {
            NewProjectView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("BackgroundColor").ignoresSafeArea())
                .navigationTitle("Nouveau projet")
                .toolbarBackground(Color("BackgroundColor"), for: .navigationBar)
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

    // MARK: - Settings Tab
    private var settingsContainer: some View {
        NavigationStack {
            SettingsView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Réglages")
                .toolbarBackground(Color("BackgroundColor"), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Helpers

    private var isSplitSupported: Bool {
        #if os(macOS)
        false
        #else
        // iPad split view; iPhone fallback
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }

    // Filter logic for projects by name; you can expand to include rooms, dates, etc.
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
        // Focus the search field when presented
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
            // iOS 16 fallback: only apply when visible
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
