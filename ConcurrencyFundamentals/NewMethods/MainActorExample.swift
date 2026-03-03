//
//  MainActorExample.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import UIKit

@MainActor
class MainActorExample: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            await loadData()
        }
    }
    
    func loadData() async {
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        view.backgroundColor = .blue
        print("Updated on main thread:", Thread.isMainThread)
    }
}

/*
 🟢 Что такое @MainActor

    ◉ @MainActor — это глобальный actor,
      который гарантирует выполнение кода на главном потоке.

    ◉ Используется для UI-логики.

────────────────────────────────────────────

 🔥 Что происходит в примере

    ◉ Класс помечен @MainActor
    ◉ Все его методы выполняются на main thread
    ◉ Даже если вызываются из фонового Task

────────────────────────────────────────────

 🧠 Почему это важно

    UIKit:
        ◉ UI обновляется только на main thread

    Раньше:
        DispatchQueue.main.async { }

    Теперь:
        @MainActor

────────────────────────────────────────────

 🟢 Разница подходов

    Старый способ (GCD):
        DispatchQueue.main.async {
            updateUI()
        }

    Современный способ:
        @MainActor
        func updateUI() { }

────────────────────────────────────────────

 🔥 Можно помечать:

    ◉ Весь класс
    ◉ Отдельные методы
    ◉ Отдельные свойства

    Например:

        @MainActor
        func updateUI() { }

────────────────────────────────────────────

 ⚠️ Важно понимать

    ◉ @MainActor НЕ создаёт поток
    ◉ Это изоляция на главном actor
    ◉ Компилятор следит за безопасностью

────────────────────────────────────────────

 🟡 Когда использовать

    ◉ ViewController
    ◉ ViewModel
    ◉ Любой код, работающий с UI
    ◉ Обновление состояния для SwiftUI

────────────────────────────────────────────

 🧠 Главное, что нужно запомнить

    ◉ @MainActor гарантирует выполнение на main thread
    ◉ Современная замена DispatchQueue.main.async
    ◉ Делает код безопаснее
    ◉ Рекомендуемый способ работы с UI
 */
