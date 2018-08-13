---
layout: post
title: Know what are you going to benchmark
excerpt: or how compilers trick developer
categories: blog
lang: en
tags:
  - msgpack
  - progaudi
  - gcc
  - .net core
  - jit
  - benchmark
author: aensidhe_2018
comments: true
---

In [previous post]({{ site.baseurl }}{% post_url /blog/2018-08-03-не-думай-о-секундах-свысока %}) I decsribed process of benchmarking of my library and how I stumbled upon interesting issue about slowness of code with subtraction. I even opened an [issue](https://github.com/dotnet/coreclr/issues/19355). And [@mikedn](https://github.com/mikedn) reminded me very about very important and interesting thing: know what are you going to benchmark. The bigger and more complex your benchmark is, it becomes more and more likely that you'll measure something else, not what you wanted. E.g. people measure .net GC in this [issue](https://github.com/progaudi/progaudi.tarantool/issues/127) mostly, not the actual code of driver.

And I got bitten by the same thing. Almost the same. You can see results of better designed [benchmark](https://github.com/aensidhe/dotnet-core-minus-regression/blob/minus-benchmark/reproduction/Program.cs) below:

   Method |     Mean |    Error |   StdDev |       Q3 | Scaled | ScaledSD | Allocated |
--------- |---------:|---------:|---------:|---------:|-------:|---------:|----------:|
     Span | 378.8 ns | 6.778 ns | 6.340 ns | 385.2 ns |   2.01 |     0.04 |       0 B |
SpanConst | 198.7 ns | 1.255 ns | 1.174 ns | 199.5 ns |   1.06 |     0.02 |       0 B |
  Pointer | 235.5 ns | 4.583 ns | 4.501 ns | 237.6 ns |   1.25 |     0.03 |       0 B |
        C | 188.1 ns | 2.714 ns | 2.538 ns | 190.3 ns |   1.00 |     0.00 |       0 B |
      Cpp | 189.5 ns | 2.896 ns | 2.709 ns | 191.5 ns |   1.01 |     0.02 |       0 B |

Here `Span` and `SpanConst` benchmark serialize one hundred ints using same code, based on `Span&lt;T&gt;`, former is using some diffrents integers and latter is using constant. Others retain their names from previous post.

Lets set aside `SpanConst` for a moment. `Span` result became slower a little, but other became slower a lot, around two times. Why is that? Previous benchmark was about serializing some `num`, where `num ∈ [1<<30 - 100, 1<<30]`. And new one takes numbers from 99000 till 0 with 1000 step. Now we're going to look onto `mp_encode_uint` method of [msgpuck](https://github.com/rtsisyk/msgpuck/blob/3b8f3e59b62d74f0198e01cbec0beb9c6a3082fb/msgpuck.h#L1378). Methods in other libraries look similar.

{% highlight c %}
MP_IMPL char *
mp_encode_uint(char *data, uint64_t num)
{
    if (num <= 0x7f) {
        return mp_store_u8(data, num);
    } else if (num <= UINT8_MAX) {
        data = mp_store_u8(data, 0xcc);
        return mp_store_u8(data, num);
    } else if (num <= UINT16_MAX) {
        data = mp_store_u8(data, 0xcd);
        return mp_store_u16(data, num);
    } else if (num <= UINT32_MAX) {
        data = mp_store_u8(data, 0xce);
        return mp_store_u32(data, num);
    } else {
        data = mp_store_u8(data, 0xcf);
        return mp_store_u64(data, num);
    }
}
{% endhighlight %}

In old benchmark GCC 6.0 was able to find out that `num ∈ [1<<30 - 100, 1<<30]` even for non-const integer and to eliminate all code, except one branch. In .net core JIT was able to do the same, but only for constant integer. In other cases JIT generated full code with all branches. So, "slow code" was actual code" and "fast" one was an anomaly tied to an ability of compilers eliminate dead code. Developer should take this into account during designing of benchmark. E.g. `SpanConst` here is for illustrating elimination of code and proving hypothesis that jit and gcc eliminate code here.
