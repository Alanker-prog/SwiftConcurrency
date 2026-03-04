//
//  TaskGroupNetworkingExample.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import SwiftUI

struct PostTG: Decodable, Sendable {
    let id: Int
    let title: String
}

struct TaskGroupNetworkingExample: View {
    
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
            let posts = try await fetchPosts(ids: [1,2,3,4,5])
            titles = posts.map { $0.title }
        } catch {
            titles = ["Error loading posts"]
        }
    }
    
    func fetchPosts(ids: [Int]) async throws -> [PostTG] {
        
        try await withThrowingTaskGroup(of: PostTG.self) { group in
            
            for id in ids {
                group.addTask {
                    try await fetchPost(id: id)
                }
            }
            
            var posts: [PostTG] = []
            
            for try await post in group {
                posts.append(post)
            }
            
            return posts
        }
    }
    
    func fetchPost(id: Int) async throws -> PostTG {
        
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(PostTG.self, from: data)
    }
}

#Preview {
    TaskGroupNetworkingExample()
}

/*
 🟢 TaskGroup + Параллельный Networking

    ◉ withThrowingTaskGroup создаёт группу задач
    ◉ Каждая задача выполняется параллельно
    ◉ Structured Concurrency (не GCD!)

────────────────────────────────────────────

 🔥 Что происходит

    1️⃣ Передаём массив id
    2️⃣ Для каждого id создаётся Task
    3️⃣ Все запросы выполняются одновременно
    4️⃣ Результаты собираются через for await

────────────────────────────────────────────

 🧠 Важно понимать

    ◉ Это НЕ 5 последовательных запросов
    ◉ Это 5 параллельных задач
    ◉ Swift управляет планированием потоков

────────────────────────────────────────────

 ⚡ Реальный пример из жизни

    Если загружать 5 изображений через:

        URLSession.shared.dataTask

    Они будут приходить:
        ◉ В разном порядке
        ◉ По мере завершения

    TaskGroup позволяет:
        ◉ Запустить их одновременно
        ◉ Контролировать завершение
        ◉ Обрабатывать ошибки централизованно

────────────────────────────────────────────

 🛡 Почему это лучше GCD

    Старый способ:
        ◉ DispatchGroup
        ◉ manual enter/leave

    Новый способ:
        ◉ Structured
        ◉ Автоматическая отмена при ошибке
        ◉ Без утечек задач

────────────────────────────────────────────

 🧠 Главное

    ◉ TaskGroup = параллельные async задачи
    ◉ Не блокирует поток
    ◉ Управляется Swift runtime
    ◉ Современный способ параллельного networking
 */
