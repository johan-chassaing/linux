#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Nagios plugin to check supervisord's processes status
"""

#  Author: 
#    Johan Chassaing
#
#  License: 
#    GPL
#
#  Dependencies:
#    supervisord
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
# DATA
#
__version__ = "0.1"

supervisorctl_command = 'sudo supervisorctl status'

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

processes_error = []
processes_warning = []
processes_ok = []
processes_unkown = []
#
# IMPORT
#
try :
    import argparse
    import sys
    from subprocess import Popen, PIPE
except Exception as current_error:
    print "CRITICAL - Error %s" % str(current_error)
    exit(states_codes['CRITICAL'])


#
# FUNCTIONS
#
def print_to_screen(processes_count,information,state):
    """
    print message before exit

    :param processes_count: number of processes
    :param information: processes or error code and description
    :param state: The processes state

    :type processes_count: int
    :type information: list
    :type state: str
    """
    if processes_count == -1:
       print "%s - Error %d : %s" % (state,
                                   information[0],
                                   information[1])
    elif processes_count > 0:
       print "%s - %d/%d : %s" %(state,
                                 len(information),
                                 processes_count,
                                 ','.join(information))
    else :
       print "%s - %d/%d" %(state,
                            len(information),
                            processes_count)
    exit(states_codes[state])


def processes_selector(processes_count):
    """
    Display the processes having the worst state 

    :param processes_count: number of processes

    :type processes_count: int
    """
    if processes_error:
        print_to_screen(processes_count, processes_error, "CRITICAL")

    elif processes_unkown:
        print_to_screen(processes_count, processes_unkown, "UNKOWN")

    elif processes_warning:
        print_to_screen(processes_count, processes_warning, "WARNING")

    else:
        print_to_screen(processes_count, processes_ok, "OK")


def dispatch_processes(running_processes):
    """
    Dispacth the processes by state

    :param running_processes: processes with full output

    :type running_processes: list
    """
    processes_count = 0
    for current_process in running_processes:

        current_process = current_process.strip().split()

        # filter when arg --process is used
        if args.process:
            if current_process[0] != args.process[0]:
                continue

        processes_count += 1

        current_state = states[current_process[1]]
    
        if current_state == 'CRITICAL':
            processes_error.append(current_process[0])
    
        elif current_state == 'WARNING':
            processes_warning.append(current_process[0])
    
        elif current_state == 'OK':
            processes_ok.append(current_process[0])
    
        else:
            processes_unkown.append(current_process[0])

    # error when arg --process is used and no process found 
    if args.process and processes_count == 0 :
        processes_error.append(args.process[0])
        processes_count = 1

    processes_selector(processes_count)


def check_supervisorctl():
    """
    Run the supervisorctl command
    """
    run_cmd = Popen(supervisorctl_command, stderr=PIPE, stdout=PIPE, shell=True)
    run_cmd_output, errors = run_cmd.communicate()

    if run_cmd.returncode or errors:
        print_to_screen(-1,[run_cmd.returncode,str(errors)],'CRITICAL')

    dispatch_processes(run_cmd_output.strip().split("\n"))


def check_args():
    """
    Arguments checker
    """
    parser = argparse.ArgumentParser(
                                      description='Nagios plugin for supervisord checking.')
    parser.add_argument(
                        '-f', '--full', action='store_true', default=False, 
                        help='Check all supervisord\'s processes')

    parser.add_argument(
                        '-p', '--process', action='store',
                        type=str, nargs=1,
                        help='Check for a specific supervisord\'s process')

    parser.add_argument(
                        '-v', '--version', action='version',
                        version=' '.join(['version:',__version__]),
                        help='Show plugin version')

    # Error if no argument
    if len(sys.argv) == 1:
        print "CRITICAL - plugin missconfigured, please check plugin's help [-h]"
        exit(states_codes['CRITICAL'])

    global args
    try:
        args = parser.parse_args()
    except Exception as current_error:
        print "CRITICAL - Error %s" % str(current_error)
        exit(states_codes['CRITICAL'])


    check_supervisorctl()


#
# LAUNCHER
#
if __name__ == '__main__':
    check_args();
