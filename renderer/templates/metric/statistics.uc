{% if (!statistics) return %}

# Statistics configuration
set state.stats.interval={{ statistics.interval }}
{% for (let statistic in statistics.types): %}
add_list state.stats.types={{ statistic  }}
{% endfor %}
