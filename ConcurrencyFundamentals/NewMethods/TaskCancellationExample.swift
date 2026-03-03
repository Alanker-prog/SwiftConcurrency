//
//  TaskCancellationExample.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import UIKit

class TaskCancellationExample: UIViewController {
    
    var task: Task<Void, Never>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        task = Task {
            await longRunningTask()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.task?.cancel()
            print("Task cancelled")
        }
    }
    
    func longRunningTask() async {
        
        for i in 1...10 {
            
            if Task.isCancelled {
                print("Stopped at step:", i)
                return
            }
            
            print("Step:", i)
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        print("Task finished")
    }
}

/*
 🟢 Что такое Task Cancellation

    ◉ Возможность отменить асинхронную задачу
    ◉ Часть Structured Concurrency
    ◉ Работает кооперативно (cooperative cancellation)

────────────────────────────────────────────

 🔥 Что происходит в примере

    ◉ Запускается долгий async Task
    ◉ Через 2 секунды вызывается cancel()
    ◉ Задача проверяет Task.isCancelled
    ◉ И завершает выполнение вручную

────────────────────────────────────────────

 🧠 Важно понимать

    cancel() НЕ останавливает задачу мгновенно.
    Он только выставляет флаг отмены.

    Задача должна сама проверять:

        Task.isCancelled

────────────────────────────────────────────

 🔥 Кооперативная отмена

    Swift не убивает поток.
    Это безопасная модель.

    Ты сам решаешь:
        где остановить выполнение.

────────────────────────────────────────────

 🟢 Альтернативный способ

    try await Task.checkCancellation()

    Если задача отменена —
    будет выброшена ошибка CancellationError.

────────────────────────────────────────────

 🟡 Почему это важно

    ◉ Пользователь ушёл со страницы
    ◉ Сеть больше не нужна
    ◉ Экономия ресурсов
    ◉ Предотвращение утечек

────────────────────────────────────────────

 ⚖️ Сравнение со старыми подходами

    GCD:
        ◉ DispatchWorkItem.cancel()
        ◉ Нет structured модели

    Operation:
        ◉ isCancelled
        ◉ Нужно проверять вручную

    Task:
        ◉ Встроенная поддержка отмены
        ◉ Интеграция с async/await

────────────────────────────────────────────

 🧠 Главное, что нужно запомнить

    ◉ Task поддерживает отмену
    ◉ Отмена кооперативная
    ◉ Нужно проверять Task.isCancelled
    ◉ Это безопасная модель
 */
