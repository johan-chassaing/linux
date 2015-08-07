# ansible-role-raid-lsi-sas2

## Aim
Install lsi raid card monitoring package and script

## Configuration
In "defaults/main.yml"

"raid_mailto:":string
The mail used by the script in "/etc/cron.hourly/check-raid" to send the raid status in case of failure.

## Filter
The role could be filtered with the tag "raid_lsi_sas2"
	ansible-playbook site.yml --tags raid_lsi_sas2 
