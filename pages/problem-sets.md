---
layout: default
title: Problem Sets
---

{% assign problem_sets = site.problem_sets | sort: "title" %}

{% for ps in problem_sets %}
  <article>
    <div class="featured-posts" {% if post.image %}style="background-image:url({{ site.baseurl }}/assets/img/{{ post.image }})"{% endif %}>
      <h2><span>{{ ps.title }}</span></h2>
      <div class="post-excerpt">
        {{ ps }}
      </div>
    </div>
  </article>
{% endfor %}