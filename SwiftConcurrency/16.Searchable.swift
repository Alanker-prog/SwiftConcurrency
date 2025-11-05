//
//  16.Searchable.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 31.10.2025.
//

import SwiftUI
import Combine

// ✴️ MARK: Модель данных
/*
 🟢 Restaurant — это описание ресторана:
    ➡️ id — уникальный идентификатор (нужен для ForEach и навигации)
    ➡️ title — название ресторана
    ➡️ cuisine — тип кухни (итальянская, японская и т. д.)
    ⚠️ CuisineOption — перечисление (enum) с типами кухонь.Оно хранит "сырой" текст (rawValue), который можно красиво отобразить (capitalized → “Italian”).
 */
struct Restaurant: Identifiable, Hashable {
    let id: String
    let title: String
    let cuisine: CuisineOption
}

enum CuisineOption: String {
    case american, italian, japanese, russian
}

// ✴️ MARK: Менеджер данных
/*
 🟢 Этот класс имитирует загрузку данных — будто бы с сервера или базы данных.На деле он просто возвращает 4 ресторана.
 🟡 Отмечен async throws, чтобы можно было легко заменить на настоящую сетевую загрузку позже.
 */
final class RestaurantManager {
    
    func getAllRestaurants() async throws -> [Restaurant] {
        [
            Restaurant(id: "1", title: "Burger Shack", cuisine: .american),
            Restaurant(id: "2", title: "Teremok ", cuisine: .russian),
            Restaurant(id: "3", title: "Pasta Palace", cuisine: .italian),
            Restaurant(id: "4", title: "Tanuki family", cuisine: .japanese)
        ]
    }
}

// ✴️ MARK: ViewModel(Это центр логики приложения)
/*
 🟡 @MainActor — гарантирует, что обновления UI происходят в главном потоке.
 🟡 ObservableObject — позволяет SwiftUI следить за изменениями данных.
 
 🔴 @Published: (означает, что SwiftUI-представление перерисуется, когда это свойство изменится)
 🟢 allRestaurants — все рестораны, загруженные из менеджера.
 🟢 filteredRestaurants — отфильтрованные по поиску.
 🟢 searchText — текущий текст в поисковой строке.
 🟢 searchScope — текущий фильтр (например, “Только итальянские”).
 🟢 allSearchScoup — список всех возможных фильтров (“All”, “Italian”, “Japanese” и т. д.).
 
 🔶 enum SearchScopeOption: Hashable {
    ➡️ Это вложенное перечисление для фильтров поиска. Например, пользователь может искать “Sushi” только среди японских ресторанов.
 */
@MainActor
final class SearchableViewModel: ObservableObject {
    
    @Published private(set) var allRestaurants: [Restaurant] = []
    @Published private(set) var filteredRestaurants: [Restaurant] = []
    @Published var searchText: String = ""
    @Published var searchScope: SearchScopeOption = .all
    @Published private(set) var allSearchScoup: [SearchScopeOption] = []
    
