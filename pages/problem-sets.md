---
layout: default
title: Problem Sets
---

{% assign labs = site.labs | sort: "title" %}

{% for lab in labs %}
  <article>
    <div class="featured-posts" {% if post.image %}style="background-image:url({{ site.baseurl }}/assets/img/{{ post.image }})"{% endif %}>
      <h2><span>{{ lab.title }}</span></h2>
      <div class="post-excerpt">
        {{ lab }}
      </div>
    </div>
  </article>
{% endfor %}