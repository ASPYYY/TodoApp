import XCTest
import CoreData
@testable import TodoApp

final class TodoAppTests: XCTestCase {
    
    private static var retainedCoreDataServices: [CoreDataService] = []
    private static var retainedInteractors: [TaskListInteractor] = []
    private static var retainedPresenters: [TaskListPresenter] = []
    private static var retainedViews: [MockView] = []
    
    var coreDataService: CoreDataService!
    var interactor: TaskListInteractor!
    var presenter: MockPresenter!
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        coreDataService = CoreDataService(inMemory: true)
        Self.retainedCoreDataServices.append(coreDataService)
        interactor = TaskListInteractor(service: coreDataService)
        Self.retainedInteractors.append(interactor)
        presenter = MockPresenter()
        interactor.output = presenter
    }
    
    override func tearDownWithError() throws {
        coreDataService = nil
        interactor = nil
        presenter = nil
        try super.tearDownWithError()
    }
    
    // MARK: - CoreDataService Tests
    
    func testCreateTask() throws {
        let task = coreDataService.createTask(title: "Тест", description: "Описание")
        guard let title = task.title,
              let description = task.desc,
              let createdAt = task.createdAt,
              let id = task.id else {
            XCTFail("Expected task to have all required fields")
            return
        }
        
        XCTAssertEqual(title, "Тест")
        XCTAssertEqual(description, "Описание")
        XCTAssertFalse(task.isCompleted)
        XCTAssertFalse(createdAt.timeIntervalSince1970 == 0)
        XCTAssertFalse(id.uuidString.isEmpty)
    }
    
    func testFetchTasks() throws {
        coreDataService.createTask(title: "Задача 1", description: "")
        coreDataService.createTask(title: "Задача 2", description: "")
        let tasks = coreDataService.fetchTasks()
        XCTAssertEqual(tasks.count, 2)
    }
    
    func testFetchTasksWithSearchQuery() throws {
        coreDataService.createTask(title: "Купить молоко", description: "")
        coreDataService.createTask(title: "Позвонить другу", description: "")
        let results = coreDataService.fetchTasks(searchQuery: "молоко")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Купить молоко")
    }
    
    func testFetchTasksEmptyQuery() throws {
        coreDataService.createTask(title: "Задача 1", description: "")
        coreDataService.createTask(title: "Задача 2", description: "")
        coreDataService.createTask(title: "Задача 3", description: "")
        let results = coreDataService.fetchTasks(searchQuery: "")
        XCTAssertEqual(results.count, 3)
    }
    
    func testDeleteTask() throws {
        let task = coreDataService.createTask(title: "Удалить меня", description: "")
        XCTAssertEqual(coreDataService.tasksCount(), 1)
        coreDataService.deleteTask(task)
        XCTAssertEqual(coreDataService.tasksCount(), 0)
    }
    
    func testToggleComplete() throws {
        let task = coreDataService.createTask(title: "Тест", description: "")
        XCTAssertFalse(task.isCompleted)
        coreDataService.toggleComplete(task)
        XCTAssertTrue(task.isCompleted)
        coreDataService.toggleComplete(task)
        XCTAssertFalse(task.isCompleted)
    }
    
    func testUpdateTask() throws {
        let task = coreDataService.createTask(title: "Старое название", description: "Старое описание")
        coreDataService.updateTask(task, title: "Новое название", description: "Новое описание")
        XCTAssertEqual(task.title, "Новое название")
        XCTAssertEqual(task.desc, "Новое описание")
    }
    
    func testTasksCount() throws {
        XCTAssertEqual(coreDataService.tasksCount(), 0)
        coreDataService.createTask(title: "1", description: "")
        coreDataService.createTask(title: "2", description: "")
        XCTAssertEqual(coreDataService.tasksCount(), 2)
    }
    
    // MARK: - Interactor Tests
    
    func testInteractorFetchTasks() throws {
        let expectation = expectation(description: "Fetch tasks")
        presenter.onDidFetchTasks = {
            expectation.fulfill()
        }
        
        coreDataService.createTask(title: "Задача", description: "")
        interactor.fetchTasks(query: "")
        wait(for: [expectation], timeout: 2)
        
        XCTAssertTrue(presenter.didFetchTasksCalled)
        XCTAssertEqual(presenter.fetchedTasks.count, 1)
    }
    
    func testInteractorDeleteTask() throws {
        let fetchExpectation = expectation(description: "Fetch tasks before delete")
        let deleteExpectation = expectation(description: "Delete task")
        presenter.onDidFetchTasks = {
            fetchExpectation.fulfill()
        }
        presenter.onDidDeleteTask = {
            deleteExpectation.fulfill()
        }
        
        let task = coreDataService.createTask(title: "Удалить", description: "")
        interactor.fetchTasks(query: "")
        wait(for: [fetchExpectation], timeout: 2)
        
        interactor.deleteTask(task)
        wait(for: [deleteExpectation], timeout: 2)
        
        XCTAssertTrue(presenter.didDeleteTaskCalled)
        XCTAssertEqual(coreDataService.tasksCount(), 0)
    }
    
    func testInteractorToggleComplete() throws {
        let expectation = expectation(description: "Toggle task")
        presenter.onDidFetchTasks = {
            expectation.fulfill()
        }
        
        let task = coreDataService.createTask(title: "Тест", description: "")
        XCTAssertFalse(task.isCompleted)
        interactor.toggleComplete(task)
        wait(for: [expectation], timeout: 2)
        
        XCTAssertTrue(presenter.fetchedTasks.first?.isCompleted ?? false)
        XCTAssertTrue(presenter.didFetchTasksCalled)
    }
    
    func testInteractorSearchTasks() throws {
        let expectation = expectation(description: "Search tasks")
        presenter.onDidFetchTasks = {
            expectation.fulfill()
        }
        
        coreDataService.createTask(title: "Купить хлеб", description: "")
        coreDataService.createTask(title: "Сделать зарядку", description: "")
        interactor.fetchTasks(query: "хлеб")
        wait(for: [expectation], timeout: 2)
        
        XCTAssertEqual(presenter.fetchedTasks.count, 1)
        XCTAssertEqual(presenter.fetchedTasks.first?.title, "Купить хлеб")
    }
    
    // MARK: - Presenter Tests
    
    @MainActor
    func testPresenterDidFetchTasksCallsView() throws {
        let mockView = MockView()
        let realPresenter = TaskListPresenter()
        Self.retainedViews.append(mockView)
        Self.retainedPresenters.append(realPresenter)
        realPresenter.view = mockView
        let tasks = [coreDataService.createTask(title: "Тест", description: "")]
        realPresenter.didFetchTasks(tasks)
        XCTAssertTrue(mockView.showTasksCalled)
        XCTAssertTrue(mockView.reloadTableCalled)
        XCTAssertEqual(mockView.shownTasks.count, 1)
    }
    
    @MainActor
    func testPresenterDidDeleteTaskCallsView() throws {
        let mockView = MockView()
        let realPresenter = TaskListPresenter()
        Self.retainedViews.append(mockView)
        Self.retainedPresenters.append(realPresenter)
        realPresenter.view = mockView
        let tasks = [coreDataService.createTask(title: "Тест", description: "")]
        realPresenter.didDeleteTask(at: 0, tasks: tasks)
        XCTAssertTrue(mockView.showTasksCalled)
        XCTAssertTrue(mockView.deleteTaskCalled)
    }
    
    @MainActor
    func testPresenterDidFailWithError() throws {
        let mockView = MockView()
        let realPresenter = TaskListPresenter()
        Self.retainedViews.append(mockView)
        Self.retainedPresenters.append(realPresenter)
        realPresenter.view = mockView
        realPresenter.didFailWithError("Тестовая ошибка")
        XCTAssertTrue(mockView.showErrorCalled)
        XCTAssertEqual(mockView.errorMessage, "Тестовая ошибка")
    }
}

