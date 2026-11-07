---
layout: workspace
title: Series
icon: fas fa-layer-group
order: 6
---

{% assign series_posts = site.posts | where_exp: 'post', 'post.series != nil and post.series != empty' | sort: 'date' %}
{% assign series_groups = series_posts | group_by: 'series' | sort: 'name' %}
<section class="logs" aria-labelledby="logs-title">
  <div class="section-heading"><h2 id="logs-title" class="command"><span>➜</span> ls -al ~/<b>series/</b></h2><span class="online">● WORKSPACE</span></div>
  {% if series_groups.size == 0 %}
  <p class="log-empty">아직 등록된 시리즈가 없습니다.</p>
  {% else %}
  <div class="category-grid series-index">
    {% for group in series_groups %}
    <details class="series-card-group">
      <summary class="category-card">{% include taxonomy-card-content.html name=group.name count=group.items.size description="시리즈 글 목록 펼치기" %}</summary>
      <ol class="series-list series-card-posts">
        {% for post in group.items %}<li><a href="{{ post.url | relative_url }}">{{ post.title | escape }}</a></li>{% endfor %}
      </ol>
    </details>
    {% endfor %}
  </div>
  {% endif %}
</section>
