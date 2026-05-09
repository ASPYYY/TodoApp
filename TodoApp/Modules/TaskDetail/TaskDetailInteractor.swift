import Foundation

final class TaskDetailInteractor {
    weak var presenter: TaskDetailInteractorOutputProtocol?
    var task: TaskEntity?
    
    private let coreData: CoreDataService
    
    init(service: CoreDataService = .shared) {
        self.coreData = service
    }
}

extension TaskDetailInteractor: TaskDetailInteractorProtocol {
    
    func saveTask(title: String, description: String) {
        coreData.createTaskAsync(title: title, description: description) { [weak self] _ in
            NotificationCenter.default.post(name: .taskSaved, object: nil)
            self?.presenter?.didSaveTask()
        }
    }
    
    func updateTask(title: String, description: String) {
        guard let task else { return }
        
        coreData.updateTaskAsync(task, title: title, description: description) { [weak self] _ in
            NotificationCenter.default.post(name: .taskSaved, object: nil)
            self?.presenter?.didSaveTask()
        }
    }
}

extension Notification.Name {
    static let taskSaved = Notification.Name("taskSaved")
}
