# Leksipo — результаты ревью и задачи

Дата ревью: 2 ноября 2026 года. Последнее обновление: 3 ноября 2026 года.

После переименования в Leksipo ссылки на исходники, проект и схемы приведены к новым именам. Исторические пути к результатам проверок в `/tmp` сохранены. Сведения о совместимости: [REBRANDING.md](REBRANDING.md).

Ревью охватывает исходники приложения, виджета, тестов и настройки Xcode: хранение, импорт и восстановление, тренировки, SRS, статистику, достижения, навигацию, локализацию и доступность. Первичное ревью было статическим. Закрытые пункты удалены; ниже оставлены нерешённые проблемы. Выполненные проверки исправлений перечислены в конце документа. Остальные UI-риски по-прежнему требуют проверки в указанных сценариях.

Приоритеты: **P1** — целостность данных или блокировка основного сценария; **P2** — некорректное поведение и существенные неудобства; **P3** — улучшения и технический долг. Порядок внутри раздела не задаёт порядок реализации.

Статусы основания: **код** — поведение следует из реализации; **риск** — предпосылка найдена, но последствия требуют воспроизведения; **продукт** — требуется определить ожидаемое поведение. Для UI отдельно указана необходимость проверки в симуляторе. Ссылки ведут на исходники, номера строк соответствуют состоянию на дату ревью.

## Данные, бэкап и миграция

- [ ] **DATA-07 · P2 · код — Сохранять структуру старых групп при миграции.**
  Группы собираются только из названий в карточках, поэтому пустые пользовательские группы не переносятся. Обход `Set` теряет порядок. UUID карточек теперь сохраняются, но перенос структуры пустых групп и порядка ещё не исправлен.
  Источник: [JSONToSwiftDataMigrator.swift](<Leksipo/Services/Migration/JSONToSwiftDataMigrator.swift>).
  Готово, когда: отдельно проверены пустые группы, порядок, карточка в нескольких группах и совместимость старых идентификаторов с сохраняемым состоянием; неизбежные преобразования документированы.

- [ ] **DATA-09 · P2 · продукт — Уточнить полноту резервной копии.**
  Бэкап включает основные модели, но не имя пользователя, тему, язык, лимит новых SRS-карточек и сохранённые сессии. Очереди теперь хранятся в SwiftData, однако намеренно не включены в DTO бэкапа и очищаются при восстановлении. Формулировки о сохранении всех данных создают более широкое ожидание.
  Источники: [BackupModels.swift](<Leksipo/Models/BackupModels.swift>), [BackupService.swift](<Leksipo/Services/Backup/BackupService.swift>), [SettingsView.swift](<Leksipo/UI/Features/Settings/SettingsView.swift>).
  Готово, когда: состав копии явно показан и соответствует реализации; перенос на чистую установку проверяет все обещанные данные и настройки.

- [ ] **DATA-10 · P2 · продукт — Согласовать названия и последствия сброса данных.**
  Сброс статистики сохраняет счётчики и расписание отдельных карточек, а также достижения. «Удалить все данные» тоже сохраняет разблокированные достижения и ряд настроек UserDefaults. Пользователь не получает чистое состояние, которое может ожидать от этих действий.
  Источники: [SettingsViewModel.swift](<Leksipo/UI/Features/Settings/SettingsViewModel.swift>), [SwiftDataStatsRepository.swift](<Leksipo/Repositories/SwiftData/SwiftDataStatsRepository.swift>).
  Готово, когда: для каждого действия определён и показан точный состав сброса; согласованы достижения, SRS, сессии, уведомления и виджет; проверен результат после перезапуска.

## Виджет, уведомления и локализация

- [ ] **INT-08 · P2 · код — Завершить поддержку выбранного языка во всём приложении.**
  Виджет и тексты напоминаний теперь используют выбранный язык. В основном приложении названия тем через `NSLocalizedString` и русские тексты ошибок репозиториев по-прежнему обходят `.localized()`. Форматирование дат остальных экранов тоже следует проверить при различии системного и выбранного языка.
  Источники: [LanguageManager.swift](<Leksipo/UI/Localization/LanguageManager.swift>), [AppTheme.swift](<Leksipo/UI/Theme/AppTheme.swift>), [RepositoryError.swift](<Leksipo/Repositories/RepositoryError.swift>), [SwiftDataCardRepository.swift](<Leksipo/Repositories/SwiftData/SwiftDataCardRepository.swift>).
  Готово, когда: обе локализации проверены при противоположном языке системы, включая ошибки, темы, даты и уведомления; внутренние диагностические сообщения отделены от пользовательских.

## Интерфейс и продуктовые сценарии

