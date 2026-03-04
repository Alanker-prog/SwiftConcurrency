//
//  ActorNetworkManager.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import SwiftUI

// MARK: - Model

struct PostTwo: Decodable, Sendable {
    let id: Int
    let title: String
}

// MARK: - Actor

actor NetworkManagerTwo {
    
    private var cache: [Int: PostTwo] = [:]
    
    func fetchPost(id: Int) async throws -> PostTwo {
        
        if let cached = cache[id] {
            return cached
        }
        
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(id)") else {
            throw URLError(.badURL)
        }
        
        /* ЧТО бы убрать желтое предупреждение: Нужно явно указать, что модель не принадлежит MainActor. тоесть довить в Model(nonisolated),
         Но лучше вынести Model в отдельны файл что бы вынести из изоляции MainActor*/
        let (data, _) = try await URLSession.shared.data(from: url)
        let post = try JSONDecoder().decode(PostTwo.self, from: data)
        
        cache[id] = post
        
        return post
    }
}

// MARK: - View

struct ActorNetworkManagerExample: View {
    
    @State private var title = "Loading..."
    private let networkManager = NetworkManagerTwo()
    
    var body: some View {
        Text(title)
            .padding()
            .task {
                await load()
            }
    }
    
    @MainActor
    func load() async {
        do {
            let post = try await networkManager.fetchPost(id: 1)
            title = post.title
        } catch {
            title = "Error"
        }
    }
}

#Preview {
    ActorNetworkManagerExample()
}
/*
 🟢 Исправления для компиляции

    ◉ Post добавлен Sendable
    ◉ Убрана лишняя проверка response
    ◉ UI обновляется под @MainActor

────────────────────────────────────────────

 🧠 Почему нужен Sendable

    ◉ Actor передаёт данные между изоляциями
    ◉ Компилятор требует гарантии потокобезопасности
    ◉ Struct автоматически безопасен,
      но лучше явно указать Sendable

────────────────────────────────────────────

 🟡 Почему @MainActor

    ◉ UI должен обновляться на главном потоке
    ◉ Task не гарантирует main thread
    ◉ Это современный безопасный способ

────────────────────────────────────────────

 🎯 Минимально
    ◉ Без лишней архитектуры
    ◉ Без сложных заглушек
    ◉ Полностью компилируется
 */
