---
layout: page
title: Blog
excerpt: All stories sorted by date desc
search_omit: true
permalink: /blog/
lang: en
---

{% assign posts=site.categories.blog | where:"lang", page.lang %}

<ul class="post-list">
{% for post in posts %}
  <li><article><a href="{{ site.url }}{{ post.url }}">{{ post.title }} <span class="entry-date"><time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%B %d, %Y" }}</time></span>{% if post.excerpt %} <span class="excerpt">{{ post.excerpt | remove: '\[ ... \]' | remove: '\( ... \)' | markdownify | strip_html | strip_newlines | escape_once }}</span>{% endif %}</a></article>
  </li>
{% endfor %}
</ul>
