include:
  - base

backups:
  user.present:
    - home: /home/backups/

git-core:
  pkg.installed

# Dashboard Data Snapshot Backup

git clone -n dashboard@webserver9.iatistandard.org:/home/dashboard/IATI-Registry-Refresher/data/.git dashboard-snapshot-data:
  cmd.run:
    - user: backups
    - cwd: /home/backups
    - creates: /home/backups/dashboard-snapshot-data
    
cd /home/backups/dashboard-snapshot-data; git fetch:
  cron.present:
    - identifier: backup-dashboard
    - user: backups
    - minute: 0
    - hour: 12

# GitHub Repositories Backup

https://gist.github.com/8c27baf2bb492bfad04615bca24bb8af.git:
  git.latest:
    - rev: master
    - target: /home/backups/backup-github/
    - user: backups

cd /home/backups/backup-github/; ./backup-github.sh:
  cron.present:
    - identifier: backup-github
    - user: backups
    - minute: 0
    - hour: 0

# CSV2IATI Backup

/home/backups/csv2iati:
  file.directory:
    - makedirs: True
    - user: backups
    - group: backups

cd /home/backups/csv2iati; scp pythonuser@webserver2.iatistandard.org:/home/pythonuser/CSV-IATI-Converter.modeleditor/db/csviati.sqlite `date -I`.sqlite; find -maxdepth 1 -type f -mtime +30 -exec rm {} \; ; mv *-01.sqlite monthly/:
  cron.present:
    - identifier: backup-csv2iati
    - user: backups
    - minute: 0
    - hour: 1

# Trello Backup

https://github.com/mattab/trello-backup.git:
  git.latest:
    - rev: 35b834454032539c3c1adc46f44f5e1ca7cd9880
    - target: /home/backups/trello-backup/
    - user: backups

trello-backup-deps:
  pkg.installed:
    - pkgs:
      - php5-cli

# Currently trello-backup/config.php must be manually created
cd /home/backups/trello-backup; php trello-backup.php; gzip *.json; mkdir `date -I`;  mv *.json.gz `date -I`:
  cron.present:
    - identifier: trello-backup
    - user: backups
    - minute: 0
    - hour: 2
