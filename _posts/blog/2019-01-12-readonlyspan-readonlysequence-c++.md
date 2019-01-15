---
layout: post
title: ReadOnlySpan, ReadOnlySequence, C++
excerpt: Или когда ты плачешь по шаблонам из С++
categories: blog
lang: ru
tags:
  - readonlyspan
  - readonlysequence
  - generics
  - templates
  - c++
author: aensidhe_2018
comments: true
---

В .net есть два типа: [ReadOnlySpan&lt;T&gt;](https://docs.microsoft.com/en-us/dotnet/api/system.readonlyspan-1) и [ReadOnlySequence&lt;T&gt;](https://docs.microsoft.com/en-us/dotnet/api/system.buffers.readonlysequence-1). Первый представляет собой абстракцию над неизменяемым непрерывным массивом из элементов T, второй - цепочку из подобных отрезков. Первый удобен, когда вам надо написать метод, оперирующий над а-ля массивами, которые могут быть: обычными массивами, массивами на стеке (привет, stackalloc), массивами в неуправляемой памяти и так далее. Его оверхед я рассматривал [ранее]({% post_url blog/2018-08-13-know what are you going to benchmark %}).

`ReadOnlySequence<T>` же чаще всего (на мой взгляд) полезен там, где у нас есть чтение из сети, потому что если вам по сети едет один миллион (или хотя бы тысяча) 64-битных чисел, вряд ли они приедут к вам одной пачкой. Надеяться можно, но это далеко не всегда так. Чаще всего это будет какая-то цепочка из буферов.

Я пытаюсь написать библиотеку, которой будет удобно пользоваться для обоих случаев и тут мы натыкаемся на то, что надо писать два раза один и тот же код, но для разных типов. Ниже будет выдержка, полный код [тут](https://gist.github.com/aensidhe/439d801227a6b25bad062493da97901b).

{% highlight csharp %}
private readonly IMsgPackSequenceParser<TElement> _elementSequenceParser;
private void Read(ReadOnlySequence<byte> source, Span<TElement> array, ref int readSize)
{
    for (var i = 0; i < array.Length; i++)
    {
        array[i] = _elementSequenceParser.Parse(source.Slice(readSize), out var temp);
        readSize += temp;
    }
}

private readonly IMsgPackParser<TElement> _elementParser;
private void Read(ReadOnlySpan<byte> source, Span<TElement> array, ref int readSize)
{
    for (var i = 0; i < array.Length; i++)
    {
        array[i] = _elementParser.Parse(source.Slice(readSize), out var temp);
        readSize += temp;
    }
}
{% endhighlight %}

И у нас есть проблемы:

- Оба типа являются структурами, которые не реализуют никаких интерфейсов, следовательно, мы не можем написать общий код для какого-то `IReadOnlyCollection<T>`.
- Мы не можем сделать код generic, потому что `ReadOnlySpan<T>` - это специальная stack-only структура, которая не может быть типом-параметром генерик-метода.
- Мы не можем создать `ReadOnlySequence<T>` из `ReadOnlySpan<T>` без копирования, потому что `ReadOnlySequence<T>` состоит не из спанов, а из `ReadOnlyMemory<T>`, которая похожа на Span, но не stack-only и создание памяти из отрезка - это копирование.
- Нельзя заменить в сигнатуре `Read` `ReadOnlySpan<T>` на `ReadOnlyMemory<T>`, потому что они разные. `ReadOnlyMemory<T>` не может использоваться для работы с неуправляемой памятью или массивами на стеке, а `ReadOnlySpan<T>` - может, т.е. он может представить гораздо больше "массивов" единообразно.
- Цепочку из нескольких буферов тоже нельзя представить в виде одного указателя и длины (чем является `ReadOnlySpan<T>`) без копирования по понятным причинам.

Я пока не вижу другого способа, кроме как дублировать код. Вспоминается старый добрый С++, в котором можно было бы (если мне не изменяет память) сделать примерно вот так:
{% highlight c++ %}
template<typename TContainer>
template<typename TElement>
class Parser
{
    private const IMsgPackParser<TElement> _elementParser;
    private void Read(const TContainer<byte>& source, Span<TElement>& array, int& readSize)
    {
        for (var i = 0; i < array.Length; i++)
        {
            int temp;
            array[i] = _elementParser.Parse(source.Slice(readSize), temp);
            readSize += temp;
        }
    }
}
{% endhighlight %}
