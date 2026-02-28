//
//  CustomOperationExample.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import UIKit

class CustomOperation: Operation, @unchecked Sendable {
    
    override func main() {
        
        if isCancelled { return }
        
        print("CustomOperation started")
        sleep(2)
        
        if isCancelled { return }
        
        print("CustomOperation finished")
    }
}

class CustomOperationExample: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = OperationQueue()
        
        let operation = CustomOperation()
        queue.addOperation(operation)
    }
}

/*
 🟢 Custom Operation

    ◉ Наследование от класса Operation
    ◉ Позволяет создать собственную логику выполнения
    ◉ Даёт полный контроль над задачей

────────────────────────────────────────────

 🟢 override func main()

    ◉ Точка входа операции
    ◉ Вызывается автоматически при добавлении в очередь
    ◉ Здесь размещается основная логика

────────────────────────────────────────────

 🟢 isCancelled

    ◉ Нужно ОБЯЗАТЕЛЬНО проверять вручную
    ◉ Operation не останавливается автоматически
    ◉ cancel() только выставляет флаг

    Поэтому:
        if isCancelled { return }

────────────────────────────────────────────

 🔥 Главное отличие от BlockOperation

    BlockOperation:
        ◉ Просто выполняет блок

    Custom Operation:
        ◉ Можно добавить свойства
        ◉ Можно хранить состояние
        ◉ Можно внедрять зависимости
        ◉ Можно строить сложную бизнес-логику

────────────────────────────────────────────

 🟡 Пример из жизни

    Представь:
    ◉ Операция загрузки изображения
    ◉ Операция обработки изображения
    ◉ Операция сохранения в кеш

    Каждая из них — отдельный класс.
    Чистая архитектура.
    Чёткое разделение ответственности.

────────────────────────────────────────────

 🧠 Важно понимать

    ◉ Operation — это объект с жизненным циклом
    ◉ Можно отслеживать:
        isReady
        isExecuting
        isFinished
        isCancelled

    ◉ Можно строить сложные dependency graph

────────────────────────────────────────────

 ⚠️ Более глубокий уровень (для продакшена)

    Если операция асинхронная (например URLSession),
    нужно переопределять:
        start()
        isAsynchronous
        управлять состоянием вручную

    Это уже advanced уровень.

────────────────────────────────────────────

 🧠 Главное, что нужно запомнить

    ◉ Custom Operation = управляемая задача
    ◉ Нужно проверять isCancelled
    ◉ Это архитектурный инструмент
    ◉ Более высокий уровень, чем GCD
 */
