import Foundation

final class TaskDetailPresenter {
    weak var view: TaskDetailViewProtocol?
    var interactor: TaskDetailInteractorProtocol?
    var router: TaskDetailRouterProtocol?
    var task: TaskEntity?
}

extension TaskDetailPresenter: TaskDetailPresenterProtocol {
    
    func viewDidLoad() {
        view?.setTask(task)
    }
    
    func didTapSave(title: String, description: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            view?.showError("Введите название задачи")
            return
        }
        if task != nil {
            interactor?.updateTask(title: title, description: description)
        } else {
            interactor?.saveTask(title: title, description: description)
        }
    }
}

extension TaskDetailPresenter: TaskDetailInteractorOutputProtocol {
    
    func didSaveTask() {
        router?.dismiss()
    }
    
    func didFailWithError(_ error: String) {
        view?.showError(error)
    }
}
