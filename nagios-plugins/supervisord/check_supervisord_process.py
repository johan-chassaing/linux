#!/usr/bin/python
# -*- coding: utf-8 -*-

# Checks supervisord processes status
#

# Copyright Johan Chassaing 2015
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
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

#
# VARIABLE
#

states_codes = {
    'UNKOWN': 3,
    'CRITICAL': 2,
    'WARNING': 1,
    'OK': 0
}
states = {
    'BACKOFF':  'CRITICAL',
    'EXITED':   'CRITICAL',
    'FATAL':    'CRITICAL',
    'UNKNOWN':  'CRITICAL',
    'STARTING': 'WARNING',
    'STOPPING': 'WARNING',
    'RUNNING':  'OK',
    'STOPPED':  'OK'
}

supervisorctl_command = 'supervisorctl status'


# Import
#
import os


# debrief
#
def debrief(nb_process,process_dict,state):
    if nb_process:
        print "%s | %d/%d - %s" %(state,
                                  len(process_dict),
                                  nb_process,
                                  ','.join(process_dict))
    else :
        print "%s | %d/%d" %(state,
                             len(process_dict),
                             nb_process)
    exit(states_codes[state])


# Main
#
def main():

    nb_process = 0
    processes_error = []
    processes_warning = []
    processes_ok = []
    processes_unkown = []
    
    try:
        processlist = os.popen('%s' % (supervisorctl_command)).readlines()
    except Exception as current_error: 
        print "CRITICAL | Error %s" % str(current_error)
        exit(states_codes['CRITICAL'])

    for current_process in processlist:
        nb_process += 1

        current_process = current_process.split()

        current_state = states[current_process[1]]
        # fill dictionaries
        if current_state == 'CRITICAL':
            processes_error.append(current_process[0])

        elif current_state == 'WARNING':
            processes_warning.append(current_process[0])

        elif current_state == 'OK':
            processes_ok.append(current_process[0])

        else:
            processes_unkown.append(current_process[0])

    # print output
    if processes_error:
        debrief(nb_process, processes_error, "CRITICAL")

    elif processes_unkown:
        debrief(nb_process, processes_unkown, "UNKOWN")

    elif processes_warning:
        debrief(nb_process, processes_warning, "WARNING")

    else:
        debrief(nb_process, processes_ok, "OK")

# 
#
if __name__ == '__main__':
    main()