    let manager = RestaurantManager()
    private var cancellebles = Set<AnyCancellable>()
    /*
     ✅ var isSearching: Bool { !searchText.isEmpty }
       ➡️ Что делает: Это вычисляемое свойство (computed property).
       ⚠️ Возвращает true, если в поле поиска (searchText) есть хотя бы один символ, и false, если строка пустая.
    💡 Используется, например, чтобы показать кнопку "Отмена" или список результатов только когда пользователь что-то ищет.
     */
    var isSearching: Bool {
        !searchText.isEmpty
    }
    /*
     ✅ var showSearchSuggestions: Bool { searchText.count < 3 }
        ➡️Показывает, нужно ли отображать подсказки для поиска. Возвращает true, если пользователь ввёл меньше 3 символов.

     📦 Примеры:
     searchText = ""        → showSearchSuggestions == true
     searchText = "su"      → showSearchSuggestions == true
     searchText = "sushi"   → showSearchSuggestions == false

     💡 Обычно логика такая: Пока человек только начал вводить запрос (мало символов) → показываем подсказки ("Популярное", "Недавние запросы").
        Когда ввёл 3+ символа → начинаем реальный поиск и скрываем подсказки.
     */
    var showSearchSuggestions: Bool {
        searchText.count < 3
    }
    /*
    ✅ enum SearchScopeOption: Hashable {
       ➡️ SearchScopeOption — это перечисление, которое задаёт варианты области поиска.
       ➡️ Hashable означает, что значения этого перечисления можно использовать, например, в Set, в качестве ключей в Dictionary или сравнивать.

     ✅ Варианты (cases):
     
     case all
     case cuisine(option: CuisineOption)
     
     ➡️ case all - (поиск по всему).
     ➡️ case cuisine(option: CuisineOption) — вариант, когда поиск ограничен определённой кухней (CuisineOption — это, другое перечисление, например, .italian, .japanese, .mexican и т.п.).

    
     ✅ Свойство title:
    
     var title: String {
         switch self {
         case .all:
             return "All"
         case .cuisine(option: let option):
             return option.rawValue.capitalized
         }
     }
     ➡️ Это вычисляемое свойство, которое возвращает текстовое название для каждой опции:
     ➡️ Если вариант .all → возвращает строку "All".
     ➡️ Если вариант .cuisine(option: ...) → берёт rawValue из переданного CuisineOption, делает первую букву заглавной (.capitalized) и возвращает.
     ➡️ Например, если CuisineOption.italian.rawValue == "italian",то SearchScopeOption.cuisine(option: .italian).title вернёт "Italian".
     */
    enum SearchScopeOption: Hashable {
        case all
        case cuisine(option: CuisineOption)
        
        var title: String {
            switch self {
            case .all:
                return "All"
            case .cuisine(option: let option):
                return option.rawValue.capitalized
            }
        }
    }
    
    init() {
        addSubscribers()
    }
    
