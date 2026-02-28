//
//  OperationQueueExample.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import UIKit

class OperationQueueExample: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        
        for i in 1...5 {
            queue.addOperation {
                print("Operation \(i)")
                print(Thread.current)
                sleep(1)
            }
        }
    }
}

/*
 🟢 OperationQueue

    ◉ Очередь для выполнения объектов Operation
    ◉ Более высокий уровень абстракции, чем DispatchQueue
    ◉ Управляет количеством одновременно выполняемых задач

────────────────────────────────────────────

 🟢 maxConcurrentOperationCount

    ◉ Ограничивает количество параллельных операций
    ◉ 1  → последовательное выполнение
    ◉ >1 → параллельное выполнение
    ◉ default = система сама определяет

    В примере:
    ◉ Одновременно выполняются только 2 операции

────────────────────────────────────────────

 🟢 addOperation { }

    ◉ Упрощённый способ создать BlockOperation
    ◉ Очередь автоматически создаёт Operation

────────────────────────────────────────────

 🔸 Отличие от DispatchQueue

    DispatchQueue:
        ◉ concurrent или serial определяется при создании
        ◉ Нельзя динамически менять количество потоков

    OperationQueue:
        ◉ Можно контролировать параллелизм
        ◉ Можно приостановить очередь
        ◉ Можно отменить все операции
        ◉ Поддерживает зависимости

────────────────────────────────────────────

 🟢 Дополнительные возможности

    queue.isSuspended = true
        ◉ Временно приостанавливает выполнение

    queue.cancelAllOperations()
        ◉ Отменяет все операции в очереди

────────────────────────────────────────────

 🟡 Пример из жизни

    Представь:
    ◉ Нужно загрузить 10 изображений
    ◉ Но не перегружать систему

    Мы можем:
    ◉ Установить maxConcurrentOperationCount = 3
    ◉ И контролировать нагрузку

────────────────────────────────────────────

 🧠 Главное, что нужно запомнить

    ◉ OperationQueue управляет Operation
    ◉ Можно контролировать параллельность
    ◉ Можно отменять и приостанавливать задачи
    ◉ Поддерживает dependency graph
    ◉ Более гибкий инструмент, чем GCD
 */
