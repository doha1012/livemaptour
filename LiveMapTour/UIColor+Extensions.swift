import UIKit

extension UIColor {
    static var premiumBackground: UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? 
                UIColor(white: 0.12, alpha: 0.90) : 
                UIColor(white: 0.98, alpha: 0.90)
        }
    }
}
