# ansible-role-hostname

## Aim
Set the hostname and fill the hosts file.

## Configuration
In "defaults/main.yml"

"hostname:":string
The short name, by default, it is the ansible inventory shortname

"fqdn":string
The fully qualified domain name used in the hosts file.

"hostname_hosts":list
Specify each hosts file lines.

## Filter
The role could be filtered with the tag "hostname"
	ansible-playbook site.yml --tags hostname
