---
layout: post
title: Let's add column to table. It's simple, yes?
excerpt: Как нам добавить колонку и индекс в Tarantool?
categories: blog
comments: true
lang: en
tags:
  - tarantool
  - ddl
  - always on service
---

From time to time we need to add columns to our tables. Usually it's quite simple:
{% highlight sql %}
alter table MyTable add NewColumn int null
{% endhighlight %}

If we use MS Sql Server 2012+, we can get nonnullable column:

{% highlight sql %}
alter table MyTable add NewColumn int not null default(0)
{% endhighlight %}

But if we use nosql, like [Tarantool](https://tarantool.org/), we should do nothing, because every tuple can have any number of items. Neat, right? Let's try to add an index. If we're using traditional databases, this will work regardless of nullability of column:

{% highlight sql %}
create index MyIndex on MyTable(NewColumn)
{% endhighlight %}

It's more difficult in Tarantool. You can't create an index on i-th column until all tuples of space will have some value in it. And in some cases it really hinders development and deploy. You should:

1. Write code that will write new value to i-th column. Read part should be able to work without it.
2. Deploy it to production.
3. Concurrently you can write a migration tool, that will set some value to i-th column.
4. Deploy and run it on production.
5. Create an index on production.
6. Deploy read code that rely on that index.

In some cases you should do the same even if you're using classic DB, but you can choose another way:
1. Create column and index.
2. Deploy code that can work with default value.
3. Write a migration tool.
3. Deploy and run it on background.

Of course, you can't use this shortcut everytime. But you have an option of it, which you don't in case of Tarantool. Even if it's simple and easy to write a code that can use default value, or you just don't have so much data to even bother with length of migration, you are forced to use longer option with several deploys. Unless you can go offline for some time, of course.

Everything has its price, especially speed. Sometime it's an ease of schema modifications.
