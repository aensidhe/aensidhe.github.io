---
layout: post
title: ReadOnlySpan, ReadOnlySequence, C++
excerpt: When you long for С++ templates
categories: blog
lang: en
tags:
  - readonlyspan
  - readonlysequence
  - generics
  - templates
  - c++
author: aensidhe_2018
comments: true
---

There are two similar but different types in .net: [ReadOnlySpan&lt;T&gt;](https://docs.microsoft.com/en-us/dotnet/api/system.readonlyspan-1) и [ReadOnlySequence&lt;T&gt;](https://docs.microsoft.com/en-us/dotnet/api/system.buffers.readonlysequence-1). Former is an abstraction over continous array of elements of T that you can't change. Latter is chain from those arrays. Former is useful when you're writing code that accepts arrays: usual arrays, stack-allocated arrays (hello, stackalloc), arrays in unmanaged memory and so on. It has some overhead, which was discussed [earlier]({% post_url blog/en/2018-08-13-know what are you going to benchmark %}).

`ReadOnlySequence<T>`, on my opinion, is most useful when you have some network IO, because when you expect million (or even thousand) of 64bit integers from network, you can't assume that you'll get that numbers in one batch. I mean, you can assume, but it won't be that way everytime. In most cases, you'll get chain of buffers.

I try to write library which will be useful in both cases. And we stumble upon particular weakness of C#: we need to write same method twice. Look to excerpt, full code is [here](https://gist.github.com/aensidhe/439d801227a6b25bad062493da97901b).

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

We have problems:

- Both types are structs. They don't implement any interfaces, so, we can't write any common code for some `IReadOnlyCollection<T>`.
- We can't make this code generic, because `ReadOnlySpan<T>` is special stack-only struct, which can't be type parameter of generic method.
- We can't create `ReadOnlySequence<T>` from `ReadOnlySpan<T>` without copy, because `ReadOnlySequence<T>` is not made from spans, it is made from `ReadOnlyMemory<T>` which is similar to Span, but not stack-only, and creating memory from span involves copying.
- We can't change signature `Read` by replacing `ReadOnlySpan<T>` by `ReadOnlyMemory<T>`, because they're different. `ReadOnlyMemory<T>` can't be used to work with unmanaged memory or stack-allocated array. So, `ReadOnlySpan<T>` can represent a lot more arrays.
- You can't represent sequence by span for obvious reasons.

I don't see any solution to that problem, except duplicating code. I remember when we have good old C++, when you can do this (thanks, [Yauheni Akhotnikau](https://eao197.blogspot.com/) for corrected code):

{% highlight c++ %}
template<class TElement>
class Parser {
private:
  const IMsgPackParser<TElement> elementParser_;

  template<template<class> Container>
  void Read(const Container<byte> & source, Span<TElement> & array, size_t & readSize) {
    for(size_t i = 0u; i != array.Length(); ++i) {
      size_t temp;
      array[i] = elementParser_.Parse(source.Slice(readSize), temp);
      readSize += temp;
    }
  }
};
{% endhighlight %}
