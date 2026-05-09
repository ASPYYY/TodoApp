import Foundation
import CoreData

final class TaskListInteractor {
    weak var output: TaskListInteractorOutputProtocol?
    private var tasks: [TaskEntity] = []
    private let service: CoreDataService
    
    init(service: CoreDataService = .shared) {
        self.service = service
    }
}

extension TaskListInteractor: TaskListInteractorProtocol {
    
    func loadInitialDataIfNeeded() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            
            self.service.fetchTasksAsync(searchQuery: "") { [weak self] tasks in
                guard let self else { return }
                
                if tasks.isEmpty {
                    NetworkService.shared.fetchTodos { [weak self] todos in
                        guard let self else { return }
                        
                        guard !todos.isEmpty else {
                            self.fetchTasks(query: "")
                            return
                        }
                        
                        let group = DispatchGroup()
                        todos.forEach { todo in
                            group.enter()
                            self.service.createTaskAsync(
                                title: todo.todo,
                                description: "",
                                isCompleted: todo.completed
                            ) { _ in
                                group.leave()
                            }
                        }
                        
                        group.notify(queue: .main) { [weak self] in
                            self?.fetchTasks(query: "")
                        }
                    }
                } else {
                    self.tasks = tasks
                    self.output?.didFetchTasks(tasks)
                }
            }
        }
    }
    
    func fetchTasks(query: String) {
        service.fetchTasksAsync(searchQuery: query) { [weak self] tasks in
            self?.tasks = tasks
            self?.output?.didFetchTasks(tasks)
        }
    }

    func toggleComplete(_ task: TaskEntity) {
        service.toggleCompleteAsync(task) { [weak self] _ in
            self?.fetchTasks(query: "")
        }
    }

    func deleteTask(_ task: TaskEntity) {
        if let index = tasks.firstIndex(of: task) {
            service.deleteTaskAsync(task) { [weak self] deleted in
                guard let self, deleted else { return }
                self.tasks.remove(at: index)
                self.output?.didDeleteTask(at: index, tasks: self.tasks)
            }
        }
    }
}
