//
//  URLSessionAsyncExample.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import SwiftUI

struct Post: Decodable {
    let id: Int
    let title: String
}

struct URLSessionAsyncExample: View {
    
    @State private var title: String = "Loading..."
    
    var body: some View {
        Text(title)
            .padding()
            .task {
                await fetchPost()
            }
    }
    
    func fetchPost() async {
        
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                title = "Invalid response"
                return
            }
            
            let post = try JSONDecoder().decode(Post.self, from: data)
            title = post.title
            
        } catch {
            title = "Error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    URLSessionAsyncExample()
}

/*
 🟢 URLSession + async/await в SwiftUI

    ◉ URLSession — основной сетевой API iOS
    ◉ Работает одинаково в UIKit и SwiftUI
    ◉ SwiftUI влияет только на UI-слой

────────────────────────────────────────────

 🔥 Что важно в SwiftUI

    ◉ .task — автоматически создаёт Task
    ◉ Выполняется при появлении View
    ◉ Отменяется при уничтожении View

────────────────────────────────────────────

 🧠 Почему это современно

    ◉ Нет completion handler
    ◉ Нет callback-hell
    ◉ Код линейный
    ◉ UI обновляется через @State

────────────────────────────────────────────

 🟡 Важно

    ◉ await НЕ блокирует поток
    ◉ Task приостанавливается
    ◉ UI остаётся отзывчивым

────────────────────────────────────────────

 📌 Архитектурно правильно

    View
        ↓
    Network Layer (actor)
        ↓
    URLSession

    В этом примере логика в View
    Для production нужно выносить в сервис

────────────────────────────────────────────

 🧠 Главное

    ◉ URLSession — не устарел
    ◉ UIKit не обязателен
    ◉ async/await + SwiftUI = современный стек
 */
