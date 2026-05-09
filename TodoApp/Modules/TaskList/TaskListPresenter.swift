import Foundation

final class TaskListPresenter {
    weak var view: TaskListViewProtocol?
    var interactor: TaskListInteractorProtocol?
    var router: TaskListRouterProtocol?
}

extension TaskListPresenter: TaskListPresenterProtocol {
    
    func viewDidLoad() {
        interactor?.loadInitialDataIfNeeded()
    }
    
    func didTapAddTask() {
        guard let view = view else { return }
        router?.navigateToAddTask(from: view)
    }
    
    func didTapTask(_ task: TaskEntity) {
        guard let view = view else { return }
        router?.navigateToEditTask(task, from: view)
    }
    
    func didToggleComplete(_ task: TaskEntity) {
        interactor?.toggleComplete(task)
    }
    
    func didDeleteTask(_ task: TaskEntity) {
        interactor?.deleteTask(task)
    }
    
    func didSearchTasks(query: String) {
        interactor?.fetchTasks(query: query)
    }
}

extension TaskListPresenter: TaskListInteractorOutputProtocol {
    
    func didFetchTasks(_ tasks: [TaskEntity]) {
        view?.showTasks(tasks)
        view?.reloadTable()
    }
    
    func didDeleteTask(at index: Int, tasks: [TaskEntity]) {
        // Сначала обновляем массив, потом анимируем удаление
        view?.showTasks(tasks)
        view?.deleteTask(at: index)
    }
    
    func didFailWithError(_ error: String) {
        view?.showError(error)
    }
}
