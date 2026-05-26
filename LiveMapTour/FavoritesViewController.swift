import UIKit
import WebKit

class FavoritesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tableView: UITableView!
    var favorites: [TourItem] = []
    var popupPlayerView: VideoPopupView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "나의 랜선 보관함"
        self.view.backgroundColor = .systemBackground
        
        // 1. Initialize TableView
        tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 96
        tableView.register(FavoriteCell.self, forCellReuseIdentifier: "FavoriteCell")
        self.view.addSubview(tableView)
        
        // 2. Subscribe to synchronization notifications
        NotificationCenter.default.addObserver(self, selector: #selector(loadData), name: .favoritesUpdated, object: nil)
        
        loadData()
    }
    
    @objc func loadData() {
        favorites = TourRepository.shared.getFavorites()
        tableView.reloadData()
        
        // Real-time synchronization badge update
        if favorites.isEmpty {
            self.navigationController?.tabBarItem.badgeValue = nil
        } else {
            self.navigationController?.tabBarItem.badgeValue = "\(favorites.count)"
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        popupPlayerView?.dismissCleanly()
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if favorites.count == 0 {
            let emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            emptyLabel.text = "저장된 랜선 여행지가 없습니다.\n지도에서 핀을 길게 눌러 등록해보세요!"
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.numberOfLines = 0
            emptyLabel.textAlignment = .center
            emptyLabel.font = .systemFont(ofSize: 15, weight: .medium)
            tableView.backgroundView = emptyLabel
            tableView.separatorStyle = .none
            return 0
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            return favorites.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath) as? FavoriteCell else {
            return UITableViewCell()
        }
        
        let item = favorites[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = favorites[indexPath.row]
        presentPopupPlayer(with: item)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = favorites[indexPath.row]
            
            // Check if deleted item is currently playing
            if popupPlayerView?.tourItem?.videoId == item.videoId {
                popupPlayerView?.dismissCleanly()
            }
            
            let generator = UINotificationFeedbackGenerator()
            TourRepository.shared.removeFavorite(byVideoId: item.videoId)
            generator.notificationOccurred(.success)
        }
    }
    
    func presentPopupPlayer(with item: TourItem) {
        popupPlayerView?.dismissCleanly()
        
        let popup = VideoPopupView(tourItem: item)
        self.popupPlayerView = popup
        PopupPresentationManager.shared.present(popup, in: self.view, safeAreaGuide: self.view.safeAreaLayoutGuide)
    }
}

