{% assign current_offset = 0 %}
{% for o in offsets %}
<tr>

{% if o.offset and o.offset != current_offset %}
  {{ "Offset mismatch. Expected " | append: o.offset | append: ", got " | append: current_offset | append: ". Desc: " | append: o.desc | raise_error }}
{% endif %}

{% if o.unused %}
  {% assign odesc = '<span class="unknown">' | append: o.desc | append: ' (unused)</span>' %}
{% else %}
  {% assign odesc = o.desc %}
{% endif %}

{% if o.length %}
  {% assign olength = o.length %}
{% else %}
  {% case o.type %}
    {% when 'byte' %} {% assign olength = 1 %}
    {% when 'char' %} {% assign olength = 1 %}
    {% when 'word' %} {% assign olength = 2 %}
    {% when 'dword' %} {% assign olength = 4 %}
    {% when 'resref' %} {% assign olength = 8 %}
  {% endcase %}
{% endif %}

  <td>{{ current_offset | offset_to_hex }}</td>
  <td>{{ olength }} ({{ o.type }})</td>
  <td>{{ odesc | liquify |  markdownify }}</td>
</tr>

{% assign current_offset = current_offset | plus: olength %}
{% endfor %}
