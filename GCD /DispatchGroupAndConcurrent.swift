//
//  GroupAndConcurrentPerform.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import UIKit

class GroupAndConcurrentPerform: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        group.enter()
        
        queue.async {
            DispatchQueue.concurrentPerform(iterations: 5) { index in
                print("Processing item \(index)")
                print(Thread.current)
            }
            
            group.leave()
        }
        
        group.notify(queue: .main) {
            print("All parallel work completed → обновляем UI")
        }
    }
}

/*
 🟢 DispatchGroup + concurrentPerform
    ◉ concurrentPerform выполняет параллельный цикл
    ◉ DispatchGroup позволяет узнать, когда ВСЯ работа завершена
    ◉ В связке мы контролируем момент окончания параллельных вычислений

 🔹 Что происходит в примере
    ◉ concurrentPerform запускает 5 параллельных итераций
    ◉ Он блокирует текущий фоновый поток
    ◉ После завершения вызывается group.leave()
    ◉ notify срабатывает, когда группа завершена

 ⚠️ Важно
    ◉ concurrentPerform сам по себе синхронный
    ◉ DispatchGroup здесь нужен, чтобы уведомить main поток
    ◉ UI обновляем только внутри notify(.main)

 🔸 Где это может применяться
    ◉ Параллельная обработка изображений
    ◉ Массовые вычисления перед отображением данных
    ◉ Подготовка данных перед обновлением интерфейса

────────────────────────────────────────────

 🟡 Пример из жизни (загрузка 5 изображений)

 Если загрузить 5 изображений через:

    URLSession.shared.dataTask

 ◉ Каждая загрузка асинхронная
 ◉ Изображения будут появляться по одному
 ◉ Порядок завершения будет случайным
 ◉ Нужно вручную отслеживать, когда все загрузки завершены
    (например через DispatchGroup)

 Проблема:
 UI обновляется частями

────────────────────────────────────────────

 🟢 Если использовать TaskGroup

 ◉ Можно запустить 5 загрузок одновременно
 ◉ Дождаться завершения всех задач
 ◉ Получить массив результатов
 ◉ Обновить UI ОДИН раз

 Это современный способ групповой параллельной работы.

────────────────────────────────────────────

 🧠 Главное, что нужно запомнить
    ◉ concurrentPerform = параллельный цикл (sync)
    ◉ DispatchGroup = механизм ожидания
    ◉ Вместе дают контроль над завершением работы
    ◉ Для новых проектов предпочтительнее TaskGroup
 */
