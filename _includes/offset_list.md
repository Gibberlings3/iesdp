{% for o in offsets %}
<tr>

{% if o.unused %}
  {% assign odesc = '<span class="unknown">' | append: o.desc | append: ' (unused)</span>' %}
{% else %}
  {% assign odesc = o.desc %}
{% endif %}

{% if o.length %}
  {% assign olength = o.length %}
{% else %}
  {% case o.type %}
    {% when 'byte' %}
      {% assign olength = 1 %}
    {% when 'char' %}
      {% assign olength = 1 %}
    {% when 'word' %}
      {% assign olength = 2 %}
    {% when 'dword' %}
      {% assign olength = 4 %}
    {% when 'strref' %}
      {% assign olength = 8 %}
  {% endcase %}
{% endif %}

  <td>{{ o.offset }}</td>
  <td>{{ olength }} ({{ o.type }})</td>
  <td>{{ odesc | markdownify | remove: '<p>' | remove: '</p>' }}</td>
</tr>
{% endfor %}
