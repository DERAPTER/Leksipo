# Переименование в Leksipo

Название приложения — **Leksipo** (Лексипо), маскота — **Лекси**.

Проект: `Leksipo.xcodeproj`. Исходники находятся в `Leksipo`, `Leksipo Tests` и `Leksipo Widgets`. Targets, продукты и общие схемы переименованы в Leksipo. Внешняя папка проекта — `/Users/egorhalikov/Desktop/Swift/Leksipo`.

## Совместимость

Следующие технические имена намеренно сохранены:

| Имя | Причина |
| --- | --- |
| `DERAPTER.English-Words` | Bundle ID установленного приложения и доступ к его данным |
| `DERAPTER.English-Words.English-Words-Widgets` | Идентичность существующего расширения виджета |
| `DERAPTER.English-Words-Tests` | Bundle ID тестового target |
| `group.com.DERAPTER.English-Words` | Общий контейнер приложения и виджета |
| `English_Words` | Swift-модуль моделей: сохранён через `PRODUCT_MODULE_NAME`, чтобы не менять пространство имён SwiftData; используется в `@testable import` |
| `english_words_data.json` | Поиск старого файла при миграции пользовательских данных |
| `englishwords://srs` | Поддержка прежних ссылок и установленных виджетов |

Основная новая ссылка — `leksipo://srs`. Обе схемы проходят одинаковую проверку адреса. Новые резервные копии получают префикс `Leksipo_Backup_`; формат JSON, модели SwiftData, UUID и ключи настроек не меняются.

GitHub-репозиторий: [DERAPTER/Leksipo](https://github.com/DERAPTER/Leksipo). Локальный `origin` указывает на `https://github.com/DERAPTER/Leksipo.git`. Исторические пути к результатам проверок в `/tmp` в `TODO.md` сохранены; ссылки на исходники и проект обновлены.

## Проверки переименования

- `xcodebuild -list -project Leksipo.xcodeproj` и `-showdestinations` для схемы `Leksipo Tests`: проект, targets и схемы распознаны.
- Сборка приложения и виджета: `xcodebuild -project Leksipo.xcodeproj -scheme 'Leksipo WidgetsExtension' -configuration Debug -destination 'platform=iOS Simulator,id=0F7663D5-D9BE-4427-84AA-63BC840AEC4D' -derivedDataPath /tmp/leksipo-rename-build CODE_SIGNING_ALLOWED=NO build` — успешно, без предупреждений.
- Тесты: `xcodebuild -project Leksipo.xcodeproj -scheme 'Leksipo Tests' -destination 'platform=iOS Simulator,id=0F7663D5-D9BE-4427-84AA-63BC840AEC4D' -derivedDataPath /tmp/leksipo-rename-build -resultBundlePath /tmp/leksipo-rename-tests.xcresult CODE_SIGNING_ALLOWED=NO test` — 336 тестов в 16 наборах прошли.
- Проверены XML схем, plist и entitlements, обе локализации приложения и виджета. Bundle ID и содержимое entitlements сверены с состоянием до переименования.
- В готовом приложении `CFBundleDisplayName`, `CFBundleName` и `CFBundleExecutable` равны `Leksipo`; зарегистрированы обе URL-схемы.
- Приложение установлено и запущено в отдельном временном iPhone 17 Pro / iOS 26.4 Simulator; экран onboarding проверен визуально. Обе ссылки открывают приложение через `simctl openurl`. После проверки временный симулятор удалён.

Старый пакет `English Words.xcodeproj`, повторно созданный Xcode и содержащий только служебное состояние workspace без `project.pbxproj`, удалён. Его служебные файлы сохранены в `/tmp/leksipo-old-xcode-workspace-state.zip`.

После переименования внешней папки сверено содержимое всех 2277 файлов (SHA-256) и неизменность состояния Git. Повторная сборка приложения и виджета из `/Users/egorhalikov/Desktop/Swift/Leksipo` через схему `Leksipo WidgetsExtension`, Debug, iPhone 17 Pro / iOS 26.4, с `-derivedDataPath /tmp/leksipo-folder-rename-build CODE_SIGNING_ALLOWED=NO build` завершилась успешно без предупреждений. `git ls-remote origin HEAD` подтвердил доступ к новому адресу и прежний HEAD `34048bbe7e74a79e8e6a3a75ea10f6215d52788e`. Единственный пакет проекта в корне — `Leksipo.xcodeproj`.
