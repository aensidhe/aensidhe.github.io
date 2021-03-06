---
layout: post
title: Давайте мы добавим в табличку колонку. Это же просто!
excerpt: Как нам добавить колонку и индекс в Tarantool?
categories: blog
comments: true
lang: ru
tags:
  - tarantool
  - ddl
  - always on service
---

Время от времени приходится добавлять новые колонки и индексы в уже существующие базы данных. Обычно сделать это просто:
{% highlight sql %}
alter table MyTable add NewColumn int null
{% endhighlight %}

Если у нас MS Sql Server 2012+, то мы можем добавить даже колонку без null:

{% highlight sql %}
alter table MyTable add NewColumn int not null default(0)
{% endhighlight %}

Если у нас no-sql, например, [Tarantool](https://tarantool.org/), делать ничего не надо. Каждый кортеж может содержать произвольное количество элементов. Замечательно? И да, и нет. Недостатки проявляются потом, когда вы пытаетесь добавить индекс на эту новую колонку. Код ниже сработает и на nullable колонках, и на не nullable:
{% highlight sql %}
create index MyIndex on MyTable(NewColumn)
{% endhighlight %}

В Тарантуле всё немного сложнее. Вы не сможете добавить индекс, испольщующий i-ю колонку, на space до тех пор, пока все кортежи в спейсе не будут иметь значение в i-й колонке. Казалось бы мелочи, но на самом деле нет. Это усложняет в некоторых случаях разработку и развёртывание. Мы теперь должны действовать по плану:

1. Пишем код, который пишет в новую колонку и умеет работать с её отсутствием.
2. Дотаскиваем его до продакшена.
3. Параллельно можем писать утилиту, которая проставит всем туплам в i-ю колонку какое-нибудь значение.
4. Запускаем её на продакшене.
5. Создаём на продакшене индекс.
6. Деплоим код, который использует индекс.

В классических СУБД мы можем действовать также, а можем по-другому:
1. Создаём колонку и индекс
2. Деплоим код, который использует индекс, который умеет работать с null/дефолтным значением.
3. Параллельно пишем утилиту, как и выше.
4. Запускаем утилиту в бэкграунде.

Да, не всегда этот короткий вариант хорош и может быть применён. Но мы имеем выбор: первый вариант или второй. В случае с Tarantool у вас нет выбора. Даже если вы можете дешёво написать код, который работает с дефолтным значением поля, или у вас просто мало данных, вам всё равно надо работать по длинному варианту, если вы не можете положить продакшен в оффлайн.

За всё надо платить, в том числе и за скорость. В данном случае мы платим удобством.
