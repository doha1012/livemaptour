import UIKit

class FavoriteCell: UITableViewCell {
    
    var containerView: UIView!
    var thumbnailImageView: UIImageView!
    var playOverlayView: UIImageView!
    var titleLabel: UILabel!
    var addressLabel: UILabel!
    var coordinateLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        self.selectionStyle = .default
        
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(containerView)
        
        thumbnailImageView = UIImageView()
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .center
        thumbnailImageView.backgroundColor = .systemGray6
        thumbnailImageView.tintColor = .systemBlue
        thumbnailImageView.roundCorners(radius: 12)
        containerView.addSubview(thumbnailImageView)
        
        playOverlayView = UIImageView()
        playOverlayView.translatesAutoresizingMaskIntoConstraints = false
        playOverlayView.image = UIImage(systemName: "play.circle.fill")
        playOverlayView.tintColor = .white.withAlphaComponent(0.85)
        containerView.addSubview(playOverlayView)
        
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
        titleLabel.numberOfLines = 1
        containerView.addSubview(titleLabel)
        
        addressLabel = UILabel()
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.font = .systemFont(ofSize: 12, weight: .medium)
        addressLabel.textColor = .secondaryLabel
        containerView.addSubview(addressLabel)
        
        coordinateLabel = UILabel()
        coordinateLabel.translatesAutoresizingMaskIntoConstraints = false
        coordinateLabel.font = .systemFont(ofSize: 10, weight: .regular)
        coordinateLabel.textColor = .tertiaryLabel
        containerView.addSubview(coordinateLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            
            thumbnailImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            thumbnailImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 90),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 72),
            
            playOverlayView.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor),
            playOverlayView.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor),
            playOverlayView.widthAnchor.constraint(equalToConstant: 24),
            playOverlayView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            addressLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            addressLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            coordinateLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 4),
            coordinateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            coordinateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }
    
    func configure(with item: TourItem) {
        titleLabel.text = item.title
        addressLabel.text = item.country
        coordinateLabel.text = "Lat: \(String(format: "%.4f", item.latitude)), Lon: \(String(format: "%.4f", item.longitude))"
        
        let symConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .regular)
        let symImage = UIImage(systemName: item.thumbnailName, withConfiguration: symConfig)
        thumbnailImageView.image = symImage ?? UIImage(systemName: "map", withConfiguration: symConfig)
    }
}
