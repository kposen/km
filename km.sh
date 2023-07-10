#!/bin/bash
# Copyright (c) 2023, Kevin ??
# Contributors:
#   - Bank-Builder : https://github.com/Bank-Builder
#   - Kevin-???? :  https://github.com/kevin-???
# License MIT: https://opensource.org/licenses/MIT

_version="0.9"
_custodians=0;
_required=0;

function displayHelp(){
 echo "Usage km [COMMAND] [OPTIONS]";
 echo "ver $_version";
 echo "   Kevin's Magic (km) is a wrapper to encrypt a payload, split the master-key to be distributed";
 echo "   to the key custodians, and then join it all back together again.";
 echo "";
 echo "  [COMMAND]:";
 echo "    --initialise [custodians] [required] [--force]";
 echo "                                         initialise for a given number of custodians";
 echo "                                         and parts required to reconstitute.";
 echo "                                         Where a .conf already exists the optional --force";
 echo "                                         will regenerate the master-key instead of only just";
 echo "                                         regenerating the custodian key parts.";
 echo "";
 echo "    lock -f [file]                       encrypted the [file] and displays 'custodian.1..5' key parts";
 echo "";
 echo "    unlock -f [file] -parts [[parts n/m]] decryptes the [file]using the key parts provided";
 echo "";
 echo "  EXAMPLE(s):";
 echo "    km --initialise 5 2                     # create a km.conf file with keys & salt";
 echo "    km lock -f payload.file                 # creates an encrypted payload.enc & cutodian key files";
 echo "    km unlock -f payload.file -parts [part1/5] [part2/5]   # use parts 2/5 to unlock payload.enc";         
 echo "    km --version";
 echo "";
}

function displayVersion(){
 echo "km version $_version";
 echo "-------";
 echo "Source: https://github.com/kevin-???/km - Copyright (C) 2023, Kevin ????";
 echo "License MIT: https://opensource.org/licenses/MIT";
 echo "-------";
}

function initialise(){
 # This function will create the km.conf file and 
 # set the initial conditions required.
 #  if _custodians > 0 and < 12:
 #     if _required> 0 and <= _custodians
        touch km.conf
        echo "Kevin's Magic Configuration File" > km.conf
        echo "================================" >> km.conf
        _masterKey=$(openssl rand -hex 16)
        _salt=$(openssl rand -hex 16)
        _iv=$(openssl rand -hex 16)
        echo "masterkey:$_masterKey" >> km.conf
        echo "salt:$_salt" >> km.conf
        echo "iv:$_iv" >> km.conf
        echo "custodians:$_custodians" >> km.conf
        echo "required:$_required" >> km.conf
        echo "================================" >> km.conf
        exit 0; 
    # else 
    #     echo "Invalid custodians or required number supplied"
    #     exit 1;
 
}

function lock(){
 # load the config and encrypt the file & generate the Shamir parts
 _salt="$(cat km.conf |grep salt | awk -F: '{print $2}')"
 _iv="$(cat km.conf |grep iv | awk -F: '{print $2}')"
 _masterkey="$(cat km.conf |grep masterkey | awk -F: '{print $2}')"
 _custodians="$(cat km.conf |grep custodians | awk -F: '{print $2}')"
 _required="$(cat km.conf |grep required | awk -F: '{print $2}')"
 # AES encrypt(masterkey ) file > file
 echo "openssl enc -aes-128-cbc -pbkdf2 -K $_key -S $_salt -iv $_iv -in sample.txt -out sample.txt.enc"

 # ssss-split -t 3 -n 5 -w $_masterKey
}

function unlock(){
 # ssss-combine -t 3 
 echo ""
}

# Kevin's Magic Main
while [[ "$#" > 0 ]]; do
    case $1 in
        status) 
            displayStatus; exit 0;;
        --initialise)
            _custodians="$2";
            _required="$3";
            initialise;
            exit 0;;
        lock|LOCK) 
            lock; exit 0;;
        unlock|UNLOCK) 
            unlock; exit 0;;  
        --help) 
            displayHelp; exit 0;;
        --version) 
            displayVersion; exit 0;;
        -f|--file) 
            _conf="$2";
            shift;;
        *) echo "Unknown parameter passed: $1"; exit 1;;
    esac; 
    shift;
done

echo "Try km --help for help";

## End ##
