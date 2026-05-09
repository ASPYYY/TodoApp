import UIKit

final class TaskDetailRouter {
    weak var viewController: UIViewController?
    
    static func createModule(task: TaskEntity?) -> UIViewController {
        let view = TaskDetailViewController()
        let presenter = TaskDetailPresenter()
        let interactor = TaskDetailInteractor()
        let router = TaskDetailRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        presenter.task = task
        interactor.presenter = presenter
        interactor.task = task
        router.viewController = view
        
        return view
    }
}

extension TaskDetailRouter: TaskDetailRouterProtocol {
    func dismiss() {
        viewController?.dismiss(animated: true) {
        }
    }
}
