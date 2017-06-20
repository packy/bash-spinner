#!/bin/bash

# Author: Tasos Latsas
# https://github.com/packy/bash-spinner
# forked from https://github.com/tlatsas/bash-spinner

# spinner.sh
#
# Display an awesome 'spinner' while running your long shell commands
#
# Do *NOT* call _spinner function directly.
# Use {start,stop}_spinner wrapper functions

# usage:
#   1. source this script in your's
#   2. start the spinner:
#       start_spinner [display-message-here]
#   3. run your command
#   4. stop the spinner:
#       stop_spinner [your command's exit status]
#
# Also see: test.sh


function _spinner() {
    # $1 start/stop
    #
    # on start: $2 display message
    # on stop : $2 process exit status
    #           $3 spinner function pid (supplied from stop_spinner)

    local on_success="DONE"
    local on_fail="FAIL"
    local white="\e[1;37m"
    local green="\e[1;32m"
    local red="\e[1;31m"
    local nc="\e[0m"
    local cursor_off="\e[?25l"
    local cursor_on="\e[?25h"

    case $1 in
        start)
            # calculate the column where spinner and status msg will be displayed
            let column=$(tput cols)-${#2}-8
            # display message and position the cursor in $column column
            echo -ne ${2}
            printf "%${column}s"

            # start spinner
            i=1
            sp=${SPINNER_STYLE:='\|/-'}
            delay=${SPINNER_DELAY:-0.15}

            printf "$cursor_off"
            while :
            do
                printf "\b${sp:i++%${#sp}:1}"
                sleep $delay
            done
            ;;
        stop)
            printf "$cursor_on"
            if [[ -z ${3} ]]; then
                echo "spinner is not running.."
                exit 1
            fi

            kill $3 > /dev/null 2>&1

            # inform the user uppon success or failure
            printf "\b["
            if [[ $2 -eq 0 ]]; then
                printf "${green}${on_success}${nc}"
            else
                printf "${red}${on_fail}${nc}"
            fi
            printf "]\n"
            ;;
        *)
            echo "invalid argument, try {start/stop}"
            exit 1
            ;;
    esac
}

function start_spinner {
    set +m # silence job control messages GLOBALLY
    # $1 : msg to display
    { _spinner "start" "${1}" & } 2> /dev/null
    # set global spinner pid
    _sp_pid=$!
    disown
    set -m # re-enable job control messages GLOBALLY
}

function stop_spinner {
    # $1 : command exit status
    _spinner "stop" $1 $_sp_pid
    unset _sp_pid
}

function select_spinner {
    # $1 : spinner to use
    case $1 in
        arrows)       SPINNER_STYLE="←↖↑↗→↘↓↙" ;;
        vpulse)       SPINNER_STYLE="▁▃▅▆▇▆▅▃" ;;
        hpulse)       SPINNER_STYLE="▏▎▍▋▊▉▉▊▋▍▎" ;;
        hpulse2)      SPINNER_STYLE="▉▊▋▍▎▏▎▍▌▊▉" ;;
        hpulse3)      SPINNER_STYLE="▉▊▋▌▍▎▏▎▍▌▋▊▉" ;;
        block1)       SPINNER_STYLE="▖▘▝▗" ;;
        block2)       SPINNER_STYLE="▌▀▐▄" ;;
        lines)        SPINNER_STYLE="┤┘┴└├┌┬┐" ;;
        triangle)     SPINNER_STYLE="◢◣◤◥" ;;
        square)       SPINNER_STYLE="◰◳◲◱" ;;
        circle1)      SPINNER_STYLE="◴◷◶◵" ;;
        circle2)      SPINNER_STYLE="◐◓◑◒" ;;
        circle3)      SPINNER_STYLE="◜◝◞◟" ;;
        boom)         SPINNER_STYLE=".oO@*" ;;
        dot|dot-cw)   SPINNER_STYLE="⠈⠐⠠⢀⡀⠄⠂⠁" ;;
        dot-ccw)      SPINNER_STYLE="⠁⠂⠄⡀⢀⠠⠐⠈" ;;
        dots|dots-cw) SPINNER_STYLE="⣾⣷⣯⣟⡿⢿⣻⣽" ;;
        dots-ccw)     SPINNER_STYLE="⣾⣽⣻⢿⡿⣟⣯⣷" ;;
        diamonds)     SPINNER_STYLE="◇◆◈◆" ;;
        default|*)    SPINNER_STYLE='\|/-' ;;
    esac
}

function spinner_gallery {
    local time=${1:-30}
    local delay=${SPINNER_DELAY:-0.15}

    local hide_cursor="\e[?25l"
    local show_cursor="\e[?25h"
    local clear_screen="\e[2J"
    local cursor_UL_screen="\e[H" # move cursor to upper left corner of screen

    # create a trap to allow us to exit cleanly on ^C
    function spinner_gallery_finish {
        printf "$show_cursor"
        END=$START # exit the loop ASAP
    }
    trap spinner_gallery_finish SIGINT

    function spinner_gallery_max {
        perl -e 'print $ARGV[0] > $ARGV[1] ? $ARGV[0] : $ARGV[1]' -- "$1" "$2"
    }
    function spinner_gallery_min {
        perl -e 'print $ARGV[0] < $ARGV[1] ? $ARGV[0] : $ARGV[1]' -- "$1" "$2"
    }

    # get the list of styles from the definition of the select_spinner function
    STYLES=$(type select_spinner | perl -ne '
             s/\s+\|\s+\*//;
             /^\s+(.*)\)/ && do {
               $s = $1;
               $s =~ s/\s+//g;
               print qq{"$s" };
             }')

    local MAX=0
    local LIST=""
    for ITEM in $STYLES; do
        eval ITEM=$ITEM

        MAX=$(spinner_gallery_max $MAX ${#ITEM})

        local NAME=$(echo $ITEM | sed 's/\|.*//' | sed 's/\-/_/g')

        LIST="$LIST $NAME"

        local STYLE=style_$NAME
        eval local $STYLE=$(echo $ITEM | sed 's/\|.*//')

        local LABEL=label_$NAME
        eval local $LABEL=\""$ITEM"\"

        local VAR=i_$NAME
        eval local $VAR=1
    done

    local START=$( date +%s )
    local END=$(( $START + $time + 1 ))

    printf "$clear_screen"

    while [[ $( date +%s ) -le $END ]]; do
        printf "$cursor_UL_screen"
        printf "$hide_cursor"
        echo
        for NAME in $LIST; do
            local STYLE=$(eval "echo \$style_$NAME")
            local LABEL=$(eval "echo \$label_$NAME")
            local VAR=i_$NAME
            select_spinner $STYLE
            _SPINNER="${SPINNER_STYLE:$VAR++%${#SPINNER_STYLE}:1}"
            printf "\b %${MAX}s %s\n" $LABEL "$_SPINNER"
        done
        local REMAINING=$(spinner_gallery_min $(( $END - $( date +%s ) )) $time)
        if [[ $REMAINING -ge 0 ]]; then
            printf "\ndisplaying gallery for 0:%02d " $REMAINING
        fi
        sleep $delay
    done

    # clean up afterwards
    trap - SIGINT
    printf "\n\n"
    printf "$show_cursor"
    unset -f spinner_gallery_finish # since functions can't be local
    unset -f spinner_gallery_max
    unset -f spinner_gallery_min
}
