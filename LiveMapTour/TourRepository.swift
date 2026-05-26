import Foundation
import CoreLocation

class TourRepository {
    static let shared = TourRepository()
    
    private let favoritesKey = "LiveMapTourFavorites"
    
    private let serialQueue = DispatchQueue(label: "doha.LiveMapTour.repository.queue")
    
    private var favoritesCache: [TourItem] = []
    private var favoriteVideoIds: Set<String> = []
    private var isCacheLoaded = false
    
    private init() {}
    
    private func ensureCacheLoaded() {
        guard !isCacheLoaded else { return }
        let favorites = getFavoritesInternal()
        favoritesCache = favorites
        favoriteVideoIds = Set(favorites.map { $0.videoId })
        isCacheLoaded = true
    }
    
    private func getFavoritesInternal() -> [TourItem] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey) else { return [] }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([TourItem].self, from: data)
        } catch {
            print("Failed to decode favorites:", error)
            return []
        }
    }
    
    private func saveInternal(_ favorites: [TourItem]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(favorites)
            UserDefaults.standard.set(data, forKey: favoritesKey)
        } catch {
            print("Failed to encode favorites:", error)
        }
    }
    
    func getFavorites() -> [TourItem] {
        return serialQueue.sync {
            ensureCacheLoaded()
            return favoritesCache
        }
    }
    
    func addFavorite(_ item: TourItem) {
        serialQueue.sync {
            ensureCacheLoaded()
            if !favoriteVideoIds.contains(item.videoId) {
                favoritesCache.append(item)
                favoriteVideoIds.insert(item.videoId)
                
                // Asynchronously save to background thread to avoid blocking UI main thread
                let snapshot = favoritesCache
                DispatchQueue.global(qos: .background).async {
                    self.saveInternal(snapshot)
                }
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .favoritesUpdated, object: nil)
                }
            }
        }
    }
    
    func removeFavorite(byVideoId videoId: String) {
        serialQueue.sync {
            ensureCacheLoaded()
            if let index = favoritesCache.firstIndex(where: { $0.videoId == videoId }) {
                favoritesCache.remove(at: index)
                favoriteVideoIds.remove(videoId)
                
                // Asynchronously save to background thread to avoid blocking UI main thread
                let snapshot = favoritesCache
                DispatchQueue.global(qos: .background).async {
                    self.saveInternal(snapshot)
                }
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .favoritesUpdated, object: nil)
                }
            }
        }
    }
    
    func isFavorite(videoId: String) -> Bool {
        return serialQueue.sync {
            ensureCacheLoaded()
            return favoriteVideoIds.contains(videoId)
        }
    }
    
    // MARK: - Dynamic YouTube Search + oEmbed Title Engine
    
    func findDynamicTour(forAddress address: String, query: String, coordinate: CLLocationCoordinate2D, completion: @escaping (TourItem?) -> Void) {
        let searchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.youtube.com/results?search_query=\(searchQuery)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7", forHTTPHeaderField: "Accept-Language")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data, error == nil,
                  let html = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            
            // Extract videoId from YouTube search results
            var foundVideoId: String? = nil
            
            // Pattern 1: Escaped videoId format: \x22videoId\x22:\x22XXXXXXXXXXX\x22
            let pattern1 = #"\\x22videoId\\x22:\\x22([a-zA-Z0-9_-]{11})\\x22"#
            if let regex = try? NSRegularExpression(pattern: pattern1, options: []),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)) {
                if let range = Range(match.range(at: 1), in: html) {
                    foundVideoId = String(html[range])
                }
            }
            
            // Pattern 2: Escaped watch format: \/watch?v\x3dXXXXXXXXXXX
            if foundVideoId == nil {
                let pattern2 = #"\\/watch\?v\\x3d([a-zA-Z0-9_-]{11})"#
                if let regex = try? NSRegularExpression(pattern: pattern2, options: []),
                   let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)) {
                    if let range = Range(match.range(at: 1), in: html) {
                        foundVideoId = String(html[range])
                    }
                }
            }
            
            // Pattern 3: Standard "videoId":"XXXXXXXXXXX"
            if foundVideoId == nil {
                let pattern3 = #""videoId"\:"([a-zA-Z0-9_-]{11})""#
                if let regex = try? NSRegularExpression(pattern: pattern3, options: []),
                   let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)) {
                    if let range = Range(match.range(at: 1), in: html) {
                        foundVideoId = String(html[range])
                    }
                }
            }
            
            // Pattern 4: Standard /watch?v=XXXXXXXXXXX
            if foundVideoId == nil {
                let pattern4 = #"\/watch\?v\=([a-zA-Z0-9_-]{11})"#
                if let regex = try? NSRegularExpression(pattern: pattern4, options: []),
                   let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)) {
                    if let range = Range(match.range(at: 1), in: html) {
                        foundVideoId = String(html[range])
                    }
                }
            }
            
            guard let videoId = foundVideoId else {
                completion(nil)
                return
            }
            
            // Use YouTube oEmbed API to get REAL video title
            self.fetchRealTitle(videoId: videoId) { realTitle in
                let title = realTitle ?? "\(address) Walking Tour"
                let symbol = self.getSymbolForAddress(address)
                let country = address.components(separatedBy: " ").first ?? ""
                
                let tour = TourItem(
                    id: UUID(),
                    title: title,
                    country: country,
                    addressName: address,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    videoId: videoId,
                    thumbnailName: symbol
                )
                completion(tour)
            }
        }
        task.resume()
    }
    
    /// YouTube oEmbed API - returns the REAL video title directly from YouTube
    private func fetchRealTitle(videoId: String, completion: @escaping (String?) -> Void) {
        let oembedURL = "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=\(videoId)&format=json"
        guard let url = URL(string: oembedURL) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 4.0
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let title = json["title"] as? String {
                    completion(title)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
    
    private func getSymbolForAddress(_ address: String) -> String {
        let lower = address.lowercased()
        if lower.contains("영국") || lower.contains("london") || lower.contains("런던") { return "crown" }
        if lower.contains("프랑스") || lower.contains("paris") || lower.contains("파리") { return "building.columns" }
        if lower.contains("대한민국") || lower.contains("korea") || lower.contains("서울") { return "mappin.and.ellipse" }
        if lower.contains("일본") || lower.contains("japan") || lower.contains("교토") { return "sun.max" }
        if lower.contains("미국") || lower.contains("new york") || lower.contains("뉴욕") { return "flag" }
        if lower.contains("이탈리아") || lower.contains("rome") || lower.contains("로마") { return "building.columns.fill" }
        return "map"
    }
}

extension Notification.Name {
    static let favoritesUpdated = Notification.Name("LiveMapTourFavoritesUpdated")
}
