//
//  LimitedTaskGroupNetworking.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import SwiftUI

struct PostLimited: Decodable, Sendable {
    let id: Int
    let title: String
}

struct LimitedTaskGroupNetworking: View {
    
    @State private var titles: [String] = []
    
    var body: some View {
        List(titles, id: \.self) { title in
            Text(title)
        }
        .task {
            await loadPosts()
        }
    }
    
    @MainActor
    func loadPosts() async {
        do {
            let posts = try await fetchPosts(ids: Array(1...10), limit: 3)
            titles = posts.map { $0.title }
        } catch {
            titles = ["Error loading posts"]
        }
    }
    
    func fetchPosts(ids: [Int], limit: Int) async throws -> [PostLimited] {
        
        try await withThrowingTaskGroup(of: PostLimited.self) { group in
            
            var iterator = ids.makeIterator()
            var posts: [PostLimited] = []
            
            // Запускаем первые limit задач
            for _ in 0..<limit {
                if let id = iterator.next() {
                    group.addTask {
                        try await fetchPost(id: id)
                    }
                }
            }
            
            // По мере завершения добавляем новые
            while let post = try await group.next() {
                posts.append(post)
                
                if let nextID = iterator.next() {
                    group.addTask {
                        try await fetchPost(id: nextID)
                    }
                }
            }
            
            return posts
        }
    }
    
    func fetchPost(id: Int) async throws -> PostLimited {
        
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(PostLimited.self, from: data)
    }
}

#Preview {
    LimitedTaskGroupNetworking()
}

/*
 🟢 Ограничение параллельности в TaskGroup

    ◉ limit определяет максимум одновременных задач
    ◉ Новая задача добавляется только после завершения предыдущей

────────────────────────────────────────────

 🔥 Что происходит

    1️⃣ Запускаем первые 3 запроса
    2️⃣ Когда один завершился —
       запускаем следующий
    3️⃣ Всегда максимум 3 активных задачи

────────────────────────────────────────────

 🧠 Почему это важно

    ◉ Не перегружаем сервер
    ◉ Контролируем ресурсы
    ◉ Production-safe поведение

────────────────────────────────────────────

 🛡 Это современная замена

    DispatchSemaphore
    OperationQueue(maxConcurrentOperationCount)

────────────────────────────────────────────

 🎯 Главное

    ◉ TaskGroup = гибкий контроль параллелизма
    ◉ Structured Concurrency
    ◉ Production-паттерн
 */
