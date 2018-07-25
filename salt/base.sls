Europe/London:
    timezone.system

ssh_keys:
  file.managed:
    - name: /root/.ssh/authorized_keys
    - source: salt://authorized_keys

basic-server-deps:
    pkg.installed:
        - pkgs:
            - unattended-upgrades

/etc/apt/apt.conf.d/50unattended-upgrades:
  file.managed:
    - source: salt://50unattended-upgrades

/etc/apt/apt.conf.d/10periodic:
  file.managed:
    - source: salt://10periodic
