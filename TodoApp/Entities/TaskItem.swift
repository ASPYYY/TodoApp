import Foundation
import CoreData

@objc(TaskEntity)
public class TaskEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var desc: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var isCompleted: Bool
}

extension TaskEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }
}
