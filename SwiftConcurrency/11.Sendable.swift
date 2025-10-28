//
//  11.Sendable.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 26.10.2025.
//
/*
 ✴️ Что такое Sendable:

 ✅ Sendable — это протокол, введённый в Swift 5.5 вместе с системой конкурентности (async/await, actors).
    Он помечает типы, которые безопасно передавать между конкурентными контекстами — то есть типы, которые можно «отправить» (send) в другую задачу без риска гонок данных.
 
 ✅ Если ты, например, вызываешь Task внутри View или ObservableObject, то Swift компилятор проверяет, что данные, которые ты передаёшь между задачами, безопасны для параллельного доступа.Если объект не Sendable, компилятор выдаст предупреждение или ошибку.
 */
import SwiftUI
import Combine

/*
 ✅ actor — это специальный тип, который гарантирует потокобезопасность.Всё, что внутри актора, выполняется в одном потоке, так что не может быть гонок данных.

 ✅ Метод updateDatabase(userInfo:) принимает объект MyClassUserInfo и ничего не делает (пока).В реальном коде здесь можно было бы сохранять данные пользователя в базу.

 📘 Важно:
 Чтобы передать данные в актор, объект userInfo должен быть потокобезопасным.
 Для этого используется Sendable — протокол, который гарантирует, что объект можно безопасно передавать между потоками.
 ❌ Если простыми словами, если мы передаем данные в actor(он потокабезопасный класс) из class(ссылочный тип не потокабезопасный) будет проблемы и что бы из бижать этого нужно сделать class потокабезопасным(как в примере ниже)
 ⚠️ Стркутуры по умолчанию потокобезопасны, (пример в низу MyUserInfo) , также важно что бы структура содержала только безопасные типы, тип значения: Struct, Enum, String, Int...
 ⚠️ Она явно помечена Sendable, чтобы компилятор знал, что её можно безопасно передавать между задачами (потоками).
 */
actor CurrentUserManager {
    
    func updateDatabase(userInfo: MyClassUserInfo) {
        }
    }

struct MyUserInfo: Sendable {
    var name: String
}

/*
 ✅ class — ссылочный тип, а классы по умолчанию не потокабезопасны и не соответствуют Sendable,поэтому мы делаем его потокобезопасным, но лучше по возможности использовать структуры(они больше для этого подходят)

 ⚠️  @unchecked Sendable: Означает что программист берёт на себя ответственность за потокобезопасность и говорит компелятору не проверять этот класс на потокобезопасность! ❌ НЕ ЖЕЛАТЕЛЬНО ИСПОЛЬЗОВАТЬ @unchecked В КОДЕ,МОЖНО ЕГО УДАЛИТЬ И ОШИБОК НЕ БУДЕТ, ОТАВИЛ ЕГО ПРОСТО ЧТО БЫ ЗНАТЬ ЧТО ТАКОЕ ЕСТЬ  ❌

 ✅ Чтобы действительно сделать класс потокобезопасным: есть своя DispatchQueue (queue), где выполняются все изменения; в методе updateName(name:) имя обновляется через queue.async, чтобы гарантировать, что не будет одновременных обращений к self.name из разных потоков.
     Таким образом, класс фактически безопасен, хотя компилятор этого сам не проверяет.
 */
final class MyClassUserInfo: @unchecked Sendable {
    private var name: String
    let queue = DispatchQueue(label: "com.MyApp.MyClassUserInfo")
    
    init(name: String) {
        self.name = name
    }
    
    func updateName(name: String) {
        queue.async {
            self.name = name
        }
    }
}

/*
 ✅ Класс — это ObservableObject, значит, его можно использовать в SwiftUI как источник данных.Он создаёт экземпляр актора CurrentUserManager. далее ->
      ➡️ Метод updateCurrentUserInfo():
      ➡️ создаёт объект MyClassUserInfo;
      ➡️ вызывает метод актора updateDatabase(userInfo:) с помощью await.
      ➡️ await нужен, потому что вызов актора — асинхронный, так как доступ к его состоянию должен выполняться последовательно.
 */
class SendableBootcampViewModel: ObservableObject {
    
    var manager = CurrentUserManager()
    
    func updateCurrentUserInfo() async {
        let info = MyClassUserInfo(name: "info")
        await manager.updateDatabase(userInfo: info)
    }
}

struct SendableBootcamp: View {
    
    @StateObject var vm = SendableBootcampViewModel()
    
    var body: some View {
        Text("Hello, World!")
            .task {
                await vm.updateCurrentUserInfo()
            }
    }
}

#Preview {
    SendableBootcamp()
}
