---
layout: workspace
title: Categories
icon: fas fa-stream
order: 1
---

<section class="logs" aria-labelledby="logs-title">
  <div class="section-heading"><h2 id="logs-title" class="command"><span>➜</span> ls -al ~/<b>categories/</b></h2><span class="online">● WORKSPACE</span></div>
  <div class="category-grid">
    {% assign categories = site.categories | sort %}
    {% for category in categories %}
      {% assign name = category[0] %}
      {% assign group_posts = category[1] %}
      {% assign slug = name | slugify | url_encode %}
      {% assign category_url = '/categories/' | append: slug | append: '/' %}
      <a class="category-card" href="{{ category_url | relative_url }}">{% include taxonomy-card-content.html name=name count=group_posts.size %}</a>
    {% endfor %}
  </div>
</section>
