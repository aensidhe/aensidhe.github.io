---
layout: post
title: Неофициальный докер-образ для Tarantool
excerpt: Даёшь тег в докер хабе на каждый пакет тарантула!
categories: blog
lang: en
tags:
  - tarantool
  - progaudi
  - docker
  - announce
comments: true
---

Earlier ([here is translation of my article](https://medium.com/@Vadim.Popov/tarantool-as-main-data-storage-for-net-server-apps-43dad4bdd8bc) by Vadim Popov) I mentioned that, if you look to some tag in [official Tarantool repository](https://github.com/tarantool/docker/), you can't say what build number is. E.g. until recently tag 1.7 contained build 1.7.5-0-g24b70de10. Now it has 1.7.5-250-g8c55b4993. Such slow update speed is good if you want only stable solutions: official image is updated only when Tarantool team is sure that everything is good.

But if you're using [packages](https://packagecloud.io/tarantool/), you have much more opportunities. Every commit in main branches is built by travis into a package and uploaded to packagecloud. You can choose exact build and use it. Or update to latest every single day. Your choice.

I build an unofficial image which will be built same way as packages: every commit in main branch. Also, I'll update tags of minor and major version. Let's see: we are going to build commit [300bc7dac](https://github.com/tarantool/tarantool/commit/300bc7daccfc8ae3ace5a064ba190a7d3b9787be) from branch 1.7. Build number will be `1.7.5-257-g300bc7dac`, minor version is `1.7.5`, major - `1.7`. All those tags will be updated. You can choose granularity of updates in your datacenter.

Additionally, all packages in image were updated to latest versions, luautf8 is added today. All future build of 1.7 and 1.8 will contain it. We merge any changes in [upstream](https://github.com/tarantool/docker/) as fast as we can, usually in 24 hours, but it is not a guaranteed. If you have any questions, leave them in comments or [issue tracker](https://github.com/progaudi/tarantool-docker/issues).

Finally, there is `1.7.5-0-g24b70de10` tag for seamless transition from old official 1.7 image.