//
//  13.StrongAndWeakSelf.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 29.10.2025.
//

import SwiftUI

struct StrongAndWeakSelfBootcamp: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    StrongAndWeakSelfBootcamp()
}
/*
 🧩 1. Что было раньше (до Swift Concurrency)

 Раньше, когда мы использовали:
 замыкания (completion handlers),
 Combine (sink),
 GCD (DispatchQueue.async),мы часто создавали циклы сильных ссылок:

 networkManager.loadData { data in
     self.handleData(data) // <-- self сильно захвачено
 }

 ➡️ Замыкание захватывало self сильно,
 и если self хранило ссылку на networkManager, то образовывался retain cycle —
 объекты никогда не освобождались из памяти.

 🔧 Поэтому использовали слабые ссылки:

 networkManager.loadData { [weak self] data in
     self?.handleData(data)
 }

 ⚙️ 2. Что изменилось в Swift Concurrency

 Теперь у нас есть:

 Task {
     await viewModel.loadData()
 }


 или

 for await message in chat.messagesStream {
     await handle(message)
 }


 ❗️Здесь нет цикла сильных ссылок, даже если ты используешь self напрямую.

 Почему? Потому что Swift Concurrency управляет временем жизни задач по-другому, и Task не сохраняет сильную ссылку на self так, как это делает замыкание.

 🧠 3. Как именно это работает

 Когда ты создаёшь задачу (Task { ... }), происходит следующее:

 Задача — это объект, живущий независимо от self;

 Код внутри Task захватывает self, но:

 если Task находится внутри @MainActor, то Swift не продлевает жизнь self искусственно;

 если self уничтожен, то задача может быть автоматически отменена.

 Пример:
 class MyViewModel {
     func start() {
         Task {
             await loadData()
         }
     }
     
     func loadData() async {
         print("Загружаем...")
     }
 }


 Если ViewModel будет уничтожена (например, экран закрылся),
 задача внутри Task автоматически завершится, потому что Swift Concurrency отслеживает контекст акторов и задач.

 👉 Это значит, что нет необходимости вручную писать [weak self].

 🔒 4. @MainActor и защита от утечек

 Если метод помечен @MainActor, то:

 он выполняется строго на главной очереди;

 self тоже живёт на главном акторе;

 Swift гарантирует, что не будет утечки памяти при захвате self.

 Пример:

 @MainActor
 class ViewModel {
     func fetch() async {
         print("fetch")
     }

     func start() {
         Task {
             await fetch() // захватываем self безопасно
         }
     }
 }


 Здесь Task выполняется на MainActor →
 никакой retain cycle не может возникнуть, потому что задача жизненно связана с актором, а не с объектом self.

 🧩 5. Когда слабые ссылки всё же нужны

 Хотя в большинстве случаев Swift Concurrency решает проблему владения,
 иногда weak self всё ещё полезно:

 🧷 Случай 1: когда Task живёт дольше, чем объект

 Если ты создаёшь задачу, которая может жить вне контекста объекта, например:

 class Downloader {
     func startDownload() {
         Task.detached {
             await self.downloadFile()
         }
     }
 }


 Здесь Task.detached не привязана к актору и не знает про self.
 Если Downloader уничтожится, а задача всё ещё выполняется,
 то она продолжит работу и будет удерживать self в памяти.

 ➡️ В таких случаях нужно явно использовать weak:

 Task.detached { [weak self] in
     await self?.downloadFile()
 }

 🧷 Случай 2: при работе с Combine, closures и старым кодом

 Если у тебя есть старый API с completion handlers,
 там по-прежнему могут быть retain cycle — Swift Concurrency не спасёт.
 Тогда weak self всё ещё обязателен.

 🧮 6. Почему это безопасно — технически

 Swift Concurrency построен вокруг структуры владения (ownership model) и потоков акторов (actors).
 Главные механизмы:

 Structured Concurrency — задачи живут внутри родительских задач и завершаются вместе с ними.

 Task Tree — если self уничтожен, родительская задача отменяется.

 Actors — каждая сущность выполняет свой код последовательно и безопасно.

 📘 Поэтому Task не удерживает self "навечно" — она лишь использует его, пока он жив.

 🧠 Итого: почему weak self больше почти не нужен
 Причина    Объяснение
 ✅ Task не создаёт циклов    Задачи не удерживают self бесконечно
 ✅ Structured Concurrency    Родитель уничтожен → дочерние задачи завершаются
 ✅ @MainActor безопасность    self живёт в главном акторе, утечек нет
 ⚠️ weak self нужно только в Task.detached    Там нет контекста актора, можно удержать self
 💬 Пример сравнения
 
 👎 Старый Combine-подход:
 publisher
     .sink { [weak self] value in
         self?.updateUI(value)
     }


 нужно weak self, иначе утечка.

 👍 Новый Concurrency-подход:
 Task {
     for await value in publisher.values {
         await self.updateUI(value)
     }
 }


 weak self не нужно — Task безопасна и завершится вместе с объектом.
 */
