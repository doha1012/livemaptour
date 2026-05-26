import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        
        let mapVC = MapViewController()
        let favoritesVC = FavoritesViewController()
        
        let mapNav = UINavigationController(rootViewController: mapVC)
        let favoritesNav = UINavigationController(rootViewController: favoritesVC)
        
        mapNav.tabBarItem = UITabBarItem(title: "지도", image: UIImage(systemName: "map"), selectedImage: UIImage(systemName: "map.fill"))
        favoritesNav.tabBarItem = UITabBarItem(title: "즐겨찾기", image: UIImage(systemName: "star"), selectedImage: UIImage(systemName: "star.fill"))
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [mapNav, favoritesNav]
        tabBarController.tabBar.tintColor = .systemBlue
        tabBarController.tabBar.backgroundColor = .systemBackground
        
        window.rootViewController = tabBarController
        self.window = window
        window.makeKeyAndVisible()
    }
}
