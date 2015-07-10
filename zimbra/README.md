# Zimbra scripts

## delete_domains.sh
Script to delete one or severals domains, starting by accounts, calendar ressources and finaly distribution list.

### Manual
Edit and configure the domains list:
 One domain
 DOMAINS=( domain1 )
 Severals domain:
 DOMAINS=( domain1 domain2 )


Get help
 # delete_domains.sh -h

Dry run mode
 # delete_domains.sh

Delete mode
 # delete_domains.sh -d
