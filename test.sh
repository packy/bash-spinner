#!/bin/bash

source "$(pwd)/spinner.sh"

# test success
select_spinner default
start_spinner 'sleeping for 2 secs...'
sleep 2
stop_spinner $?

# test fail
start_spinner 'copying non-existent files...'
# use sleep to give spinner time to fork and run
# because cp fails instantly
sleep 2
cp 'file1' 'file2' > /dev/null 2>&1
stop_spinner $?

# test alternate spinners
printf "\nSome alternate spinners:\n"
select_spinner arrows;   start_spinner 'Arrows';    sleep 2; stop_spinner $?
select_spinner lines;    start_spinner 'Lines';     sleep 2; stop_spinner $?
select_spinner triangle; start_spinner 'Triangles'; sleep 2; stop_spinner $?
select_spinner circle2;  start_spinner 'Circles';   sleep 2; stop_spinner $?
select_spinner dots;     start_spinner 'Dots';      sleep 2; stop_spinner $?