    /*
     ⚙️🔻 private func addSubscribers() {
          ✅ Мы “слушаем” ($searchText) изменения текста и текущего фильтра ($searchScope).
          ✅ combineLatest — объединяет два паблишера — $searchText и $searchScope.
          ✅ debounce(0.3) — подождать 0.3 сек, пока пользователь перестанет печатать (чтобы не фильтровать на каждый символ).
          ✅ sink — это подписчик (subscriber) и при изменении значений вызывается функция filterRestaurants.
            ⚠️ В теле sink вызывается self?.filterRestaurants(searchText: searchText, currentSearchScope: searchScope) -> То есть при каждом изменении текста поиска или выбранного фильтра вызывается метод фильтрации ресторанов.
          ✅ .store(in: &cancellebles) - Сохраняет подписку в массив cancellebles, чтобы Combine мог управлять её жизненным циклом (и не потерять подписку из памяти).
     */
    private func addSubscribers() {
        $searchText
            .combineLatest($searchScope)
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] (searchText, searchScope) in
                self?.filterRestaurants(searchText: searchText, currentSearchScope: searchScope)
            }
            .store(in: &cancellebles)
    }
    
    // ✴️ MARK: Улучшеная версия этой функции для фильтрации в строке поиска в самом внизу(использовать ее!)
    /*
     🔴🔴🔴 MARK: В САМОМ НИЗУ ЕСТЬ ЛУЧШАЯЯ РЕАЛИЗАЦИЯ ЭТОЙ ФУНКЦИИ, НЕ СТАЛ ЕЕ МЕНЯТЬ ЧТО БЫ НЕ ИЗМЕНЯТЬ УРОК 🔴🔴🔴
     ⚙️🔻 private func filterRestaurants()
       ✴️ Эта функция отвечает за фильтрацию списка ресторанов на основе двух факторов: Результат сохраняется в переменную filteredRestaurants
           ➡️ private функция доступна только внутри этого файла или класса.
           ➡️ searchText — строка, введённая пользователем в поиск (например, "pizza").
     
         🟡 Если пользователь удалил весь текст, то:
            ✅ guard !searchText.isEmpty else {
                filteredRestaurants = []
                searchScope = .all
                return
               ➡️ Проверяет условия, пустой ли текст поиска и очищается до сустого массива если нет символов.
               ➡️ Если пустой — сбрасывает фильтр в .all(все рестораны)
               ➡️ функция завершается (return)
     
         🟡 Фильтрация по категории (scope)
            ✅ var restaurantsInScope = allRestaurants
               ➡️ здесь создаётся переменная restaurantsInScope, в которую изначально кладётся список(массив объектов типа Restaurant) всех ресторанов (allRestaurants).
            ✅ switch currentSearchScope {
               case.all:
                    break
               case.cuisine(let option):
               ⚠️ Здесь выполняется ветвление в зависимости от значения переменной currentSearchScope. currentSearchScope — это enum (перечисление)
                  🔸 Если значение currentSearchScope равно ВЕТКЕ .all, ничего не происходит (break просто прерывает выполнение ветки).Таким образом, restaurantsInScope остаётся равным allRestaurants,то есть показываются все рестораны.
                  🔸 Если выбрана конкретная кухня (например, .cuisine("Italian")), то выполняется фильтрация массива ресторанов: ➡️
            ✅ restaurantsInScope = allRestaurants.filter({ $0.cuisine == option })
               ➡️ filter — это стандартный метод Swift для массивов, который возвращает новый массив, содержащий только те элементы, которые удовлетворяют условию в замыкании ({ ... }).
               ➡️ $0 — это сокращённая форма для обозначения текущего элемента массива в замыкании. Например, если allRestaurants содержит объекты типа Restaurant, то $0 — это конкретный Restaurant.
               ➡️ $0.cuisine == option — условие: оставить только те рестораны, у которых свойство cuisine совпадает с выбранной кухней.
               📌 В итоге restaurantsInScope будет содержать только рестораны нужной кухни.
     
         🟡 Фильтрация по введённому тексту
            ✅ let search = searchText.lowercased()
               ➡️ Приводим поисковую строку к нижнему регистру, чтобы сравнение было регистронезависимым.Например, "Pizza" и "pizza" будут восприниматься одинаково.
            ✅ filteredRestaurants = restaurantsInScope.filter({ restaurant in
               ➡️ Здесь берём список restaurantsInScope (уже ограниченный областью поиска) и применяем к нему метод .filter(...), который возвращает новый массив,включающий только те рестораны, которые удовлетворяют условию внутри замыкания { ... }.
               ⚠️ restaurant — это текущий элемент массива (объект типа Restaurant).
            ✅ Проверяем два условия:
               let titleContainsSearch = restaurant.title.lowercased().contains(search)
               let cuisineContainsSearch = restaurant.cuisine.rawValue.lowercased().contains(search)
                  ➡️ restaurant.title — название ресторана, например "Pizza House".
                  ➡️ restaurant.cuisine.rawValue — строковое значение типа кухни (например, "Italian").
                  ➡️ .contains(search) — проверяет, содержится ли введённый текст в этих строках.
            ✅ Возвращаем результат:
               return titleContainsSearch || cuisineContainsSearch
                  ➡️ Ресторан попадёт в итоговый список если название содержит поисковое слово или тип кухни содержит его.

     */
    private func filterRestaurants(searchText: String, currentSearchScope: SearchScopeOption) {
        guard !searchText.isEmpty else {
            filteredRestaurants = []
            searchScope = .all
            return
        }
        
        // Filter on search scoup
        var restaurantsInScope = allRestaurants
        switch currentSearchScope {
        case.all:
            break
        case.cuisine(let option):
            restaurantsInScope = allRestaurants.filter({ $0.cuisine == option })
        }
        
        
        // Filter on search text
        let search = searchText.lowercased()
        filteredRestaurants = restaurantsInScope .filter({ restaurant in
            let ttileContainsSearch = restaurant.title.lowercased().contains(search)
            let cuisineContainsSearch = restaurant.cuisine.rawValue.lowercased().contains(search)
            return ttileContainsSearch || cuisineContainsSearch
        })
    }
    /*
  ⚙️🔻 func loadRestaurants() async - Функция async, она имитирует загрузку данных из сети. В родительском View вызовим ее через -> await viewModel.loadRestaurants()
     
     ✅ allRestaurants = try await manager.getAllRestaurants()
       ⚠️Здесь происходит главное действие:
         ➡️ manager — это объект, который отвечает за загрузку данных (например, из сети или базы данных).
         ➡️ getAllRestaurants() — асинхронная функция, возвращающая массив ресторанов [Restaurant].
         ➡️ try await — говорит: await — дождись завершения асинхронной операции,
         ➡️ try — потому что функция может выбросить ошибку (например, нет сети). Результат сохраняется в свойство allRestaurants.
     
     ✅ let allCuisines = Set(allRestaurants.map { $0.cuisine })
       ⚠️ создаём уникальный список всех кухонь, которые есть в полученных ресторанах:
          ➡️ .map { $0.cuisine } → вытаскивает из каждого ресторана его тип кухни (например: [.italian, .japanese, .italian])
          ➡️ Set(...) → убирает дубликаты (получаем Set([.italian, .japanese])). Результат — множество уникальных кухонь(если у нас в массиве к примеру 8 ресторанов с итальнской кухней, что бы они все разом не отображались Set будет отображать один вариант .italian,)
     
     ✅ allSearchScoup = [.all] + allCuisines.map({ SearchScopeOption.cuisine(option: $0) })
       ⚠️ Создаём массив вариантов фильтра для поиска (searchScope):
          ➡️ Сначала добавляем вариант .all — чтобы пользователь мог выбрать «Все рестораны».
          ➡️ Затем — превращаем каждую кухню в вариант SearchScopeOption.cuisine(option: $0) -> (например, .cuisine(option: .italian)).
     */
    func loadRestaurants() async {
        do {
            allRestaurants = try await manager.getAllRestaurants()
            
            let allCuisines = Set(allRestaurants.map { $0.cuisine })
            allSearchScoup = [.all] + allCuisines.map({ SearchScopeOption.cuisine(option: $0) })
            
        } catch {
            print(error)
        }
    }
    // Варианты подсказок по названию
    func getSearchSuggestions() -> [String] {
        guard showSearchSuggestions else {
            return []
        }
        
        var suggestions: [String] = []
        
        let search = searchText.lowercased()
        if search.contains("pa") {
            suggestions.append("Pasta")
        }
        if search.contains("su") {
            suggestions.append("Sushi")
        }
        if search.contains("bu") {
            suggestions.append("Burger")
        }
        suggestions.append("Market")
        
        suggestions.append(CuisineOption.italian.rawValue.capitalized)
        suggestions.append(CuisineOption.american.rawValue.capitalized)
        suggestions.append(CuisineOption.japanese.rawValue.capitalized)
        suggestions.append(CuisineOption.russian.rawValue.capitalized)
        
        return suggestions
    }
    // Варианты подсказок по кухням, так как allRestaurants это массив вызываем через contentsOf:
    func getRestaurantsSuggestions() -> [Restaurant] {
        guard showSearchSuggestions else {
            return []
        }
        
        var suggestions: [Restaurant] = []
        
        let search = searchText.lowercased()
        if search.contains("ita") {
            suggestions.append(contentsOf: allRestaurants.filter({ $0.cuisine == .italian }))
        }
        if search.contains("jap") {
            suggestions.append(contentsOf: allRestaurants.filter({ $0.cuisine == .japanese }))
        }
        
        return suggestions
    }
}

