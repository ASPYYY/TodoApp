import UIKit

// MARK: - DarkNavigationController

final class DarkNavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .lightContent
    }
}

// MARK: - SceneDelegate

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        guard NSClassFromString("XCTestCase") == nil else {
            window?.rootViewController = UIViewController()
            window?.makeKeyAndVisible()
            return
        }
        
        let taskListVC = TaskListRouter.createModule()
        let navController = DarkNavigationController(rootViewController: taskListVC)
        navController.navigationBar.barStyle = .black

        
        window?.rootViewController = navController
        window?.backgroundColor = .black
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {
        CoreDataService.shared.saveContext()
    }
}
