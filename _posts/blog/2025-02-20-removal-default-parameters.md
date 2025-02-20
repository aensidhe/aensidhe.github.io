---
layout: post
title: Был параметр и нет
excerpt: а у вас автоматизация отклеилась
categories: blog
comments: true
lang: ru
author: aensidhe_2025
tags:
  - работа
  - rust
  - ux
---

Мы на работе используем [rust](https://www.rust-lang.org/), и он постоянно развивается и это, наверно, хорошо. В общем, к делу. Локально у каждого разработчика какая-то своя операционка, а на Gitlab корпоративном, в раннере какая-то конкретная. И некоторые баги локально не повторяются, а в Gitlab'e повторяются. Поэтому в Makefile есть такая задача:

```make
ifndef BUILD_TARGET
	BUILD_TARGET=debug
endif

docker_rocky_build:
	rm -f ./lib.so
	docker buildx build --ssh default=$$SSH_AUTH_SOCK --progress plain . -t test -f Dockerfile.rocky.local.build
	docker run --rm --entrypoint cat test /build/target/{BUILD_TARGET}/lib.so > ./lib.so
```

В докерфайле было тоже тупо:

```Dockerfile
FROM ...

ARG BUILD_TARGET
ENV BUILD_TARGET=${BUILD_TARGET}

...

RUN --mount=type=ssh cargo build --${BUILD_TARGET}
```

Ну и надо собрать отладочную сборку делаешь `make docker_rocky_build`, надо релизную делаешь `make docker_rocky_build BUILD_TARGET=release`.

То есть, запускаешь отладочную сборку, мы передаём `debug` параметров в докер, достаём файл из папки `debug`. Надо `release` - соответственно аналогично, достаёшь библиотеку из папки `release`.

И вот в одной из каких-то последних версий `cargo`, сборочного инструмента для `rust`, выпилили ключик `--debug`, потому что ну типа по умолчанию же отладочная сборка. С одной стороны логично, с другой стороны теперь где-то надо пилить всякие условные операторы и переключения в сборочных скриптах.

Как решил эту проблему? Да очень просто, теперь просто собираем релизную сборку, а надо будет дебажную - ну, будет страдать.