struct SearchableBootcamp: View {
    
    @StateObject private var vm = SearchableViewModel()
    
    /*
     ❕ForEach(...) — цикл, который отображает список ресторанов.
     ✅ vm.isSearching ? vm.filteredRestaurants : vm.allRestaurants
       ⚠️ если сейчас идёт поиск (isSearching == true) и показываем отфильтрованные рестораны, : иначе — все рестораны.
     ✅ NavigationLink(value: restaurant) — при нажатии на элемент списка переходим к экрану конкретного ресторана.
     ✅ restaurantRow(restaurant:) — отдельная функция, создающая вью одного ресторана (описана внизу).
     */
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(vm.isSearching ? vm.filteredRestaurants : vm.allRestaurants) { restaurant in
                    NavigationLink(value: restaurant) {
                        restaurantRow(restauranr: restaurant)
                    }
                }
            }
            .padding(.horizontal)
        }
        /*
         🔴 Добавляет поле поиска в навигационную панель
           🟢 text: $vm.searchText — двусторонняя привязка к свойству searchText во ViewModel.Когда пользователь вводит текст, vm.searchText обновляется автоматически.
           🟢 prompt — текст-подсказка в поле (“placeholder”).
           🟢 placement — где отображать поиск (.navigationBarDrawer — под навигацией).
         📍 При каждом изменении текста во ViewModel обычно вызывается фильтрация (например, с помощью onChange в модели).
         */
        .searchable(text: $vm.searchText, placement: .navigationBarDrawer, prompt: "Search restaurants...")
        /*
         🔴 Этот блок добавляет фильтры (scope buttons) прямо под полем поиска.Пример: «All», «Italian», «Japanese» и т. д.
           🟢 vm.searchScope — выбранный фильтр, который связан с кнопками (через $ — привязка).
           🟢 vm.allSearchScoup — массив всех возможных фильтров (скорее всего, [SearchScopeOption]).
           🟢 Text(scope.title) — название фильтра.
           🟢 .tag(scope) — связывает кнопку с конкретным значением enum’а SearchScopeOption.
         📍 Когда пользователь выбирает категорию (например, “Italian”), VM обновляется, и снова выполняется фильтрация.
         */
        .searchScopes($vm.searchScope, scopes: {
            ForEach(vm.allSearchScoup, id: \.self) { scope in
                Text(scope.title)
                    .tag(scope)
            }
        })
        /*
         🔴 Этот блок показывает предложения под полем поиска, пока пользователь печатает.
           🟢 vm.getSearchSuggestions() возвращает массив строк — например, “pizza”, “sushi”, “pasta”.
           🟢 Text(suggestion).searchCompletion(suggestion) — если нажать на эту подсказку, текст автоматически вставится в строку поиска.
           🟢 vm.getRestaurantsSuggestions() возвращает массив ресторанов, которые соответствуют введённому тексту.
           🟢 Каждый из них оборачивается в NavigationLink, чтобы пользователь мог сразу перейти к этому ресторану.
         📍 То есть в подсказках могут быть и слова, и конкретные рестораны.
         */
        .searchSuggestions({
            ForEach(vm.getSearchSuggestions(), id: \.self) { suggestion in
                Text(suggestion)
                    .searchCompletion(suggestion)
            }
            ForEach(vm.getRestaurantsSuggestions(), id: \.self) { suggestion in
                NavigationLink(value: suggestion) {
                    Text(suggestion.title)
                }
            }
        })
        .navigationTitle("Restaurants")
        /*
         🔴 .task {} — выполняет асинхронную задачу при появлении вью.
           🟢 await vm.loadRestaurants() — вызывает функцию во ViewModel, которая, скорее всего, загружает данные (например, из сети или JSON).
         📍 Это происходит один раз при первом показе экрана.
         */
        .task {
            await vm.loadRestaurants()
        }
        /*
         🔴 Этот модификатор определяет куда переходить, если пользователь нажал на NavigationLink(value:).
           ⚠️ restaurantRow(restauranr: restaurant) Выше в коде - создает каждому рестарвну из массива [Restaurant] отдельное view
           🟢 В данном случае: это значение типа из массива Restaurant, то откроется экран с заголовком ресторана(имитируем переход на сайт ресторана)
         */
        .navigationDestination(for: Restaurant.self) { restaurant in
            Text(restaurant.title.uppercased())
        }
    }
    // Вспомогательная функция(используем ее выше в основном методе ForEach)
    private func restaurantRow(restauranr: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(restauranr.title)
                .font(.headline)
                .foregroundStyle(.red)
            Text(restauranr.cuisine.rawValue.capitalized)
                .font(.caption)
                .foregroundStyle(.green)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.05))
        .tint(.primary)
    }
}