- [ ] **UI-01 · P2 · риск — Проверить навигацию sheet редактирования карточки.**
  `EditCardView` содержит `ScrollView` и toolbar, а место показа через `.sheet` не оборачивает его в `NavigationStack`. Навигационные заголовок и кнопка отмены не имеют собственного контейнера в модальном экране.
  Источники: [EditCardView.swift](<Leksipo/UI/Features/EditCard/EditCardView.swift#L30>), [GroupsListView.swift](<Leksipo/UI/Features/GroupsList/GroupsListView.swift#L88>).
  Готово, когда: в симуляторе подтверждены видимые и работающие заголовок, отмена и сохранение на iPhone/iPad; sheet не зависит от navigation bar presenting-экрана.

- [ ] **UI-02 · P2 · риск — Адаптировать тренировочные экраны к доступному размеру.**
  Обе карточки имеют фиксированный размер 320×480. Соседние счётчики и кнопки увеличивают требуемую высоту, а основной экран не предоставляет полноценную прокрутку. Возможны обрезание и недоступные действия в landscape, небольших окнах iPad и при увеличенном тексте.
  Источники: [SRSCardView.swift](<Leksipo/UI/Features/SRSSolve/Components/SRSCardView.swift#L22>), [SwipeableCardView.swift](<Leksipo/UI/Features/Solve/Components/SwipeableCardView.swift#L18>), [SRSView.swift](<Leksipo/UI/Features/SRSSolve/SRSView.swift>), [SolveView.swift](<Leksipo/UI/Features/Solve/SolveView.swift>).
  Готово, когда: в симуляторе все действия доступны в поддерживаемых ориентациях, узком окне и крупных категориях Dynamic Type без наложений.

- [ ] **UI-03 · P2 · код — Дать доступ к полному тексту карточки.**
  Слова ограничены несколькими строками, пояснения — четырьмя; отдельного раскрытия длинного содержимого нет. Импорт и редактор позволяют сохранить текст, который пользователь затем не сможет полностью прочитать во время обучения.
  Источники: [SRSCardView.swift](<Leksipo/UI/Features/SRSSolve/Components/SRSCardView.swift#L82>), [SwipeableCardView.swift](<Leksipo/UI/Features/Solve/Components/SwipeableCardView.swift#L181>).
  Готово, когда: длинное слово, выражение и пояснение доступны полностью без уменьшения до нечитаемого размера; проверены обе стороны карточки.

- [ ] **UI-04 · P2 · риск — Обеспечить доступность основных действий без жестов.**
  Переворот и ответы в свободной тренировке, раскрытие групп и скрытые действия строк зависят от tap/drag-жестов. Явных эквивалентных accessibility actions недостаточно; ряд кнопок-иконок и состояний выбранной вкладки не имеет содержательных пользовательских обозначений.
  Источники: [SwipeableCardView.swift](<Leksipo/UI/Features/Solve/Components/SwipeableCardView.swift>), [SwipeableCardRow.swift](<Leksipo/UI/Features/GroupsList/Components/SwipeableCardRow.swift>), [SwipeableGroupHeader.swift](<Leksipo/UI/Features/GroupsList/Components/SwipeableGroupHeader.swift>), [CustomTabBar.swift](<Leksipo/UI/TabBar/CustomTabBar.swift>), [DayCell.swift](<Leksipo/UI/Features/Profile/Components/DayCell.swift>).
  Готово, когда: VoiceOver и Switch Control позволяют пройти обучение и управлять словарём; названы действия и состояния, а календарь озвучивает полную дату и прогресс. Требуется реальная проверка, а не только добавление labels.

- [ ] **UI-05 · P3 · риск — Проверить доступность анимаций и областей нажатия.**
  В переворотах и перелётах карточек нет адаптации к Reduce Motion; календарные ячейки и некоторые иконки имеют небольшую визуальную область. Взаимодействие горизонтальных жестов строк с вертикальной прокруткой требует отдельного прогона.
  Источники: [SwipeableCardView.swift](<Leksipo/UI/Features/Solve/Components/SwipeableCardView.swift>), [SRSCardView.swift](<Leksipo/UI/Features/SRSSolve/Components/SRSCardView.swift>), [DayCell.swift](<Leksipo/UI/Features/Profile/Components/DayCell.swift>), [SwipeableGroupHeader.swift](<Leksipo/UI/Features/GroupsList/Components/SwipeableGroupHeader.swift>).
  Готово, когда: уменьшение движения учитывается, области касания удобны, а обычная прокрутка не запускает изменение/удаление. Проверить на устройстве или в симуляторе.

- [ ] **UI-06 · P2 · продукт — Определить сохранение состояния при переключении вкладок.**
  RootView выбирает поддерево через `switch`, поэтому вкладки не сохраняют независимые навигационные стеки и локальное состояние автоматически. Смена языка дополнительно меняет `.id` всего содержимого и может сбросить открытый экран настроек.
  Источник: [RootView.swift](<Leksipo/App/RootView.swift>).
  Готово, когда: поведение возврата во вкладку предсказуемо; отдельно проверены вложенная навигация, раскрытые группы, позиция списка и текущая тренировка. Сохранённая очередь не подменяет сохранение состояния UI.

- [ ] **UI-07 · P2 · риск — Предупреждать о потере несохранённых изменений.**
  У редактора есть `hasChanges`, но он не используется для защиты закрытия sheet. Свайп закрытия может потерять введённые слова, перевод, пояснения и изменения групп без подтверждения.
  Источники: [EditCardViewModel.swift](<Leksipo/UI/Features/EditCard/EditCardViewModel.swift#L75>), [EditCardView.swift](<Leksipo/UI/Features/EditCard/EditCardView.swift>), [AddCardView.swift](<Leksipo/UI/Features/AddCard/AddCardView.swift>).
  Готово, когда: закрытие изменённой формы предлагает сохранить/отбросить/продолжить; пустая или неизменённая форма закрывается без лишних вопросов. Проверить все способы закрытия.

- [ ] **UI-08 · P3 · продукт — Согласовать ввод и последующее изменение имени.**
  На первой странице onboarding кнопка продолжения требует имя, но перелистывание страниц позволяет обойти это ограничение. В профиле имя показывается без отдельного сценария редактирования.
  Источники: [OnboardingView.swift](<Leksipo/UI/Features/Onboarding/OnboardingView.swift>), [ProfileView.swift](<Leksipo/UI/Features/Profile/ProfileView.swift>).
  Готово, когда: имя явно обязательно либо необязательно, все способы навигации следуют этому правилу, а ошибочное имя можно изменить позже.

- [ ] **UI-09 · P3 · продукт — Упростить пополнение и поиск словаря из основного экрана.**
  Добавление карточки связано с пользовательской группой; у системных групп нет такого же прямого действия. Поиск реализован для выбора существующей карточки в форме добавления, но не как основной поиск по словарю. При большой коллекции найти слово для просмотра/редактирования неудобно.
  Источники: [GroupsListView.swift](<Leksipo/UI/Features/GroupsList/GroupsListView.swift>), [GroupRowView.swift](<Leksipo/UI/Features/GroupsList/Components/GroupRowView.swift>), [AddCardView.swift](<Leksipo/UI/Features/AddCard/AddCardView.swift>).
  Готово, когда: согласован короткий путь «добавить первое слово» и «найти существующее слово» из основного экрана; найденная карточка сохраняет все связи с группами.

- [ ] **UI-10 · P3 · риск — Ограничить ширину длинных названий в FlowLayout.**
  Размер элементов запрашивается без ограничения; перенос на следующую строку сам по себе не уменьшает один элемент шире контейнера. Длинное название группы способно выйти за доступную ширину.
  Источник: [FlowLayout.swift](<Leksipo/UI/Shared/FlowLayout.swift>).
  Готово, когда: длинное название, узкий экран и крупный шрифт не расширяют форму за границы; выбранная группа остаётся читаемой и доступной для удаления.

- [ ] **UI-11 · P2 · код — Показывать ошибки загрузки и изменения карточек.**
  Ошибка загрузки групп в редакторе теперь показана с повтором загрузки и блокировкой сохранения. Ошибки сохранения и удаления по-прежнему записываются в `errorMessage`, но после успешной загрузки групп `EditCardView` их не отображает. Обработка ошибок в SRS, свободной тренировке и операциях настроек уже добавлена; остальные пары View/ViewModel нужно проверить отдельно.
  Источники: [EditCardViewModel.swift](<Leksipo/UI/Features/EditCard/EditCardViewModel.swift>), [EditCardView.swift](<Leksipo/UI/Features/EditCard/EditCardView.swift>).
  Готово, когда: ошибки оставшихся экранов видны пользователю, предусмотрен повтор, а ошибка загрузки не маскируется состоянием пустой базы.

## Технический долг, запуск и проверка качества

- [ ] **TECH-03 · P2 · риск — Убрать тяжёлый импорт и повторные полные выборки с критического пути UI.**
  Чтение файла, JSON-декодирование и запись остаются на главном акторе. Импорт теперь строит индексы групп/карточек за одну загрузку и фиксируется общей транзакцией; повторных выборок для каждой входной карточки больше нет. Большие коллекции, другие вызовы `exists`, массовое восстановление, отсутствие прогресса и отмены всё ещё требуют измерений и доработки.
  Источники: [ImportDataViewModel.swift](<Leksipo/UI/Features/ImportData/ImportDataViewModel.swift>), [SwiftDataCardRepository.swift](<Leksipo/Repositories/SwiftData/SwiftDataCardRepository.swift>), [BackupService.swift](<Leksipo/Services/Backup/BackupService.swift>).
  Готово, когда: измерены типовые и большие наборы; сокращены выборки/сохранения, показан прогресс. В фон передаются только безопасные значения/DTO, а не `mainContext` или живые SwiftData-модели.

- [ ] **TECH-04 · P3 · код — Ограничить рост и стоимость хранилища сессий.**
  Store сериализует словарь сессий при изменениях; удаление пользовательской группы не очищает связанную сохранённую сессию. Очереди уже перенесены из UserDefaults в SwiftData для атомарной записи ответов, но большие словари и старые группы продолжают увеличивать стоимость сериализации.
  Источники: [SolveSessionStore.swift](<Leksipo/Services/SolveSession/SolveSessionStore.swift>), [SolveSession.swift](<Leksipo/Services/SolveSession/SolveSession.swift>), [GroupsListViewModel.swift](<Leksipo/UI/Features/GroupsList/GroupsListViewModel.swift>).
  Готово, когда: удалённые группы не оставляют ненужные сессии; измерены чтение/запись больших очередей и определён предел/способ очистки устаревшего состояния.

- [ ] **TECH-05 · P3 · код — Сократить обходы слоя данных и скрытые зависимости.**
  Репозитории возвращают изменяемые SwiftData-модели, бэкап принимает `ModelContext` из UI. Достижения теперь сохраняются явным методом репозитория; границы записи ответов и массовых операций уже объединены транзакцией. Для учебного дня, SRS-координатора и статистики внедрены время, календарь и настройки; глобальные сервисы и остальные обходы слоёв остаются.
  Источники: [AppContainer.swift](<Leksipo/App/AppContainer.swift>), [StatsRepository.swift](<Leksipo/Repositories/Protocols/StatsRepository.swift>), [AchievementsService.swift](<Leksipo/Services/Achievements/AchievementsService.swift>), [SettingsView.swift](<Leksipo/UI/Features/Settings/SettingsView.swift>).
  Готово, когда: при исправлении соответствующих сценариев операции получают явные границы и подменяемые зависимости. Не требуется переписывать MVVM/Repository или вводить новые зависимости ради этого пункта.

- [ ] **TECH-07 · P3 · код — Убрать дублирование загрузки и приблизительные показатели без пояснений.**
  Ряд экранов запускает загрузку и в `.task`, и в `.onAppear`. `StorageSizeCalculator` оценивает объём фиксированными коэффициентами на сущность, а не фактической длиной данных/размером базы; показатель нельзя выдавать за точное занимаемое место.
  Источники: [SolveListView.swift](<Leksipo/UI/Features/SolveList/SolveListView.swift>), [ProfileView.swift](<Leksipo/UI/Features/Profile/ProfileView.swift>), [SRSOverviewView.swift](<Leksipo/UI/Features/SRSOverview/SRSOverviewView.swift>), [StorageSizeCalculator.swift](<Leksipo/UI/Features/Settings/Components/StorageSizeCalculator.swift>).
  Готово, когда: на одно событие жизненного цикла приходится необходимое число загрузок; размер измеряется по определённой методике либо явно подписан как приблизительный.

- [ ] **TECH-09 · P2 · код — Изолировать настройки и жизненный цикл тестовых хранилищ.**
  Тесты координатора теперь используют внедрённый отдельный suite для лимита и очищают его после теста. Новые сценарии также изолированы. Остаётся очистить основной suite каждого экземпляра `SolveSessionStoreTests` после использования; временный второй suite там уже очищается через `defer`.
  Источники: [SolveSessionCoordinatorTests.swift](<Leksipo Tests/Services/SolveSessionCoordinatorTests.swift>), [SolveSessionStoreTests.swift](<Leksipo Tests/Services/SolveSessionStoreTests.swift>), [TestContainer.swift](<Leksipo Tests/Helpers/TestContainer.swift>).
  Готово, когда: тесты используют внедрённые настройки/изолированные suite, не меняют общие предпочтения и дают одинаковый результат при повторных запусках.

- [ ] **TECH-11 · P2 · код/риск — Согласовать совместимость и версии targets перед выпуском.**
  Приложение наследует iOS 18.5, виджет и тесты требуют iOS 26.4. Версия/build приложения — 2.9.0/2, виджета — 1.0/1. Это требует отдельной проверки поддерживаемых устройств, сборки комплекта и валидации архива; успешный выпуск по одним исходникам не подтверждён.
  Источник: [project.pbxproj](<Leksipo.xcodeproj/project.pbxproj#L342>).
  Готово, когда: выбранная разница deployment targets обоснована, версия расширения согласована, выполнены сборка/валидация и проверки на минимальной поддерживаемой ОС. Не повышать минимальную ОС приложения автоматически ради унификации.

- [ ] **TECH-13 · P3 · код — Актуализировать документацию и параметры распространения.**
  README описывает устаревшие версии/минимальную iOS и часть уже реализованных функций как планы; ссылка на LICENSE не подкреплена найденным файлом. В entitlements присутствуют дополнительные App Groups SideStore/AltStore, использование которых текущими сервисами не подтверждено.
  Источники: [README.md](<README.md>), [entitlements приложения](<Leksipo/Leksipo.entitlements>), [entitlements виджета](<Leksipo WidgetsExtension.entitlements>).
  Готово, когда: описание сверено с кодом; лицензию определяет владелец проекта; назначение групп и signing проверено для выбранного способа распространения. Не удалять группы и не менять signing без проверки необходимости.

## Рекомендуемая последовательность оставшейся работы

1. Провести UI-прогон на iPhone/iPad, в landscape, с Dynamic Type и VoiceOver; уточнить оставшиеся продуктовые решения.
2. Закрывать производительность, оставшиеся пробелы тестов и документацию небольшими задачами.

## Проверки после первого этапа исправлений

- Общая схема `Leksipo Tests` явно включает тестовый target. Приложение и виджет собраны для симулятора; 278 тестов прошли на iPhone 17 Pro с iOS 26.4.
- Проверены отказ сохранения/откат бэкапа и ответов, повторная миграция, старый формат бэкапа 2.9.0, некорректные данные, двойной ответ, удалённые UUID, атомарность импорта и удаления, а также обновление прежней SwiftData-схемы и открытие базы новым ModelContainer.
- Экран ошибки миграции визуально проверен на искусственно повреждённом файле в отдельном временном симуляторе. Полный визуальный прогон всех экранов и проверка на физическом устройстве не выполнялись.
- Тесты: [DataSafetyTests.swift](<Leksipo Tests/Persistence/DataSafetyTests.swift>), [MigrationSafetyTests.swift](<Leksipo Tests/Persistence/MigrationSafetyTests.swift>), [PreSafetySchema.swift](<Leksipo Tests/Persistence/PreSafetySchema.swift>).

Выполненная команда из корня проекта (UUID относится к доступному симулятору этой машины):

```sh
xcodebuild test -project 'Leksipo.xcodeproj' \
  -scheme 'Leksipo Tests' \
  -destination 'platform=iOS Simulator,id=0F7663D5-D9BE-4427-84AA-63BC840AEC4D' \
  -derivedDataPath /tmp/EnglishWordsReviewBuild \
  -resultBundlePath /tmp/EnglishWordsSafety-final.xcresult \
  CODE_SIGNING_ALLOWED=NO
```

При повторном запуске выбрать новый путь `-resultBundlePath` (Xcode не перезаписывает существующий результат). На другой машине сначала проверить доступные destinations. Signing, deployment targets и версии приложения/виджета не изменялись; валидация релизного архива этой проверкой не заменяется.

## Проверки защиты редактора после ошибки загрузки групп

- Сборка приложения, виджета и тестового target успешна; 87 тестов редактора и репозиториев карточек/групп прошли на iPhone 17 Pro с iOS 26.4.
- Добавлены 6 регрессионных тестов (8 сценариев с учётом параметров): сохранение до загрузки и после ошибки не меняет карточку и связи; повторная ошибка и успешный повтор не теряют текст и пояснения; повторный `onAppear` не сбрасывает выбор; намеренное удаление всех связей и пустой список групп допустимы; пустые обязательные поля по-прежнему блокируют сохранение. Сохранённые значения проверяются через новый `ModelContext` в изолированной базе в памяти.
- Тесты: [EditCardSafetyTests.swift](<Leksipo Tests/Persistence/EditCardSafetyTests.swift>).
- В отдельном временном симуляторе iPhone 17 Pro с iOS 26.4 редактор отрендерен через `UIHostingController` с искусственной ошибкой чтения групп и после успешного чтения. Визуально проверены сообщение, кнопка повтора, заблокированное сохранение и обычный выбор групп. Использовалась база в памяти; временный сценарий снимков удалён из тестов после проверки. Полный UI-прогон не выполнялся.
- Обе локализации проверены через `plutil -lint`; `git diff --check` выполнен без ошибок.

Выполненная команда из корня проекта:

```sh
xcodebuild test -project 'Leksipo.xcodeproj' \
  -scheme 'Leksipo Tests' \
  -destination 'platform=iOS Simulator,id=0F7663D5-D9BE-4427-84AA-63BC840AEC4D' \
  -derivedDataPath /tmp/EnglishWordsReviewBuild \
  -resultBundlePath /tmp/EnglishWords-DATA11-tests.xcresult \
  '-only-testing:Leksipo Tests/EditCardSafetyTests' \
  '-only-testing:Leksipo Tests/CardRepositoryTests' \
  '-only-testing:Leksipo Tests/GroupRepositoryTests' \
  CODE_SIGNING_ALLOWED=NO
```

## Проверки этапа импорта, SRS, статистики и достижений

3 ноября 2026 года закрыты и удалены из списка: IMP-01–04, SRS-04–11, STAT-01–04, STAT-06–07, TECH-02 и TECH-06. Рекомендуемая последовательность обновлена. TECH-03, TECH-05 и TECH-09 уточнены только в уже исправленной части; оставшаяся работа сохранена.

Принятые правила:

- Импорт сравнивает названия групп и пары слов без регистра и пробелов по краям. Повторные группы объединяются, одна карточка связывается со всеми указанными группами. Существующий текст/пояснения не перезаписываются; среди повторов внутри файла используются первые пояснения. Предпросмотр и итог показывают новые группы, карточки, связи и повторные записи без создания копий. Перед подтверждением база не меняется; после подтверждения расчёт повторяется в общей транзакции. Ошибки содержат путь к полю, неудачная замена файла сбрасывает старый ввод и подтверждение.
- Учебный день — гражданская дата григорианского календаря в текущем часовом поясе. Границы вычисляются календарно, включая DST. Исторические `dateKey` при смене зоны/восстановлении не переименовываются; абсолютные даты SRS интерпретируются в текущей зоне. Сессия другого дня пересобирается, устаревший ответ не записывается.
- Новая карточка расходует дневной лимит при первом SRS-ответе, включая неправильный. Счётчик сохраняется вместе с ответом, переживает новые сессии, повторное открытие базы и перенос бэкапа. Сначала идут назначения по сроку, затем самые старые неизученные слова; SRS больше не перемешивает этот порядок. Изменение лимита и новые назначения учитываются при обновлении очереди и после ответа. Окончание дня проверяет актуальную очередь, а не только прежний размер сессии.
- Дни без заданий засчитываются в SRS-серию. Сохранённая ближайшая дата обязательного повторения позволяет учитывать пустые промежуточные дни без запуска приложения; пропущенное назначение прерывает серию. Новая карточка уточняет эту границу. Оценки сохраняются с прогрессом сессии, прогноз следующего повторения заполняется на завершении.
- Изменение цели действует сегодня, сохраняя флаги прошлых дней. Повышение цели может снять сегодняшний флаг выполнения; повторное достижение не выдаёт дневную награду второй раз. Текущая серия вычисляется по датам истории и не показывает давно прерванную серию.
- Счётчики по-прежнему означают правильные ответы. Подписи уточнены в обеих локализациях; детали и календарь различают частичный прогресс, цель и SRS. История календаря загружается целиком. История всех неправильных попыток свободной тренировки в этом этапе не добавлялась.
- Достижения пересчитываются после импорта, добавления первой карточки, изменения избранного в SRS и свободной тренировке, сохранения цели и открытия профиля. Все одновременно открытые награды попадают в очередь; старое завершение/отмена баннера не удаляет следующую. Создание первой карточки вместе с избранным фиксируется одной транзакцией; действия вынесены в небольшой ViewModel по существующему MVVM.

Файлы этого этапа:

| Область | Файлы и изменения |
| --- | --- |
| Импорт | [ImportDataViewModel.swift](<Leksipo/UI/Features/ImportData/ImportDataViewModel.swift>) — нормализация, предпросмотр, объединение и отчёт; [ImportDataView.swift](<Leksipo/UI/Features/ImportData/ImportDataView.swift>) — подтверждение и подключение достижений. |
| Календарь и модели | Новый [StudyDay.swift](<Leksipo/Services/SRS/StudyDay.swift>) — единая политика дня; [Card.swift](<Leksipo/Models/Card.swift>) и [SRSAlgorithm.swift](<Leksipo/Services/SRS/SRSAlgorithm.swift>) — календарные границы; [DailyStat.swift](<Leksipo/Models/DailyStat.swift>) — дневной счётчик новых слов, число SRS-ответов и следующая обязательная дата. |
| Очередь и ответ | [SwiftDataCardRepository.swift](<Leksipo/Repositories/SwiftData/SwiftDataCardRepository.swift>) — нормализация проверки дублей, квота, порядок, прогноз и учёт добавления слов; [SolveSession.swift](<Leksipo/Services/SolveSession/SolveSession.swift>) — дата и оценки сессии; [SolveSessionCoordinator.swift](<Leksipo/Services/SolveSession/SolveSessionCoordinator.swift>) — актуальная очередь и внедрение настроек/времени; [AnswerRecordingService.swift](<Leksipo/Services/SolveSession/AnswerRecordingService.swift>) — проверка актуальности и атомарная запись дневного статуса. |
| Экран SRS | [SRSViewModel.swift](<Leksipo/UI/Features/SRSSolve/SRSViewModel.swift>) — восстановление оценок, прогноз, обновление моделей и достижения; [SRSView.swift](<Leksipo/UI/Features/SRSSolve/SRSView.swift>) — обновление при системной смене времени; [SRSCardView.swift](<Leksipo/UI/Features/SRSSolve/Components/SRSCardView.swift>) — непустое пояснение на обороте; [SRSOverviewViewModel.swift](<Leksipo/UI/Features/SRSOverview/SRSOverviewViewModel.swift>) — актуальная серия и пустые дни. |
| Статистика и профиль | [StatsRepository.swift](<Leksipo/Repositories/Protocols/StatsRepository.swift>) и [SwiftDataStatsRepository.swift](<Leksipo/Repositories/SwiftData/SwiftDataStatsRepository.swift>) — цель, серии и история; [ProfileViewModel.swift](<Leksipo/UI/Features/Profile/ProfileViewModel.swift>) — актуальные данные и вся история; [ActivityCalendarView.swift](<Leksipo/UI/Features/Profile/Components/ActivityCalendarView.swift>), [DayCell.swift](<Leksipo/UI/Features/Profile/Components/DayCell.swift>) и [DayDetailSheet.swift](<Leksipo/UI/Features/Profile/Components/DayDetailSheet.swift>) — состояния календаря и подробности дня. |
| Достижения и первая карточка | [AchievementsService.swift](<Leksipo/Services/Achievements/AchievementsService.swift>) — очередь уведомлений; [RootView.swift](<Leksipo/App/RootView.swift>) — безопасная отмена показа; новый [AddFirstCardViewModel.swift](<Leksipo/UI/Features/Solve/Components/AddFirstCardViewModel.swift>), [AddFirstCardSheet.swift](<Leksipo/UI/Features/Solve/Components/AddFirstCardSheet.swift>) и [SolveView.swift](<Leksipo/UI/Features/Solve/SolveView.swift>) — атомарное создание и оценка достижений; [SolveViewModel.swift](<Leksipo/UI/Features/Solve/SolveViewModel.swift>) — оценка достижений после изменения избранного в свободной тренировке; [AppContainer.swift](<Leksipo/App/AppContainer.swift>) — передача настроек и очистка всей очереди после восстановления. |
| Совместимость и откат | [BackupModels.swift](<Leksipo/Models/BackupModels.swift>) и [BackupService.swift](<Leksipo/Services/Backup/BackupService.swift>) — необязательные поля, валидация и восстановление дневного SRS-состояния; [PersistenceTransaction.swift](<Leksipo/Services/Persistence/PersistenceTransaction.swift>) — откат новых полей наблюдаемых моделей. |
| Локализация | [ru](<Leksipo/Resources/ru.lproj/Localizable.strings>) и [en](<Leksipo/Resources/en.lproj/Localizable.strings>) — импорт, правила SRS, состояния календаря и точные названия метрик. |
| Проверки | Новый [StudyWorkflowTests.swift](<Leksipo Tests/Persistence/StudyWorkflowTests.swift>) — 29 регрессионных тестов; [DataSafetyTests.swift](<Leksipo Tests/Persistence/DataSafetyTests.swift>) — подтверждение импорта и отдельные настройки; [MigrationSafetyTests.swift](<Leksipo Tests/Persistence/MigrationSafetyTests.swift>) и [PreSafetySchema.swift](<Leksipo Tests/Persistence/PreSafetySchema.swift>) — миграция прежней схемы и восстановление квоты/оценок после открытия новой базы; [SolveSessionCoordinatorTests.swift](<Leksipo Tests/Services/SolveSessionCoordinatorTests.swift>) — новая политика очереди и изоляция лимита. |

Совместимость: новые поля SwiftData имеют значения по умолчанию; новые поля DTO бэкапа и JSON сессии необязательны. Старые базы, бэкапы 2.9.0/формата 1 и сессии читаются. В старых данных число впервые введённых за день слов и будущая обязательная дата не сохранялись: недостающие сведения не выдумываются, дневной счётчик начинается с нуля, а старая сессия без даты пересобирается по расписанию. Исторические ответы, карточки и разблокированные достижения сохраняются.

Проверки:

- Приложение, виджет и тестовый target собраны; полный набор из 313 тестов прошёл на iPhone 17 Pro с iOS 26.4. Проверены дубль группы/карточки, новые связи, неудачный выбор файла, предпросмотр, ошибки сохранения и откат, дневной лимит, полночь, несколько пропущенных дней, изменение лимита, DST (23/25 часов), перенос бэкапа Tokyo → Los Angeles, старые форматы, повторное открытие дисковой базы, оценки/прогноз, изменение цели, пустые SRS-дни, история старше года и очередь наград.
- На отдельном временном симуляторе через `UIHostingController` проверены оборот SRS в обоих направлениях, детали частичного прогресса и календарь. Подтверждение импорта проверено снимком экрана симулятора. Временный код визуальной проверки удалён. Полный UI-прогон на iPad, Dynamic Type, VoiceOver и физическом устройстве не выполнялся.
- `plutil -lint` для обеих локализаций и `git diff --check` — без ошибок.

Финальная команда из корня проекта:

```sh
xcodebuild test -project 'Leksipo.xcodeproj' \
  -scheme 'Leksipo Tests' \
  -destination 'platform=iOS Simulator,id=0F7663D5-D9BE-4427-84AA-63BC840AEC4D' \
  -derivedDataPath /tmp/EnglishWordsReviewBuild \
  -resultBundlePath /tmp/EnglishWords-stage2-final2.xcresult \
  CODE_SIGNING_ALLOWED=NO
```

## Проверки виджета, напоминаний и перехода из виджета

3 ноября 2026 года закрыты INT-01–07 и INT-09. INT-08 оставлен для остальных ошибок локализации приложения; исправленная часть описана в нём отдельно.

Что изменено:

- Новый `SRSIntegrationService` обновляет снимок и расписание после успешного commit, на запуске, при активации/уходе в фон, системном изменении времени, смене языка/темы и лимита. События включают импорт, создание/удаление/изменение карточек, частичный SRS, сброс и восстановление. Вложенные операции публикуют одно зафиксированное состояние. Откат ничего не публикует; неизменившиеся данные не вызывают лишний reload виджета.
- Снимок имеет срок актуальности: не позже местной полуночи и шести часов после записи. Timeline заранее содержит состояние устаревания. Без открытия приложения вчерашнее «всё повторено» больше не выдаётся за сегодняшний результат. Пустая очередь, отсутствие снимка, устаревание и ошибка различаются; последняя корректная копия сохраняется при сбое чтения базы. Недоступный App Group явно считается ошибкой. Сбой записи виджета не блокирует напоминания, если данные базы успешно прочитаны.
- Напоминания выключены до выбора пользователя. В настройках доступны включение, местное время (по умолчанию 20:00), статус разрешения и переход в настройки iOS после отказа. Автоматический запрос разрешения во время onboarding удалён. Язык уведомления берётся из выбора приложения.
- План содержит до 32 отдельных будущих срабатываний, начиная с ближайшего дня с заданиями. Завершение сегодняшней очереди сохраняет напоминания о будущих назначениях. Уже прошедшее время пропускается; триггеры не фиксируют часовой пояс, а на активации и системной смене времени план пересчитывается. Без следующего открытия приложения расписание ограничено этими 32 срабатываниями. Это локальные уведомления, а не неограниченная фоновая синхронизация.
- Планирование выполняется последовательно с проверкой версии до и после асинхронных операций. Поздний `add` старого плана удаляется; отмена/новое время не могут быть перезаписаны старым callback. Удаляются только собственные идентификаторы SRS, включая прежний `daily_srs_reminder`.
- Зарегистрирован `englishwords://srs` в Info.plist приложения. `AppRouter` проверяет scheme/host/path/параметры и хранит маршрут до готовности UI, включая onboarding и восстановление запуска. После потребления маршрут очищается.
- Виджет применяет выбранные язык и тему, включая первоначальную запись ранее сохранённых настроек. Переведены также название и описание в галерее виджетов.

Файлы этого этапа:

| Область | Файлы |
| --- | --- |
| Синхронизация | Новый [SRSIntegrationService.swift](<Leksipo/Services/Widget/SRSIntegrationService.swift>), [SRSWidgetSnapshotWriter.swift](<Leksipo/Services/Widget/SRSWidgetSnapshotWriter.swift>), [PersistenceTransaction.swift](<Leksipo/Services/Persistence/PersistenceTransaction.swift>), [AppContainer.swift](<Leksipo/App/AppContainer.swift>). |
| Снимок и отображение | [SRSWidgetSnapshot.swift](<Leksipo/UI/Shared/SRSWidgetSnapshot.swift>), [SRSWidgetProvider.swift](<Leksipo Widgets/SRSWidgetProvider.swift>), [SRSWidgetEntryView.swift](<Leksipo Widgets/SRSWidgetEntryView.swift>), [SRSWidget.swift](<Leksipo Widgets/SRSWidget.swift>). Ключ хранилища v1 и прежние поля сохранены; новые поля optional. |
| Напоминания | Новый [SRSReminderPlan.swift](<Leksipo/Services/Notification/SRSReminderPlan.swift>), [NotificationService.swift](<Leksipo/Services/Notification/NotificationService.swift>), новый [ReminderSettingsView.swift](<Leksipo/UI/Features/Settings/Components/ReminderSettingsView.swift>), [SettingsView.swift](<Leksipo/UI/Features/Settings/SettingsView.swift>). |
| Запуск и маршрут | Новый [AppRouter.swift](<Leksipo/App/AppRouter.swift>), [LeksipoApp.swift](<Leksipo/App/LeksipoApp.swift>), [RootView.swift](<Leksipo/App/RootView.swift>), новый [Info.plist](<Leksipo/Info.plist>) и [project.pbxproj](<Leksipo.xcodeproj/project.pbxproj>). Настройки проекта изменены только для Info.plist/URL scheme и исключения plist из копирования ресурсов. |
| Удаление прежних частичных обновлений | [SettingsViewModel.swift](<Leksipo/UI/Features/Settings/SettingsViewModel.swift>) и [SRSViewModel.swift](<Leksipo/UI/Features/SRSSolve/SRSViewModel.swift>) больше не обновляют виджет и не отменяют напоминание отдельно от общей синхронизации. |
| Язык и тема | [LanguageManager.swift](<Leksipo/UI/Localization/LanguageManager.swift>), [ThemeManager.swift](<Leksipo/UI/Theme/ThemeManager.swift>), локализации приложения [ru](<Leksipo/Resources/ru.lproj/Localizable.strings>)/[en](<Leksipo/Resources/en.lproj/Localizable.strings>) и виджета [ru](<Leksipo Widgets/ru.lproj/Localizable.strings>)/[en](<Leksipo Widgets/en.lproj/Localizable.strings>). |
| Проверки | Новый [SRSIntegrationTests.swift](<Leksipo Tests/Persistence/SRSIntegrationTests.swift>) — 23 регрессионных теста. В [DataSafetyTests.swift](<Leksipo Tests/Persistence/DataSafetyTests.swift>) и [MigrationSafetyTests.swift](<Leksipo Tests/Persistence/MigrationSafetyTests.swift>) явно отключены системные интеграции тестовых AppContainer, чтобы не писать в App Group и не планировать реальные уведомления. |

Проверки:

- Полный набор: 336 тестов на iPhone 17 Pro с iOS 26.4. Проверены commit/rollback, импорт и частичный ответ, лимит, восстановление и удаление данных, недоступность общего контейнера, сохранение прежнего снимка, старый формат v1, полночь/срок актуальности/смена зоны, будущие даты, DST, включение/отказ/отмена и две гонки асинхронного планирования, сохранность чужих уведомлений, строгая проверка URL и отложенный маршрут.
- Проверен итоговый Info.plist собранного приложения: `CFBundleURLTypes` содержит `englishwords`. Общие файлы виджета остаются в target расширения; signing, entitlements, deployment targets и версии в проекте не изменялись.
- В отдельном временном симуляторе фактически установлен виджет. Проверены холодное нажатие на него после завершения процесса приложения, переход из уже работающего приложения и сохранение ссылки через onboarding. Во всех случаях открывается SRS.
- Обмен через App Group проверен отдельной локальной ad hoc сборкой: виджет показал серию 1, затем после добавления тестовой карточки — «К повторению: 1». При русской системе выбор English и синей темы в приложении отразился на домашнем виджете. Подписанная сборка необходима для настоящего App Group; сборка с `CODE_SIGNING_ALLOWED=NO` проверяет компиляцию/тесты, но не общий контейнер приложения и расширения.
- В UI проверены включение напоминаний, запрос разрешения только по этому действию, отказ и подсказка с переходом в iOS Settings. Реальная доставка уведомления по часам не ожидалась; планирование и отмена проверены управляемым клиентом, без отправки пользователю тестовых уведомлений. Проверка на физическом устройстве и полный UI-прогон всех размеров/категорий текста не выполнялись.
- `plutil -lint` для Info.plist и четырёх локализаций; `git diff --check` — без ошибок.

Команды из корня проекта:

```sh
xcodebuild test -project 'Leksipo.xcodeproj' \
  -scheme 'Leksipo Tests' \
  -destination 'platform=iOS Simulator,id=0F7663D5-D9BE-4427-84AA-63BC840AEC4D' \
  -derivedDataPath /tmp/EnglishWordsReviewBuild \
  -resultBundlePath /tmp/EnglishWords-stage3-final.xcresult \
  CODE_SIGNING_ALLOWED=NO

xcodebuild build -project 'Leksipo.xcodeproj' \
  -scheme 'Leksipo WidgetsExtension' \
  -destination 'platform=iOS Simulator,id=B98695EF-677A-42D6-9178-02B4BCB5B07B' \
  -derivedDataPath /tmp/EnglishWordsWidgetSignedBuild \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=-
```

UUID второго destination относится только к временному симулятору проверки; после завершения он удалён. Для повторения требуется выбрать доступный destination и новый путь результата тестов.

Исправления должны сохранять существующую архитектуру, формат пользовательских данных и несвязанные изменения. Сторонние зависимости, существенную перестройку, коммиты и отправку изменений согласовывать отдельно.
