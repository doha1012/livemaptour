import UIKit

class PopupPresentationManager {
    static let shared = PopupPresentationManager()
    
    private init() {}
    
    func present(_ popup: VideoPopupView, in parentView: UIView, safeAreaGuide: UILayoutGuide) {
        popup.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(popup)
        
        // 🚀 iPad responsive scaling limits max width to 500pt and centers horizontally on large screens
        NSLayoutConstraint.activate([
            popup.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            popup.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -16),
            
            // On iPhones, it takes full width with 16pt margins. On iPads, it centers with a maximum width of 500pt.
            popup.leadingAnchor.constraint(greaterThanOrEqualTo: parentView.leadingAnchor, constant: 16),
            popup.trailingAnchor.constraint(lessThanOrEqualTo: parentView.trailingAnchor, constant: -16),
            popup.widthAnchor.constraint(lessThanOrEqualToConstant: 500)
        ])
        
        // Width constraint is equal to parent width minus margins unless it exceeds the 500 max limit
        let widthConstraint = popup.widthAnchor.constraint(equalTo: parentView.widthAnchor, constant: -32)
        widthConstraint.priority = .defaultHigh // allow max width constraint to override this
        widthConstraint.isActive = true
        
        // Slide up entry animation
        popup.transform = CGAffineTransform(translationX: 0, y: 400)
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
            popup.transform = .identity
        }, completion: nil)
    }
}
