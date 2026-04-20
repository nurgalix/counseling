import SwiftUI
import Combine

@MainActor
final class ResourcesViewModel: ObservableObject {

    // MARK: - Published State
    @Published var selectedCategory: ResourceCategory = .peace
    @Published private(set) var favoriteIDs: Set<UUID> = []

    // MARK: - Derived
    var filteredItems: [ResourceItem] {
        ResourceItem.allItems.filter { $0.category == selectedCategory }
    }

    var featuredItem: ResourceItem? {
        filteredItems.first
    }

    var gridItems: [ResourceItem] {
        Array(filteredItems.dropFirst())
    }

    // MARK: - Persistence Key
    private let favoritesKey = "resources_favorite_ids"

    // MARK: - Init
    init() {
        loadFavorites()
    }

    // MARK: - Favorites
    func isFavorited(_ item: ResourceItem) -> Bool {
        favoriteIDs.contains(item.id)
    }

    func toggleFavorite(_ item: ResourceItem) {
        if favoriteIDs.contains(item.id) {
            favoriteIDs.remove(item.id)
        } else {
            favoriteIDs.insert(item.id)
        }
        saveFavorites()
    }

    // MARK: - Category
    func select(category: ResourceCategory) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedCategory = category
        }
    }

    // MARK: - Private Persistence
    private func saveFavorites() {
        let strings = favoriteIDs.map { $0.uuidString }
        UserDefaults.standard.set(strings, forKey: favoritesKey)
    }

    private func loadFavorites() {
        guard let strings = UserDefaults.standard.stringArray(forKey: favoritesKey) else { return }
        favoriteIDs = Set(strings.compactMap { UUID(uuidString: $0) })
    }
}