/*
 ⚠️ Это структура аналог этого кода из приложения  -> var isSearching: Bool { !searchText.isEmpty } ,она определяет isSearching true или false. Просто тут другой подход через окружение @Environment. Он как будто чтуть более сложный и в пиложении мы использовали более простой способ  var isSearching: Bool { !searchText.isEmpty }
 🔴 Эта структура не используется! Она просто что бы продимонстрировать дополнтьельный метод для поисковой строки
 
✅ @Environment(\.isSearching) private var isSearching
  ➡️ Это ключевая строка. Она говорит SwiftUI: «Возьми значение из environment (окружения) по ключу .isSearching и сохрани его в переменную isSearching».
  ➡️ @Environment — специальный property wrapper, который позволяет «наследовать» данные из родительских вью.
  ➡️ \.isSearching — это environment key, предоставляемый самим SwiftUI.Он сообщает, активен ли сейчас поиск в Searchable (например, если родитель использует .searchable() модификатор).
  ➡️ когда пользователь активирует строку поиска, isSearching в SearchChildView станет true.
 */
struct SearchChildView: View {
    
    @Environment(\.isSearching) private var isSearching
    
    var body: some View {
        Text("Child View is searching: \(isSearching.description)")
    }
}

#Preview {
    NavigationStack {
        SearchableBootcamp()
    }
}

