//
//  DispatchWorkItem.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 26.02.2026.
//

import UIKit

class DispatchWorkItemExample: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = DispatchQueue.global(qos: .utility)
        
        let workItem = DispatchWorkItem {
            print("Work started")
            print(Thread.current)
        }
        
        workItem.notify(queue: .main) {
            print("Work finished → обновляем UI")
        }
        
        queue.async(execute: workItem)
        
        // workItem.cancel()   // попробуй вызвать до async
    }
}

/*
 🟢 DispatchWorkItem
    ◉ Объект-обёртка вокруг блока кода
    ◉ Позволяет управлять задачей (запуск, отмена, notify)

 🟢 workItem.notify(queue: .main)
    ◉ Выполнится после завершения workItem
    ◉ Удобно для обновления UI
    ◉ Работает похоже на completion handler

 🟢 queue.async(execute: workItem)
    ◉ Отправляем задачу в очередь
    ◉ Выполняется асинхронно в фоновом потоке

 🔸 Для чего используется DispatchWorkItem
    ◉ Возможность отмены задачи
    ◉ Добавление notify после выполнения
    ◉ Повторное использование одного блока
    ◉ Более гибкое управление задачами

 ❗ Отмена задачи
    ◉ workItem.cancel() помечает задачу как отменённую
    ◉ Если задача уже начала выполняться — она НЕ остановится автоматически
    ◉ Внутри блока можно проверить:
        if workItem.isCancelled { return }

 ⚠️ Важно
    ◉ DispatchWorkItem не умеет принудительно останавливать уже выполняющийся код
    ◉ Это кооперативная отмена (нужно проверять isCancelled вручную)

 🟡 Что такое OperationQueue
    ◉ Более высокий уровень абстракции над GCD
    ◉ Работает с объектами Operation
    ◉ Поддерживает зависимости между задачами
    ◉ Может корректно отменять задачи во время выполнения
    ◉ Даёт больше контроля (приоритеты, maxConcurrentOperationCount)

 🧠 Главное, что нужно запомнить
    ◉ DispatchWorkItem = управляемый блок кода
    ◉ notify = код после завершения
    ◉ cancel() не останавливает уже выполняющийся код автоматически
    ◉ OperationQueue — более мощный инструмент поверх GCD
 */
