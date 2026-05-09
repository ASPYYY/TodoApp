import UIKit

@MainActor
protocol TaskDetailViewProtocol: AnyObject {
    func setTask(_ task: TaskEntity?)
    func dismiss()
    func showError(_ message: String)
}

protocol TaskDetailPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didTapSave(title: String, description: String)
}

protocol TaskDetailInteractorProtocol: AnyObject {
    func saveTask(title: String, description: String)
    func updateTask(title: String, description: String)
}

protocol TaskDetailInteractorOutputProtocol: AnyObject {
    func didSaveTask()
    func didFailWithError(_ error: String)
}

protocol TaskDetailRouterProtocol: AnyObject {
    func dismiss()
    static func createModule(task: TaskEntity?) -> UIViewController
}
