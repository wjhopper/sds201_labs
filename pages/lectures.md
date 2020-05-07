---
layout: default
title: Lectures
---

{% assign lectures = site.lectures | sort: "title" %}

{% for lect in lectures %}
<article>
  <div class="featured-posts" {% if post.image %}style="background-image:url({{ site.baseurl }}/assets/img/{{ post.image }})"{% endif %}>
    <h2><span>{{ lect.title }}</span></h2>
    <div class="post-excerpt">
      {{ lect }}
    </div>
  </div>
</article> 
{% endfor %}
