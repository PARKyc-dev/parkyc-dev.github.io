---
layout: workspace
title: Categories
icon: fas fa-stream
order: 1
---

<section class="logs" aria-labelledby="logs-title">
  <div class="section-heading"><h2 id="logs-title" class="command"><span>➜</span> ls -al ~/<b>categories/</b></h2><span class="online">● WORKSPACE</span></div>
  <div class="category-grid">
    {% assign root_names = '' | split: ',' %}
    {% for post in site.posts %}{% assign root_name = post.categories | first %}{% if root_name %}{% assign root_names = root_names | push: root_name %}{% endif %}{% endfor %}
    {% assign root_names = root_names | uniq | sort %}
    {% for name in root_names %}
      {% assign group_posts = site.categories[name] %}
      {% assign children = '' | split: ',' %}
      {% for post in group_posts %}{% if post.categories.first == name %}{% for category in post.categories offset:1 %}{% assign children = children | push: category %}{% endfor %}{% endif %}{% endfor %}
      {% assign children = children | uniq | sort %}
      {% assign slug = name | slugify | url_encode %}
      {% assign category_url = '/categories/' | append: slug | append: '/' %}
      <a class="category-card" href="{{ category_url | relative_url }}">{% assign card_description = children | join: ' · ' %}{% include taxonomy-card-content.html name=name count=group_posts.size description=card_description %}</a>
    {% endfor %}
  </div>
</section>
