# 1C-Bitrix: Архитектура платформы

*Обновлено: 2026-03-21*

---

## Два ядра: Legacy vs D7

| Характеристика | Legacy (старое ядро) | D7 (новое ORM-ядро) |
|---|---|---|
| Стиль кода | Процедурный + глобальные функции | Объектно-ориентированный (ООП) |
| Доступ к БД | `CIBlock`, `CSaleOrder`, `CUser` | `IblockTable::getList()`, DataManager |
| Namespace | Нет | `Bitrix\Main\`, `Bitrix\Iblock\`, `Bitrix\Sale\` |
| ORM | Нет | Entity DataManager |
| Статус | Устаревает (adapter-слой) | Рекомендован для нового кода |
| Пример | `$res = CIBlockElement::GetList(...)` | `$res = ElementTable::getList(...)` |

**Правило:** весь новый код пишется на D7. Legacy-код трогать только при крайней необходимости.

---

## Структура директорий

```
/www/                           ← корень сайта (document root)
├── bitrix/                     ← ЯДРО BITRIX. Никогда не редактировать вручную.
│   ├── modules/                ← стандартные модули (main, iblock, sale, catalog, ...)
│   ├── components/             ← стандартные компоненты
│   ├── templates/              ← стандартные шаблоны компонентов
│   ├── php_interface/          ← init.php (глобальная инициализация — лучше не трогать)
│   └── admin/                  ← административная панель
│
├── local/                      ← ВЕСЬ КАСТОМНЫЙ КОД. Только сюда.
│   ├── components/             ← кастомные компоненты
│   ├── modules/                ← кастомные модули
│   ├── templates/              ← шаблоны сайта + переопределения компонентов
│   ├── php_interface/
│   │   ├── init.php            ← главный init (EventHandler, подключение зависимостей)
│   │   └── dbconn.php          ← конфиг БД (НЕ в git!)
│   └── classes/                ← кастомные классы (если не модуль)
│
├── upload/                     ← загруженные файлы (НЕ в git, большой объём)
│   ├── iblock/                 ← файлы инфоблоков
│   └── resize_cache/           ← кеш ресайза изображений
│
├── .htaccess                   ← конфиг Apache (или nginx.conf отдельно)
└── index.php                   ← точка входа
```

**Правило git:** в репозитории хранится только `local/` + `.htaccess` + `index.php` + публичные файлы. Папки `bitrix/` и `upload/` добавляются в `.gitignore`.

---

## Компоненты (MVC-паттерн Bitrix)

```
/local/components/
└── vendor.name/               ← namespace.name (например: my.catalog)
    ├── component.php          ← Controller (бизнес-логика, запросы к БД)
    ├── .parameters.php        ← параметры компонента (для визуального редактора)
    └── templates/
        └── .default/          ← шаблон по умолчанию
            ├── template.php   ← View (HTML + PHP)
            ├── result_modifier.php  ← постобработка $arResult перед template
            ├── style.css
            └── script.js
```

### Переопределение стандартного компонента

Чтобы изменить стандартный компонент без правки ядра, скопировать шаблон:
```
/local/templates/<шаблон_сайта>/components/bitrix/<имя.компонента>/.default/template.php
```
Bitrix сначала ищет шаблон в `local/`, затем в `bitrix/`.

---

## Модули (Module API)

Структура модуля:
```
/local/modules/vendor.module/
├── include.php                ← AutoLoader подключения, EventManager регистрация
├── install/
│   ├── index.php              ← Класс установки/удаления модуля (DoInstall/DoUninstall)
│   ├── db/
│   │   └── mysql/install.sql  ← SQL для создания таблиц
│   └── step.php               ← Если установка многошаговая
├── lib/                       ← Основной код (D7 DataManager, классы)
│   └── my.php
└── lang/
    ├── ru/                    ← Переводы
    └── en/
```

Установка: `/bitrix/admin/module_admin.php`

---

## Система событий (EventManager)

```php
// Подписка на событие (в init.php или include.php модуля)
\Bitrix\Main\EventManager::getInstance()->addEventHandler(
    'sale',           // модуль-источник события
    'OnSaleOrderSaved', // имя события
    ['\Vendor\Module\Handler', 'onOrderSaved']  // callback
);

// Класс-обработчик
class Handler {
    public static function onOrderSaved(\Bitrix\Main\Event $event) {
        $order = $event->getParameter('ENTITY');
        // логика
    }
}
```

Стандартные события: `OnAfterUserAdd`, `OnSaleOrderSaved`, `OnBeforeIBlockElementAdd`, `OnIBlockPropertyBuildList`

---

## ORM Data Manager (D7)

```php
use Bitrix\Main\ORM\Data\DataManager;
use Bitrix\Main\ORM\Fields;

// Определение сущности
class MyTable extends DataManager
{
    public static function getTableName() { return 'my_custom_table'; }

    public static function getMap() {
        return [
            new Fields\IntegerField('ID', ['primary' => true, 'autocomplete' => true]),
            new Fields\StringField('NAME', ['required' => true]),
            new Fields\DatetimeField('CREATED_AT'),
        ];
    }
}

// Использование
$result = MyTable::getList([
    'filter' => ['=ACTIVE' => 'Y'],
    'select' => ['ID', 'NAME'],
    'order'  => ['ID' => 'DESC'],
    'limit'  => 10,
]);

MyTable::add(['NAME' => 'Test']); // insert
MyTable::update(1, ['NAME' => 'Updated']); // update
MyTable::delete(1); // delete
```

---

## Кеширование

Bitrix имеет несколько уровней кеширования:

| Тип | Использование | Класс |
|-----|--------------|-------|
| Managed Cache | Кеш по тегам (инфоблоки, компоненты) | `Bitrix\Main\Data\Cache` |
| HTML Cache | Кеш HTML-вывода компонента | параметр `CACHE_TIME` компонента |
| Composite Site | Кеш всей страницы, замена динамических блоков | `bitrix:main.include` |
| OPcache | PHP-уровень (настраивается в php.ini) | — |
| Redis/Memcache | Бэкенд для Managed Cache | `.settings.php` |

```php
// Пример Managed Cache
$cache = \Bitrix\Main\Data\Cache::createInstance();
if ($cache->initCache(3600, 'my_cache_id', '/my/path/')) {
    $data = $cache->getVars();
} elseif ($cache->startDataCache()) {
    $data = expensiveQuery();
    $cache->endDataCache($data);
}
```

---

## Агенты (CAgent) — фоновые задачи

Периодические задачи регистрируются как агенты:
```php
// Регистрация агента
\CAgent::AddAgent(
    '\Vendor\Module\Agent::run();',  // имя функции (должна возвращать себя!)
    'vendor.module',
    'N',      // не каждый хит
    3600,     // интервал в секундах
    '',       // дата первого запуска (пусто = сразу)
    'Y',      // активен
);

// Сама функция
static function run() {
    // логика
    return '\Vendor\Module\Agent::run();'; // обязательно вернуть себя!
}
```

Просмотр агентов: `/bitrix/admin/agent_list.php`