// MARK: - Mock Presenter

final class MockPresenter: TaskListInteractorOutputProtocol {
    
    var didFetchTasksCalled = false
    var didDeleteTaskCalled = false
    var didFailCalled = false
    var fetchedTasks: [TaskEntity] = []
    var deletedIndex: Int?
    var onDidFetchTasks: (() -> Void)?
    var onDidDeleteTask: (() -> Void)?
    
    func didFetchTasks(_ tasks: [TaskEntity]) {
        didFetchTasksCalled = true
        fetchedTasks = tasks
        onDidFetchTasks?()
    }
    
    func didDeleteTask(at index: Int, tasks: [TaskEntity]) {
        didDeleteTaskCalled = true
        deletedIndex = index
        fetchedTasks = tasks
        onDidDeleteTask?()
    }
    
    func didFailWithError(_ error: String) {
        didFailCalled = true
    }
}

// MARK: - Mock View

@MainActor
final class MockView: TaskListViewProtocol {
    
    var showTasksCalled = false
    var reloadTableCalled = false
    var deleteTaskCalled = false
    var showErrorCalled = false
    var shownTasks: [TaskEntity] = []
    var errorMessage: String?
    
    func showTasks(_ tasks: [TaskEntity]) {
        showTasksCalled = true
        shownTasks = tasks
    }
    
    func reloadTable() {
        reloadTableCalled = true
    }
    
    func deleteTask(at index: Int) {
        deleteTaskCalled = true
    }
    
    func showError(_ message: String) {
        showErrorCalled = true
        errorMessage = message
    }
}
