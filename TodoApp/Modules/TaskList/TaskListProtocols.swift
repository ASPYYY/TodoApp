import UIKit

@MainActor
// View → Presenter
protocol TaskListViewProtocol: AnyObject {
    func showTasks(_ tasks: [TaskEntity])
    func reloadTable()
    func deleteTask(at index: Int)
    func showError(_ message: String)
}

// Presenter → View
protocol TaskListPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didTapAddTask()
    func didTapTask(_ task: TaskEntity)
    func didToggleComplete(_ task: TaskEntity)
    func didDeleteTask(_ task: TaskEntity)
    func didSearchTasks(query: String)
}

// Presenter → Interactor
protocol TaskListInteractorProtocol: AnyObject {
    func fetchTasks(query: String)
    func loadInitialDataIfNeeded()
    func toggleComplete(_ task: TaskEntity)
    func deleteTask(_ task: TaskEntity)
}

// Interactor → Presenter
protocol TaskListInteractorOutputProtocol: AnyObject {
    func didFetchTasks(_ tasks: [TaskEntity])
    func didDeleteTask(at index: Int, tasks: [TaskEntity])
    func didFailWithError(_ error: String)
}

// Presenter → Router
protocol TaskListRouterProtocol: AnyObject {
    func navigateToAddTask(from view: TaskListViewProtocol)
    func navigateToEditTask(_ task: TaskEntity, from view: TaskListViewProtocol)
}
