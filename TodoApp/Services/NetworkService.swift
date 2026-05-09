import Foundation

nonisolated final class NetworkService: @unchecked Sendable {
    
    static let shared = NetworkService()
    private init() {}
    
    private let todosURL = "https://dummyjson.com/todos"
    
    func fetchTodos(completion: @escaping ([TodoDTO]) -> Void) {
        guard let url = URL(string: todosURL) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "unknown")")
                completion([])
                return
            }
            completion(self.decode(data))
        }.resume()
    }
    
    nonisolated private func decode(_ data: Data) -> [TodoDTO] {
        do {
            let response = try JSONDecoder().decode(TodoResponse.self, from: data)
            return response.todos
        } catch {
            print("Decode error: \(error)")
            return []
        }
    }
}

// MARK: - DTO Models

nonisolated struct TodoResponse: Decodable, Sendable {
    let todos: [TodoDTO]
}

nonisolated struct TodoDTO: Decodable, Sendable {
    let id: Int
    let todo: String
    let completed: Bool
    let userId: Int
}
