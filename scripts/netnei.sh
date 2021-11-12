#! /usr/bin/env sh
TMP_DIREC=`mktemp -d`
TMPOUT="${TMP_DIREC}/tmp_output"
TMPOUT2="${TMP_DIREC}/tmp_output2"
LOCATE="192.168.50.*"
ROUND=1

# handler
trap "interrupt_handle 2" 2
interrupt_handle (){
    if [ ${1} -eq 2 ]; then
        echo "Stop scanning, delete tmp file..." >&1
        rm -rf "${TMP_DIREC}"
        echo "Complete."
        exit 255
    fi
}

# check pkgs
check_pkgs(){
    # nmap
    if [ ${1} = "apt" ]; then
        apt -qq list --installed | grep nmap | awk '{ print $0; }'  > ${TMPOUT}
    elif [ ${1} = "brew" ]; then
        brew list | awk '{print $0}' | grep nmap > ${TMPOUT}
    fi
    test -s ${TMPOUT}
    local res=${?}
    if [ ${res} -eq 0 ]; then
        echo "nmap has been installed..."
    else
        echo "namp haven't been install, installing..."
        if [ ${1} = "apt" ]; then
            sudo apt install nmap
        elif [ ${1} = "brew" ]; then
            brew install nmap
        fi
    fi
    

    # dialog
    if [ ${1} = "apt" ]; then
        apt -qq list --installed | grep dialog | awk '{ print $0; }'  > ${TMPOUT}
    elif [ ${1} = "brew" ]; then
        brew list | awk '{print $0}' | grep dialog > ${TMPOUT}
    fi
    test -s ${TMPOUT}
    local res=${?}
    if [ ${res} -eq 0 ]; then
        echo "dialog has been installed..."
    else
        echo "dialog haven't been install, installing..."
        if [ ${1} = "apt" ]; then
            sudo apt install dialog
        elif [ ${1} = "brew" ]; then
            brew install dialog
        fi
    fi
}

# find with system dns
find_dev() {
    nmap --system-dns -sn "${LOCATE}" \
        | grep "Nmap scan" > ${TMPOUT2}
    cat ${TMPOUT2} \
        | awk 'BEGIN{ HOST=0; } { if (NF == 6) {printf "%s %s ", $(NF-1), $NF;} else {printf "unknown (%s) ", $NF; } HOST+=1; } END{printf "TOTAL %s ", HOST;}' \
        > ${TMPOUT}
    dialog --ok-label "Keep scanning" --no-cancel\
         --menu "Scan Result #${1}"  20 50 20 \
         `cat ${TMPOUT}` 2> /dev/null
}

# check packages
if [ ${1} ]; then
    if [ ${1} = "brew" ]; then
        check_pkgs "brew"
    elif [ ${1} = "apt" ]; then
        check_pkgs "apt"
    else
        echo "Please input package tool name."
        rm -rf "${TMP_DIREC}"
        exit 255
    fi
fi

# Main Event Loop
if [ $2 ]; then
    LOCATE=${2}
    dialog --ok-label "scan" \
        --msgbox "Packages are all ready. \n...\nScan target has been set: ${LOCATE}" 10 40
else
    dialog --ok-label "scan" \
        --msgbox "Packages are all ready. \n...\nDefault Scaning: ${LOCATE} " 10 40
fi

while true; do
    find_dev $ROUND
    ROUND=$(( ROUND + 1 ))
done

# End
rm -rf "${TMP_DIREC}"
echo "End."
