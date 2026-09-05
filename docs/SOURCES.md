# Первичные источники и границы их использования

[Карта](DESIGN.md). Проверено 6 сентября 2026. Источники подтверждают свойства инструментов, описание референса и условия поставщиков. Сюжет, существа, игровые правила и бюджеты GUESTS — авторские проектные предложения, не утверждения этих источников.

## Художественный ориентир

**V01. [VHOLUME — официальная страница Steam](https://store.steampowered.com/app/4131730/VHOLUME/).** Подтверждает описание игры как приключения от первого лица в мрачном бруталистском городе с бюрократической темой. Для GUESTS используется художественная отправная точка, не право копировать уровни, персонажей или файлы. Мы не переносим паркур референса в жанровую основу GUESTS.

**V02. Пользовательский скриншот в текущем обсуждении.** Наблюдения: тяжёлые бетонные объёмы, маленькие окна, пустые переходы, редкие световые акценты. Происхождение изображения отдельно не установлено. Его файл не включён в публичный репозиторий/ассеты или распространяемую документацию. Ролики К.О.Н.Т.У.Р. используются как обсуждавшаяся атмосфера, не как лицензированный исходный материал.

## Ассеты и лицензии

**A01. [Kenney Furniture Kit](https://kenney.nl/assets/furniture-kit) и [Kenney Support](https://kenney.nl/support).** Страница и FAQ подтверждают CC0 для соответствующих игровых ассетов. Фактически включённые шесть файлов и хэши находятся в `assets/manifest.json` исходного проекта; версия архива проверяется по его License.txt.

**A02. [Kenney City Kit Industrial](https://kenney.nl/assets/city-kit-industrial).** CC0-кандидат для индустриальных деталей и фона; в эту документационную задачу новые модели не импортированы.

**A03. [Poly Haven License](https://polyhaven.com/license).** CC0 относится к assets. Страница также различает лицензии материалов и остальных элементов сайта и ограничивает массовый сбор сайта. Кандидаты: [Concrete](https://polyhaven.com/a/concrete), [Concrete Wall 003](https://polyhaven.com/a/concrete_wall_003). Скачивание и хэширование конкретного файла — отдельная будущая операция.

**A04. [ambientCG License](https://docs.ambientcg.com/license/).** Подтверждает CC0 для ассетов. Кандидаты: [Plaster007](https://ambientcg.com/view?id=Plaster007), [Metal022](https://ambientcg.com/view?id=Metal022). Названия не означают художественного утверждения или уже сделанного импорта.

**A05. [Quaternius](https://quaternius.com/) и [Modular Sci-Fi Megakit](https://quaternius.com/packs/modularscifimegakit.html).** Подтверждают CC0 у указанного набора и различие объёма бесплатной/расширенной/source комплектации. Не считать, что бесплатный вариант содержит весь коммерческий Source-пакет и `.blend`.

**A06. [OpenGameArt FAQ](https://opengameart.org/content/faq).** Использование определяется лицензией конкретной работы и требованиями атрибуции. У сайта нет одной универсальной CC0-лицензии на все загрузки.

**A07. [Freesound FAQ](https://freesound.org/help/faq/).** Лицензии отличаются; отдельные записи требуют атрибуции или не подходят для коммерческого использования. Страница описывает необходимость аккаунта для обычного скачивания. Наличие файла на платформе не гарантирует права на случайную фоновую музыку.

**A08. [Creative Commons — виды лицензий](https://creativecommons.org/cc-licenses/).** Основа для различий BY, SA, NC и ND. Строгий allowlist GUESTS — внутренняя производственная политика, не универсальная юридическая консультация. Неясные материалы не включаются до отдельной проверки.

## Техническая основа

**G01. [Godot — High-level multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html).** Высокоуровневый multiplayer, RPC, ENet и ограничения прямого подключения. Не подтверждает, что GUESTS уже имеет готовый игровой онлайн.

**G02. [Godot — Resources](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html).** Resources как контейнеры данных и разделение загруженных ресурсов. Архитектура отдельного изменяемого state — решение GUESTS.

**G03. [Godot — Background loading](https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html).** Фоновая загрузка ресурсов; правила ready-barrier, отмены и состава сессии разработаны для нашего проекта.

**G04. [Godot — Overview of renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).** Различия Compatibility/Mobile/Forward+. Текстуры, бюджеты и художественный пресет в GUESTS являются целями тестирования.

**G05. [Godot — Available 3D formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html).** Поддержка glTF/GLB и особенности импорта `.blend` через Blender.

**G06. [Godot — Troubleshooting physics issues](https://docs.godotengine.org/en/stable/tutorials/physics/troubleshooting_physics_issues.html).** Ограничения масштабирования физических форм; целевая деформация персонажей отделена от коллизий.

**G07. [Godot — Audio buses](https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html).** Основа для шин и микса. Перечень шин, cue-ID и правила доступности — наш дизайн.

Ссылки `/stable/` со временем меняются. Наличие новой возможности в актуальной документации не разрешает обновлять закреплённый движок без задачи миграции. Конкретное API проверяется на бинарнике из `.godot-version` и в CI.

## Фактический исходный код

Базовый [коммит GUESTS 39b90c3](https://github.com/T-Damer/guests/tree/39b90c3d08b13d7891a71ced6a63f6792e961b08) и [PR #1](https://github.com/T-Damer/guests/pull/1). Код/конфигурация определяют реализованные возможности. Сведения о старых проверках относятся к их SHA; новый документ не распространяет результаты на ещё не реализованные меню, хаб, планшет или кооперативный цикл.
