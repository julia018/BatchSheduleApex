Data model:
1. на Орге существует иерархия аккаунтов.
2. Parent поле на объекте Account указывает на родителя в иерархии
3. Иерархия аккаунтов может включать в себя до 6 уровней включительно
4. Для любого аккаунтa в иерархии может быть создана запись в объекте Opportunity

Задача:
1. Рассчитать Total Amount для каждого из аккаунтов в иерархии. Сумма должна включать в себя:
        a. Сумму поля Amount на объекте Opportunity для всех записей относящихся к Аккаунту. При этом Opportunity Status должен быть Closed/Won
        b. Сумму Total Amount для аккаунтов находящихся ниже в иерархии.
2. Каждую неделю в пятницу вечером Total Amount на всех аккаунтах должен быть пересчитан.
3. Написать Unit tests для реализации с тестированием сценариия при котором у нас есть все 6 уровней иерархии.

Реализация:
1. создать batch job для подсчета Total Amount
2. создать schedule job для запуска расчетов
3. создать необходимые поля на объектах
