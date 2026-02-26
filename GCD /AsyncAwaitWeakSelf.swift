//
//  AsyncAwaitWeakSelf.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 24.02.2026.
//

import SwiftUI
import Foundation

/*
🟢 func fetchData() async это асинхронная функция
 ◉ Task.sleep — имитация сетевого запроса (2 секунды)
 ◉ После паузы возвращается строка "Data loaded"
 ⚠️ Важно: во время await поток не блокируется, задача просто приостанавливается.
.*/
// MARK: - Network Layer

/// 🟢 Пример асинхронной функции
/// - `fetchData()` — async функция
/// - `Task.sleep` — имитация сетевого запроса (2 секунды)
/// - Во время `await` поток НЕ блокируется
final class NetworkManager {
    
    func fetchData() async throws -> String {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return "Data loaded"
    }
}

// MARK: - Example 1: Task + weak self

/// Класс без @MainActor
/// Используем `Task` и контролируем жизненный цикл через `[weak self]`
final class ViewModels {
    
    private let network = NetworkManager()
    
    func load() {
        Task { [weak self] in
            guard let self else { return }
            
            let result = try? await network.fetchData()
            print(result ?? "")
        }
    }
    
    deinit {
        print("ViewModels deinitialized")
    }
}

// MARK: - Example 2: @MainActor ViewModel (современный подход)

/// ✅ Весь класс изолирован на MainActor
/// UI-логика всегда выполняется на главном потоке
/// DispatchQueue.main больше не нужен
@MainActor
final class ViewModel {
    
    private let network = NetworkManager()
    
    var text: String = ""
    
    func load() {
        Task { [weak self] in
            guard let self else { return }
            
            let result = try? await network.fetchData()
            self.text = result ?? ""
        }
    }
}

// MARK: - Example 3: Взаимодействие MainActor и Task

/// 🧠 Главное правило:
/// - `@MainActor` → архитектурное решение
/// - `MainActor.run` → точечное решение
/// - `[weak self]` → контроль жизненного цикла объекта

@MainActor
final class FirstVC: UIViewController {
    
    func updateUI() {
        print("UI updated")
    }
}

final class SecondVC: UIViewController {

    let firstVC = FirstVC()

    func doWork() {
        Task {
            await firstVC.updateUI()
        }
    }
}

/// 🔴 Если внутри Task несколько UI-операций:
/// Используй `Task { @MainActor in }`
///
/// Task { @MainActor in
///     label.text = "Hello"
///     view.backgroundColor = .red
/// }

 // MARK: - Example 4: Замыкания и weak self (Retain Cycle)

final class DataLoader {
    
    var completion: (() -> Void)?
    
    func start() {
        completion = {
            print("Loading finished")
        }
    }
    
    deinit {
        print("DataLoader deinitialized")
    }
}

final class ViewModelTwo {
    
    private let loader = DataLoader()
    
    func load() {
        loader.completion = { [weak self] in
            self?.handleResult()
        }
    }
    
    private func handleResult() {
        print("Handle result")
    }
    
    deinit {
        print("ViewModelTwo deinitialized")
    }
}

/// 🟢 Если внутри замыкания есть свойство класса + используется self
/// обязательно проверяем необходимость `[weak self]`,
/// чтобы избежать retain cycle.
