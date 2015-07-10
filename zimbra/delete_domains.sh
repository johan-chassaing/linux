#!/bin/bash
##########################################
#
# Zimbra migration script
#
# Delete a full zimbra domain 
# All accounts, calendar ressources, 
# distribution list, domain
#
##########################################
#
# By Johan CHASSAING
# On 2015-07-10
# Last modification 2015-07-10
#
##########################################

##########################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by# the Free Software Foundation, either version 3 of the License, or
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>. 
#
##########################################


##########################################
#
#               Variables
#
##########################################

# List of each domains
DOMAINS=( domain1 )
#DOMAINS=( domain1 domain2 domain3 )

DATE=`date +%Y%m%d_%H%M`
LOG=$(dirname $0)/log.txt
SCRIPTNAME=$(basename $0)

##########################################
#
#               Functions
#
##########################################

##########################################
#         Last function before exit

# Show log path before exit
finish()
{
  # Show log path
  echoInfo "Log file created at $LOG"
  sleep 1
}

##########################################
#               Echo colorization 

# Insert color for ok/info/error

echoOk()
{
  echo -e "\e[0;32m [OK]\e[0m $1 " | tee -a $LOG
}

echoInfo()
{
  echo -e "\e[0;33m [Info]\e[0m $1 " | tee -a $LOG
}

echoError()
{
  echo -e "\e[0;31m [Error]\e[0m $1 " | tee -a $LOG
}

##########################################
#               Bad Parameters

# show error message and usage then exit
bad_Parameters()
{
  echoError "Bad parameters, please check"
  usage
  exit 1
}

##########################################
#               Usage

# How to use this script
usage()
{
  echo "  $SCRIPTNAME usage:"
  echo "  -h show help"
  echo "  -d delete accounts/ressources/dl"
}

##########################################
#               checkUser

# Check the user id

checkUser()
{
  ZIMBRAID=`id zimbra -u`
  [[ "$?" -ne "0" ]] && echoError "Zimbra user doesn't exist" && exit 1 

  if [[ "$(id -u)" -ne "$ZIMBRAID" ]]; then
    echoError "You must be user Zimbra"
    exit 1
  fi
}


##########################################
#
#               Main
#
##########################################
# Check arguments & launch options checking
while getopts "hd" option
do
  case $option in

    # show help
    h)
      opt_usage=1
      ;;
    # delete 
    d)
      opt_delete=1
      ;;
    # invalid option
    \?)
      bad_Parameters
      ;;
  esac
done

[[ "$opt_usage" -eq 1 ]] && usage && exit 0

# Checking if user is root
checkUser


# Starting
startime=$(date +%s)
echoInfo "Starting: $DATE: $startime"

# Before exiting show the log path
trap finish EXIT


[[ "$opt_delete" -ne 1 ]] && echoInfo "Dry run mode"

nb=0
fail=0

# parse domains
for domain in ${DOMAINS[@]} ; do
  #ignore empty domain
  [[ "$domain" == "" ]] && continue

  ((nb++))
  echoInfo " $nb: $domain"

  #domain still exist
  domaineExist=`zmprov gad | grep -E "^${domain}$" | wc -l `
  if [[ "$domaineExist" -eq 1 ]]; then
    
    echoInfo "  Getting accounts/ressources/dl information"
  
    #get all accounts name
    currentAccounts=`zmprov -l gaa $domain`
    for account in $currentAccounts; do
      echoInfo "   Deleting $account"
      [[ "$opt_delete" -eq 1 ]] && zmprov da $account
  	if [[ "$?" -eq 0 ]]; then
        echoOk "   $account deleted"
  	else
      if [[ "$opt_delete" -eq 1 ]]; then
        echoError "   $account deletition fails" && fail=1 && break
      else
        #dry run , no fail, no break
        echoInfo "   $resname deletition dry run"
      fi
  	fi
    done
    
    [[ "$fail" -eq 1 ]] && break
  
    #get all calendar resources name
    currentCalendarRessources=`zmprov -l gacr $domain`
    for resname in $currentCalendarRessources; do
      echoInfo "   deleting $resname"
      [[ "$opt_delete" -eq 1 ]] && zmprov dcr $resname 
  	if [[ "$?" -eq 0 ]]; then
        echoOk "     $resname deleted"
  	else
      if [[ "$opt_delete" -eq 1 ]]; then
        echoError "   $resname deletition fails" && fail=1 && break
      else
        #dry run , no fail, no break
        echoInfo "   $resname deletition dry run"
      fi
  	fi
    done
  
    [[ "$fail" -eq 1 ]] && break
  
    # Get all distribution list
    currentDistributionList=`zmprov -l gadl $domain`
    for dlname in $currentDistributionList; do
      echoInfo "   deleting $dlname"
      [[ "$opt_delete" -eq 1 ]] && zmprov ddl $dlname
  	if [[ "$?" -eq 0 ]]; then
        echoOk "     $dlname deleted"
  	else
      if [[ "$opt_delete" -eq 1 ]]; then
        echoError "   $dlname deletition fails" && fail=1 && break
      else
        #dry run , no fail, no break
        echoInfo "   $dlname deletition dry run"
      fi
  	fi
    done
  
    [[ "$fail" -eq 1 ]] && break
  
    # Remove domain 
    echoInfo "   deleting $domain"
    [[ "$opt_delete" -eq 1 ]] && zmprov dd $domain
    if [[ "$?" -eq 0 ]]; then
      echoOk "     $domain deleted"
    else
      if [[ "$opt_delete" -eq 1 ]]; then
        echoError "   $domain deletition fails" && fail=1 && break
      else
        #dry run , no fail, no break
        echoInfo "   $domain deletition dry run"
      fi
    fi
  
    [[ "$fail" -eq 1 ]] && break

  else
    echoError "  $domain doesn't exist"
  fi

done

# Time
endtime=$(date +%s)
echoInfo "End: $DATE: $endtime"

diff=$(($endtime-$startime))

if [[ $diff -gt 60 ]]; then
  show_time="$(($diff/60)) min."
else
  show_time="$diff sec."
fi

echoInfo "Time elapsed: $show_time:" 

