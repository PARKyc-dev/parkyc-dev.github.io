---
layout: workspace
title: Tags
icon: fas fa-tags
order: 2
---

<section class="logs" aria-labelledby="logs-title">
  <div class="section-heading"><h2 id="logs-title" class="command"><span>➜</span> ls -al ~/<b>tags/</b></h2><span class="online">● WORKSPACE</span></div>
  <div class="category-grid">
    {% assign groups = site.tags | sort %}
    {% for group in groups %}
      {% assign slug = group[0] | slugify | url_encode %}
      {% assign tag_url = '/tags/' | append: slug | append: '/' %}
      {% assign tag_name = group[0] %}{% assign tag_count = group[1].size %}
      <a class="category-card" href="{{ tag_url | relative_url }}">{% include taxonomy-card-content.html name=tag_name count=tag_count description="태그별 개발 기록" %}</a>
    {% endfor %}
  </div>
</section>
