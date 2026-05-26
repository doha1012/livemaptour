import UIKit
import WebKit

class VideoPopupView: UIView, WKNavigationDelegate, WKUIDelegate {
    
    var tourItem: TourItem?
    var blurEffectView: UIVisualEffectView!
    var webView: WKWebView!
    var titleLabel: UILabel!
    var addressLabel: UILabel!
    var titleStackView: UIStackView!
    var favoriteButton: UIButton!
    var closeButton: UIButton!
    
    private var shimmerView: UIView?
    
    init(tourItem: TourItem?) {
        self.tourItem = tourItem
        super.init(frame: .zero)
        setupView()
        
        if tourItem == nil {
            showShimmer()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appDidEnterBackground() {
        dismissCleanly()
    }
    
    private func setupView() {
        self.roundCorners(radius: 20)
        self.addPremiumShadow()
        
        // 1. Glassmorphism Background
        let blur = UIBlurEffect(style: .systemMaterial)
        blurEffectView = UIVisualEffectView(effect: blur)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.roundCorners(radius: 20)
        self.addSubview(blurEffectView)
        
        // 2. WKWebView - load embed iframe
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.roundCorners(radius: 12)
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        blurEffectView.contentView.addSubview(webView)
        
        if let item = tourItem {
            loadEmbedHTML(videoId: item.videoId)
        }
        
        // 3. Title Label
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.text = tourItem?.title ?? " "
        titleLabel.numberOfLines = 2
        
        // 4. Address Label
        addressLabel = UILabel()
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.font = .systemFont(ofSize: 11, weight: .regular)
        addressLabel.textColor = .secondaryLabel
        if let item = tourItem {
            addressLabel.text = "\(item.addressName) (\(String(format: "%.3f", item.latitude)), \(String(format: "%.3f", item.longitude)))"
        } else {
            addressLabel.text = " "
        }
        addressLabel.numberOfLines = 1
        
        titleStackView = UIStackView(arrangedSubviews: [titleLabel, addressLabel])
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        titleStackView.axis = .vertical
        titleStackView.alignment = .leading
        titleStackView.spacing = 4
        blurEffectView.contentView.addSubview(titleStackView)
        
        // 5. Favorite Button
        favoriteButton = UIButton(type: .system)
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        favoriteButton.roundCorners(radius: 10)
        favoriteButton.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)
        blurEffectView.contentView.addSubview(favoriteButton)
        updateFavoriteButtonState()
        
        // 6. Close Button
        closeButton = UIButton(type: .custom)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let closeConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: closeConfig), for: .normal)
        closeButton.tintColor = .systemGray.withAlphaComponent(0.8)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        blurEffectView.contentView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: blurEffectView.contentView.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: blurEffectView.contentView.trailingAnchor, constant: -10),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            webView.topAnchor.constraint(equalTo: blurEffectView.contentView.topAnchor, constant: 16),
            webView.leadingAnchor.constraint(equalTo: blurEffectView.contentView.leadingAnchor, constant: 16),
            webView.trailingAnchor.constraint(equalTo: blurEffectView.contentView.trailingAnchor, constant: -16),
            
            // 🚀 aspect-ratio 16:9 responsive constraint instead of hardcoded 180pt height!
            webView.heightAnchor.constraint(equalTo: webView.widthAnchor, multiplier: 9.0 / 16.0),
            
            titleStackView.topAnchor.constraint(equalTo: webView.bottomAnchor, constant: 10),
            titleStackView.leadingAnchor.constraint(equalTo: blurEffectView.contentView.leadingAnchor, constant: 16),
            titleStackView.trailingAnchor.constraint(equalTo: blurEffectView.contentView.trailingAnchor, constant: -16),
            
            favoriteButton.topAnchor.constraint(equalTo: titleStackView.bottomAnchor, constant: 10),
            favoriteButton.centerXAnchor.constraint(equalTo: blurEffectView.contentView.centerXAnchor),
            favoriteButton.widthAnchor.constraint(equalToConstant: 180),
            favoriteButton.heightAnchor.constraint(equalToConstant: 40),
            favoriteButton.bottomAnchor.constraint(equalTo: blurEffectView.contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func loadEmbedHTML(videoId: String) {
        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
        body, html { margin: 0; padding: 0; width: 100%; height: 100%; background-color: black; overflow: hidden; }
        iframe { width: 100%; height: 100%; border: none; }
        </style>
        </head>
        <body>
        <iframe id="player" src="https://www.youtube.com/embed/\(videoId)?playsinline=1" allow="autoplay; encrypted-media" allowfullscreen></iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(embedHTML, baseURL: URL(string: "https://www.google.com"))
    }
    
    private func showShimmer() {
        let shimmer = UIView()
        shimmer.translatesAutoresizingMaskIntoConstraints = false
        shimmer.backgroundColor = .clear
        blurEffectView.contentView.addSubview(shimmer)
        self.shimmerView = shimmer
        
        NSLayoutConstraint.activate([
            shimmer.topAnchor.constraint(equalTo: blurEffectView.contentView.topAnchor),
            shimmer.leadingAnchor.constraint(equalTo: blurEffectView.contentView.leadingAnchor),
            shimmer.trailingAnchor.constraint(equalTo: blurEffectView.contentView.trailingAnchor),
            shimmer.bottomAnchor.constraint(equalTo: blurEffectView.contentView.bottomAnchor)
        ])
        
        let webViewPlaceholder = UIView()
        webViewPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        webViewPlaceholder.backgroundColor = UIColor.systemGray.withAlphaComponent(0.15)
        webViewPlaceholder.roundCorners(radius: 12)
        shimmer.addSubview(webViewPlaceholder)
        
        let titlePlaceholder = UIView()
        titlePlaceholder.translatesAutoresizingMaskIntoConstraints = false
        titlePlaceholder.backgroundColor = UIColor.systemGray.withAlphaComponent(0.15)
        titlePlaceholder.roundCorners(radius: 4)
        shimmer.addSubview(titlePlaceholder)
        
        let addressPlaceholder = UIView()
        addressPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        addressPlaceholder.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
        addressPlaceholder.roundCorners(radius: 4)
        shimmer.addSubview(addressPlaceholder)
        
        NSLayoutConstraint.activate([
            webViewPlaceholder.topAnchor.constraint(equalTo: shimmer.topAnchor, constant: 16),
            webViewPlaceholder.leadingAnchor.constraint(equalTo: shimmer.leadingAnchor, constant: 16),
            webViewPlaceholder.trailingAnchor.constraint(equalTo: shimmer.trailingAnchor, constant: -16),
            webViewPlaceholder.heightAnchor.constraint(equalTo: webViewPlaceholder.widthAnchor, multiplier: 9.0 / 16.0),
            
            titlePlaceholder.topAnchor.constraint(equalTo: webViewPlaceholder.bottomAnchor, constant: 12),
            titlePlaceholder.leadingAnchor.constraint(equalTo: shimmer.leadingAnchor, constant: 16),
            titlePlaceholder.widthAnchor.constraint(equalToConstant: 200),
            titlePlaceholder.heightAnchor.constraint(equalToConstant: 18),
            
            addressPlaceholder.topAnchor.constraint(equalTo: titlePlaceholder.bottomAnchor, constant: 8),
            addressPlaceholder.leadingAnchor.constraint(equalTo: shimmer.leadingAnchor, constant: 16),
            addressPlaceholder.widthAnchor.constraint(equalToConstant: 120),
            addressPlaceholder.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        shimmer.alpha = 0.4
        UIView.animate(withDuration: 0.8, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            shimmer.alpha = 1.0
        }, completion: nil)
        
        webView.alpha = 0
        titleStackView.alpha = 0
        favoriteButton.alpha = 0
    }
    
    private func hideShimmer() {
        UIView.animate(withDuration: 0.35, animations: { [weak self] in
            self?.shimmerView?.alpha = 0
            self?.webView.alpha = 1
            self?.titleStackView.alpha = 1
            self?.favoriteButton.alpha = 1
        }) { [weak self] _ in
            self?.shimmerView?.removeFromSuperview()
            self?.shimmerView = nil
        }
    }
    
    func configure(with item: TourItem) {
        self.tourItem = item
        
        titleLabel.text = item.title
        addressLabel.text = "\(item.addressName) (\(String(format: "%.3f", item.latitude)), \(String(format: "%.3f", item.longitude)))"
        updateFavoriteButtonState()
        
        loadEmbedHTML(videoId: item.videoId)
        hideShimmer()
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    // MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
    
    private func updateFavoriteButtonState() {
        guard let item = tourItem else {
            favoriteButton.isHidden = true
            return
        }
        favoriteButton.isHidden = false
        let isFav = TourRepository.shared.isFavorite(videoId: item.videoId)
        let starFilled = "★ 즐겨찾기 해제"
        let starEmpty = "☆ 즐겨찾기 등록"
        favoriteButton.setTitle(isFav ? starFilled : starEmpty, for: .normal)
        favoriteButton.backgroundColor = isFav ? .systemRed.withAlphaComponent(0.2) : .systemBlue.withAlphaComponent(0.2)
        favoriteButton.setTitleColor(isFav ? .systemRed : .systemBlue, for: .normal)
    }
    
    @objc func toggleFavorite() {
        guard let item = tourItem else { return }
        let isFav = TourRepository.shared.isFavorite(videoId: item.videoId)
        
        let generator = UINotificationFeedbackGenerator()
        if isFav {
            TourRepository.shared.removeFavorite(byVideoId: item.videoId)
            generator.notificationOccurred(.success)
        } else {
            TourRepository.shared.addFavorite(item)
            generator.notificationOccurred(.success)
        }
        updateFavoriteButtonState()
    }
    
    @objc func closeTapped() {
        dismissCleanly()
    }
    
    func dismissCleanly() {
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
        webView.removeFromSuperview()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.transform = CGAffineTransform(translationX: 0, y: 400)
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
