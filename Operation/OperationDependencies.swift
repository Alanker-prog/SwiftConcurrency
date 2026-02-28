//
//  OperationDependencyExample.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import UIKit

class OperationDependencyExample: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = OperationQueue()
        
        let operationA = BlockOperation {
            print("Download data")
            sleep(1)
        }
        
        let operationB = BlockOperation {
            print("Parse data")
        }
        
        let operationC = BlockOperation {
            print("Update UI")
        }
        
        operationB.addDependency(operationA)
        operationC.addDependency(operationB)
        
        queue.addOperations([operationA, operationB, operationC], waitUntilFinished: false)
    }
}

/*
 🟢 Dependencies (Зависимости)

    ◉ Позволяют выстроить порядок выполнения операций
    ◉ Операция НЕ начнётся, пока не завершатся её зависимости
    ◉ Работает независимо от порядка добавления в очередь

────────────────────────────────────────────

 🟢 operationB.addDependency(operationA)

    ◉ B начнётся только после завершения A

    operationC.addDependency(operationB)
    ◉ C начнётся только после завершения B

    Получаем реальную цепочку:

        A → B → C

────────────────────────────────────────────

 🔥 Главное преимущество перед GCD

    В GCD пришлось бы:
    ◉ Вкладывать async внутрь async
    ◉ Или использовать DispatchGroup
    ◉ Или вручную контролировать порядок

    Operation делает это нативно и чисто.

────────────────────────────────────────────

 🟡 Пример из жизни

    1. Скачать JSON
    2. Распарсить
    3. Сохранить в базу
    4. Обновить UI

    Каждое действие — отдельная Operation.
    Связываем их зависимостями.
    Получаем чистую архитектуру без callback-ада.

────────────────────────────────────────────

 🧠 Важно понимать

    ◉ Dependency — это логическая зависимость, а не поток
    ◉ Очередь сама решает, на каком потоке выполнить операцию
    ◉ Зависимости можно строить в любом направлении
    ◉ Можно строить сложный граф задач

────────────────────────────────────────────

 🟢 Отличие от Swift Concurrency

    OperationQueue:
        ◉ Dependency graph строится вручную

    Task / async-await:
        ◉ Последовательность описывается через await
        ◉ Более современный и читаемый способ

────────────────────────────────────────────

 🧠 Главное, что нужно запомнить

    ◉ addDependency создаёт порядок выполнения
    ◉ Dependency — ключевая фишка Operation
    ◉ Позволяет строить pipeline задач
    ◉ Делает код чище по сравнению с GCD
 */
