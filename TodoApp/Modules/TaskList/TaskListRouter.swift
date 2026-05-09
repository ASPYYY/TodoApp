import UIKit

final class TaskListRouter {
    weak var viewController: UIViewController?
    
    static func createModule() -> UIViewController {
        let view = TaskListViewController()
        let presenter = TaskListPresenter()
        let interactor = TaskListInteractor()
        let router = TaskListRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.output = presenter
        router.viewController = view
        
        return view
    }
}

extension TaskListRouter: TaskListRouterProtocol {
    
    func navigateToAddTask(from view: TaskListViewProtocol) {
        let detailVC = TaskDetailRouter.createModule(task: nil)
        detailVC.modalPresentationStyle = .pageSheet
        if let sheet = detailVC.sheetPresentationController {
            sheet.detents = [.large()]
        }
        viewController?.present(detailVC, animated: true)
    }
    
    func navigateToEditTask(_ task: TaskEntity, from view: TaskListViewProtocol) {
        let detailVC = TaskDetailRouter.createModule(task: task)
        detailVC.modalPresentationStyle = .pageSheet
        if let sheet = detailVC.sheetPresentationController {
            sheet.detents = [.large()]
        }
        viewController?.present(detailVC, animated: true)
    }
}
