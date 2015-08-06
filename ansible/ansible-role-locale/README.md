# ansible-role-locale

## Aim
Set the locale on the server.
The locale is installed only if it's not present.

## Configuration
In "defaults/main.yml"

"locale_to_install":list
add the locale needed with 

"locale_list_to_remove":boolean
You can see the locale list to be removed 
False, you can the "others" locales in a skipped task.
True, the others locales will return an error.

## Filter
The role could be filtered with the tag "locale"
	ansible-playbook site.yml --tags locale
