//
//  OperationSummary.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import UIKit

class OperationSummary: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        
        let op1 = BlockOperation {
            print("Task 1")
        }
        
        let op2 = BlockOperation {
            print("Task 2")
        }
        
        op2.addDependency(op1)
        
        queue.addOperations([op1, op2], waitUntilFinished: false)
    }
}

/*
════════════════════════════════════════════
            OPERATION API SUMMARY
════════════════════════════════════════════

                Operation
                     │
         ┌───────────┴───────────┐
         │                       │
  BlockOperation          Custom Operation
                                 │
                          override main()

────────────────────────────────────────────

                OperationQueue
                     │
        addOperation(_:)
        addOperations(_:wait:)
        maxConcurrentOperationCount
        cancelAllOperations()
        isSuspended

────────────────────────────────────────────

                Dependencies
        operationB.addDependency(operationA)

        Формирует порядок выполнения:
                A → B → C

────────────────────────────────────────────

🔥 ОСНОВНЫЕ КОМПОНЕНТЫ

1️⃣ Operation
    ◉ Базовый класс задачи
    ◉ Имеет состояние
    ◉ Можно отменить

2️⃣ BlockOperation
    ◉ Готовая реализация
    ◉ Выполняет блок кода

3️⃣ Custom Operation
    ◉ Наследование от Operation
    ◉ override main()
    ◉ Полный контроль логики

4️⃣ OperationQueue
    ◉ Управляет выполнением операций
    ◉ Контролирует параллельность
    ◉ Поддерживает зависимости

────────────────────────────────────────────

🧠 LIFECYCLE Operation

    isReady
        ↓
    isExecuting
        ↓
    isFinished

    + isCancelled (может быть в любой момент)

────────────────────────────────────────────

⚖️ СРАВНЕНИЕ С GCD

GCD:
    ◉ Работает с блоками
    ◉ Нет состояния задачи
    ◉ Нет dependency graph

Operation:
    ◉ Работает с объектами
    ◉ Есть состояние
    ◉ Есть зависимости
    ◉ Можно приостанавливать очередь

────────────────────────────────────────────

🆕 СРАВНЕНИЕ СО SWIFT CONCURRENCY

Operation:
    ◉ Управление задачами
    ◉ Dependency graph вручную
    ◉ Более тяжёлый инструмент

Task / TaskGroup:
    ◉ Современный async/await
    ◉ Более читаемый код
    ◉ Не блокирует поток
    ◉ Предпочтительнее в SwiftUI

────────────────────────────────────────────

🟡 ПРИМЕР ИЗ ЖИЗНИ

    Загрузка 5 изображений

URLSession + async:
    ◉ Появляются по одной
    ◉ Порядок не гарантирован

OperationQueue:
    ◉ Можно ограничить параллельность
    ◉ Можно построить pipeline

TaskGroup:
    ◉ Одновременная загрузка
    ◉ Более современный подход

────────────────────────────────────────────

🎯 КОГДА ИСПОЛЬЗОВАТЬ OPERATION

    ◉ Сложные pipeline задач
    ◉ Нужны зависимости
    ◉ Нужен контроль состояния
    ◉ Старые проекты
    ◉ Собеседования

────────────────────────────────────────────

🧠 ГЛАВНОЕ

    ◉ Operation = объектная модель задач
    ◉ OperationQueue управляет выполнением
    ◉ Dependency — ключевая фишка
    ◉ Это уровень выше GCD
    ◉ Swift Concurrency — современная замена
════════════════════════════════════════════
 */
