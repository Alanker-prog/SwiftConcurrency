//
//  BlockOperationExample.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import UIKit

class BlockOperationExample: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let operation = BlockOperation {
            print("BlockOperation started")
            print(Thread.current)
        }
        
        let queue = OperationQueue()
        queue.addOperation(operation)
    }
}

/*
 🟢 BlockOperation

    ◉ Готовая реализация класса Operation
    ◉ Выполняет переданный блок кода
    ◉ Объектная альтернатива DispatchWorkItem

────────────────────────────────────────────

 🟢 let operation = BlockOperation { }

    ◉ Создаём операцию
    ◉ Код НЕ выполняется до добавления в очередь
    ◉ Можно создать несколько блоков внутри одной операции

────────────────────────────────────────────

 🟢 OperationQueue

    ◉ Очередь для выполнения операций
    ◉ Аналог DispatchQueue, но более высокого уровня
    ◉ Управляет жизненным циклом Operation

────────────────────────────────────────────

 🔸 Отличие от GCD

    DispatchQueue:
        ◉ Работает с блоками
        ◉ Нет состояния задачи

    OperationQueue:
        ◉ Работает с объектами Operation
        ◉ Есть состояние (isExecuting, isFinished)
        ◉ Можно отменять операции

────────────────────────────────────────────

 ❗ Важно

    ◉ Operation НЕ запускается автоматически
    ◉ Она должна быть добавлена в OperationQueue
    ◉ Можно отменить через operation.cancel()

────────────────────────────────────────────

 🟡 Пример из жизни

    Представь:
    ◉ У нас есть несколько задач загрузки данных
    ◉ Мы хотим управлять ими как объектами
    ◉ Возможность отменить или поставить зависимости

    BlockOperation позволяет обернуть задачу в управляемый объект.

────────────────────────────────────────────

 🧠 Главное, что нужно запомнить

    ◉ BlockOperation = объектная обёртка над блоком
    ◉ Выполняется через OperationQueue
    ◉ Можно отменить
    ◉ Более высокий уровень абстракции, чем GCD
 
 🔥 Важно для понимания
    ◉ Если создать BlockOperation, но не добавить в очередь, она не выполнится.
    ◉ В отличие от DispatchQueue.async, здесь всё строится через очередь.
 */
