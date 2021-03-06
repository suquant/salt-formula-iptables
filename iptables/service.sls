{% from "iptables/map.jinja" import service with context %}

{%- if service.enabled %}

include:
  - iptables.rules

iptables_packages:
  pkg.installed:
  - names: {{ service.pkgs }}

iptables_services:
{%- if grains.init == 'systemd' %}
  service.running:
{%- else %}
  service.dead:
{%- endif %}
  - enable: true
  - name: {{ service.service }}
  - sig: test -e /etc/iptables/rules.v4
  - require:
    - pkg: iptables_packages

{%- else %}

iptables_services:
  service.dead:
  - enable: false
  - name: {{ service.service }}

{%- for chain_name in ['INPUT', 'OUTPUT', 'FORWARD'] %}
iptables_{{ chain_name }}_policy:
  iptables.set_policy:
    - chain: {{ chain_name }}
    - policy: ACCEPT
    - table: filter
    - require_in:
      - iptables: iptables_flush

{%-   if grains.ipv6|default(False) and service.ipv6|default(True) %}
iptables_{{ chain_name }}_ipv6_policy:
  iptables.set_policy:
    - chain: {{ chain_name }}
    - family: ipv6
    - policy: ACCEPT
    - table: filter
    - require_in:
      - iptables: ip6tables_flush
{%-   endif %}

{%- endfor %}

iptables_flush:
  iptables.flush

{%- if grains.ipv6|default(False) and service.ipv6|default(True) %}
ip6tables_flush:
  iptables.flush:
    - family: ipv6
{%- endif %}


{%- endif %}