/*
private func filterRestaurants(searchText: String, currentSearchScope: SearchScopeOption) {
    // 1. Проверяем, что строка поиска не пуста
    guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        filteredRestaurants = []
        searchScope = .all
        return
    }

    // 2. Подготавливаем текст для поиска
    let search = searchText.lowercased()

    // 3. Фильтруем рестораны по выбранному scope (кухне)
    let restaurantsInScope: [Restaurant]
    switch currentSearchScope {
    case .all:
        restaurantsInScope = allRestaurants
    case .cuisine(let option):
        restaurantsInScope = allRestaurants.filter { $0.cuisine == option }
    }

    // 4. Фильтруем по тексту (название или кухня)
    filteredRestaurants = restaurantsInScope.filter { restaurant in
        restaurant.title.localizedCaseInsensitiveContains(search)
        || restaurant.cuisine.rawValue.localizedCaseInsensitiveContains(search)
    }
}
*/
/*
   🔴 ⬆️ ПОЧЕМУ ЭТОТ КОД ЛУЧШЕ ЧЕМ ТОТ ЧТО В УРОКЕ! ⬆️ 🔴
  ⚠️⚠️ Можно сделать ещё компактнее, можно заменить switch на if case: он идеально подходит, если в SearchScopeOption всего 2–3 кейса.⚠️⚠️
 
 ✅ 1. Очистка строки поиска от пробелов
 guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { ... }


 Убирает пробелы и переносы строк.

 Если пользователь случайно ввёл " " (только пробелы), фильтр всё равно не сработает, как и задумано.

 ✅ 2. Использование localizedCaseInsensitiveContains
 restaurant.title.localizedCaseInsensitiveContains(search)


 Это более “умный” способ поиска, чем lowercased().contains().

 Он не зависит от регистра и учитывает локализацию (например, русские и латинские буквы).

 Работает корректнее с разными языками и акцентами.

 ✅ 3. Убраны лишние переменные

 В исходном коде были промежуточные переменные:

 let titleContainsSearch = ...
 let cuisineContainsSearch = ...
 return titleContainsSearch || cuisineContainsSearch


 Это было избыточно — теперь выражение сразу возвращает результат.
 Функция читается проще и короче, не теряя смысл.

 ✅ 4. restaurantsInScope объявлена через let
 let restaurantsInScope: [Restaurant]


 Она не изменяется после установки, поэтому логичнее сделать её константой (let), а не переменной (var).

 Это повышает безопасность кода и делает его “чистее”.

 ✅ 5. Улучшена читаемость

 Теперь структура кода идёт логично и “сверху вниз”:

 Проверка на пустой ввод

 Подготовка текста

 Фильтрация по кухне

 Фильтрация по тексту

 Больше не нужно “прыгать глазами” по break и вложенным фильтрам.
 */
