#!/bin/bash
# Copyright (c) 2023, Kevin Posen
# Contributors:
#   - Bank-Builder : https://github.com/Bank-Builder
#   - Kevin Posen :  https://github.com/kposen/km
# License MIT: https://opensource.org/licenses/MIT

_version="0.9"
_custodians=0;
_required=0;
_inFile=""
_outFile=""
_custodianKeysFile=""
_iv=""
_salt=""
_key=""
_lock=""

function displayHelp(){
    echo "Usage km [COMMAND] [OPTIONS]";
    echo "ver $_version";
    echo "   Kevin's Magic (km) is a wrapper to encrypt a payload, split the master-key to be distributed";
    echo "   to the key custodians, and then join it all back together again.";
    echo "";
    echo "  [COMMAND]:";
    echo "    --help                               display this help";
    echo "    --version                            display the version of km";
    echo "    --initialise [custodians] [required]";
    echo "                                         initialise for a given number of custodians";
    echo "                                         and parts required to reconstitute.";
    echo "                                         Where a .conf already exists the optional --force";
    echo "                                         will regenerate the master-key instead of only just";
    echo "                                         regenerating the custodian key parts.";
    echo "";
    echo "    lock -i [file]                       created the encrypted file.enc and a custodian.keys file";
    echo "";
    echo "    unlock -i [encrypted_file] -o [file] -s [custodians.keys]";
    echo "                                         decryptes the [encrypyted_file] using the key parts provided";
    echo "";
    echo "  EXAMPLE(s):";
    echo "    km --initialise 5 2                                       # create a km.conf file";
    echo "    km lock -i sample.txt -o sample.enc -s custodian.keys     # creates the encrypted file & custodian.keys";
    echo "    km unlock -i sample.enc -o sample.txt -s custodian.keys   # use at least r of n keys in custodian.keys";         
    echo "    km --version";
    echo "";
}

function displayVersion(){
    echo "km version $_version";
    echo "-------";
    echo "Source: https://github.com/kposen/km - Copyright (C) 2023, Kevin Posen";
    echo "License MIT: https://opensource.org/licenses/MIT";
    echo "-------";
}

function initialise(){
 # This function will create the km.conf file
    if [[ $_custodians -gt 0 && $_custodians -lt 20 && $_required -lt $_custodians ]]; then
        touch km.conf
        echo "Kevin's Magic Configuration File" > km.conf
        echo "================================" >> km.conf
        echo "custodians:$_custodians" >> km.conf
        echo "required:$_required" >> km.conf
        echo "================================" >> km.conf
        exit 0;
    else
        echo "Invalid custodians or required number of key parts supplied"
        exit 1;
    fi
}

function lock(){
    # load the config and encrypt the file & generate the Shamir parts
    _key=$(openssl rand -hex 16)
    _salt=$(openssl rand -hex 16)
    _iv=$(openssl rand -hex 16)

    # AES(file,key,iv,salt) > file.enc
    echo "openssl enc -aes-128-cbc -pbkdf2 -K $_key -S $_salt -iv $_iv -in $_inFile -out $_outFile"

    # Perform Shamir secret sharing scheme on key+iv+salt ==> 48 bytes (128 bits x 3)
    # We limited the key length to 128 bits to avoid over length input into ssss-split.
    _custodians="$(cat km.conf |grep custodians | awk -F: '{print $2}')"
    _required="$(cat km.conf |grep required | awk -F: '{print $2}')"
    echo "echo $_key$_iv$_salt | ssss-split -t $_required -n $_custodians -w km > $_custodianKeysFile"
}

function unlock(){
    # create a custodian key part file, on key per line
    # read in the custodian keys and the encrypted file and produce the unencrypted output
    _custodians="$(cat km.conf |grep custodians | awk -F: '{print $2}')"
    _required="$(cat km.conf |grep required | awk -F: '{print $2}')"

    echo "1. read in $_required lines from the $_custodianKeysFile - each line is a key eg \$km1..3"
    echo "2. ssss-split -t 3 <<EOF; \$km1; \$km2; \$km3; EOF"
    echo "3. split out the key = \${split:0:15}, iv = \${split:16:31}, salt = \${split:32:48} "
    echo "4. decrypt the $_inFile with the \$_key, \$_iv, and \$_salt, and create the $_outFile"

}

# Kevin's Magic Main
while [[ "$#" > 0 ]]; do
    case $1 in
        --initialise|--initialize)
            _custodians=$2
            _required=$3
            initialise
            exit 0;;
        unlock|UNLOCK) 
            _operand="unlock";
            shift;;  
        --help) 
            displayHelp; exit 0;;
        --version) 
            displayVersion; exit 0;;
        -i) 
            _inFile="$2"
            shift;shift
            ;;
        -o) 
            _outFile="$2"
            shift;shift
            ;;
        -s) 
            _custodianKeysFile="$2"
            shift;shift
            ;;                        
        lock|LOCK) 
            _operand="lock"
            shift;;
        *) echo "Unknown parameter passed: $1"; echo "Try km --help for help"; exit 1;;
    esac 
done

if [ "$_operand" == "lock" ]; then
    lock
elif [ "$_operand" == "unlock" ]; then
    unlock
else
    echo "Try km --help for help";exit 1;
fi

## End ##
