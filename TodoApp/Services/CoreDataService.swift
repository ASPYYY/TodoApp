import CoreData
import Foundation

final class CoreDataService {
    
    static let shared = CoreDataService()
    
    private static let managedObjectModel: NSManagedObjectModel = {
        let bundles: [Bundle] = [
            Bundle(for: CoreDataService.self),
            Bundle.main,
            Bundle(identifier: "com.tematretyakov.TodoApp"),
        ].compactMap { $0 }
        
        for bundle in bundles {
            if let url = bundle.url(forResource: "TodoApp", withExtension: "momd"),
               let model = NSManagedObjectModel(contentsOf: url) {
                return model
            }
        }
        fatalError("CoreData: модель TodoApp.momd не найдена")
    }()
    
    private let persistentContainer: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext
    
    init(inMemory: Bool = false) {
        persistentContainer = NSPersistentContainer(
            name: "TodoApp",
            managedObjectModel: CoreDataService.managedObjectModel
        )
        
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        }
        
        persistentContainer.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData error: \(error)")
            }
        }
        
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - CRUD
    
    @discardableResult
    func createTask(title: String, description: String) -> TaskEntity {
        let task = TaskEntity(context: context)
        task.id = UUID()
        task.title = title
        task.desc = description
        task.createdAt = Date()
        task.isCompleted = false
        saveContext()
        return task
    }
    
    func fetchTasks(searchQuery: String = "") -> [TaskEntity] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        if !searchQuery.isEmpty {
            request.predicate = NSPredicate(
                format: "%K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@",
                #keyPath(TaskEntity.title), searchQuery,
                #keyPath(TaskEntity.desc), searchQuery
            )
        }
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    func updateTask(_ task: TaskEntity, title: String, description: String) {
        task.title = title
        task.desc = description
        saveContext()
    }
    
    func toggleComplete(_ task: TaskEntity) {
        task.isCompleted = !task.isCompleted
        saveContext()
    }
    
    func deleteTask(_ task: TaskEntity) {
        context.delete(task)
        saveContext()
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return }
        
        if Thread.isMainThread {
            try? context.save()
        } else {
            DispatchQueue.main.sync {
                try? context.save()
            }
        }
    }
    
    func tasksCount() -> Int {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }
}

// MARK: - Async CRUD

extension CoreDataService {
    
    func fetchTasksAsync(searchQuery: String = "", completion: @escaping ([TaskEntity]) -> Void) {
        backgroundContext.perform {
            let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            if !searchQuery.isEmpty {
                request.predicate = NSPredicate(
                    format: "%K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@",
                    #keyPath(TaskEntity.title), searchQuery,
                    #keyPath(TaskEntity.desc), searchQuery
                )
            }
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let objectIDs = ((try? self.backgroundContext.fetch(request)) ?? []).map(\.objectID)
            self.completeWithTasks(objectIDs: objectIDs, completion: completion)
        }
    }
    
    func createTaskAsync(
        title: String,
        description: String,
        isCompleted: Bool = false,
        completion: ((TaskEntity?) -> Void)? = nil
    ) {
        backgroundContext.perform {
            let task = TaskEntity(context: self.backgroundContext)
            task.id = UUID()
            task.title = title
            task.desc = description
            task.createdAt = Date()
            task.isCompleted = isCompleted
            
            try? self.backgroundContext.obtainPermanentIDs(for: [task])
            try? self.backgroundContext.save()
            self.completeWithTask(objectID: task.objectID, completion: completion)
        }
    }
    
    func updateTaskAsync(
        _ task: TaskEntity,
        title: String,
        description: String,
        completion: ((TaskEntity?) -> Void)? = nil
    ) {
        let objectID = task.objectID
        backgroundContext.perform {
            guard let backgroundTask = try? self.backgroundContext.existingObject(with: objectID) as? TaskEntity else {
                self.completeWithTask(objectID: nil, completion: completion)
                return
            }
            
            backgroundTask.title = title
            backgroundTask.desc = description
            try? self.backgroundContext.save()
            self.completeWithTask(objectID: objectID, completion: completion)
        }
    }
    
    func deleteTaskAsync(_ task: TaskEntity, completion: ((Bool) -> Void)? = nil) {
        let objectID = task.objectID
        backgroundContext.perform {
            guard let backgroundTask = try? self.backgroundContext.existingObject(with: objectID) as? TaskEntity else {
                DispatchQueue.main.async {
                    completion?(false)
                }
                return
            }
            
            self.backgroundContext.delete(backgroundTask)
            try? self.backgroundContext.save()
            
            DispatchQueue.main.async {
                completion?(true)
            }
        }
    }
    
    func toggleCompleteAsync(_ task: TaskEntity, completion: ((TaskEntity?) -> Void)? = nil) {
        let objectID = task.objectID
        backgroundContext.perform {
            guard let backgroundTask = try? self.backgroundContext.existingObject(with: objectID) as? TaskEntity else {
                self.completeWithTask(objectID: nil, completion: completion)
                return
            }
            
            backgroundTask.isCompleted.toggle()
            try? self.backgroundContext.save()
            self.completeWithTask(objectID: objectID, completion: completion)
        }
    }
    
    private func completeWithTask(
        objectID: NSManagedObjectID?,
        completion: ((TaskEntity?) -> Void)?
    ) {
        DispatchQueue.main.async {
            guard let objectID,
                  let task = try? self.context.existingObject(with: objectID) as? TaskEntity else {
                completion?(nil)
                return
            }
            completion?(task)
        }
    }
    
    private func completeWithTasks(
        objectIDs: [NSManagedObjectID],
        completion: @escaping ([TaskEntity]) -> Void
    ) {
        DispatchQueue.main.async {
            let tasks = objectIDs.compactMap {
                try? self.context.existingObject(with: $0) as? TaskEntity
            }
            completion(tasks)
        }
    }
}
