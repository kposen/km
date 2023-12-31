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


write_to_file(){
     # initialize a local var
     local _file="$1"
     local _data="$2"

     if [ ! -f "$_file" ] ; then
         touch "$_file"
     fi

    echo -e "$_data" >> "$_file"
 }

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
    echo "";
    echo "    lock -i [file]                       created the encrypted file.enc and a custodian.keys file";
    echo "";
    echo "    unlock -i [encrypted_file] -o [file] -s [custodians.keys]";
    echo "                                         decrypts the [encrypted_file] using the key parts provided";
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
    _iv=$(openssl rand -hex 16)
    _salt=$(openssl rand -hex 16)

    echo "key=$_key iv=$_iv salt=$_salt "
    # AES(file,key,iv,salt) > file.enc
    openssl enc -aes-128-cbc -pbkdf2 -K $_key -S $_salt -iv $_iv -in $_inFile -out $_outFile

    # Perform Shamir secret sharing scheme on key+iv+salt ==> 48 bytes (128 bits x 3)
    # We limited the key length to 128 bits to avoid over length input into ssss-split.
    _custodians="$(cat km.conf |grep custodians | awk -F: '{print $2}')"
    _required="$(cat km.conf |grep required | awk -F: '{print $2}')"
    eval $(echo "echo '$_key$_iv$_salt' | ssss-split -t $_required -n $_custodians -w km > $_custodianKeysFile")
}

function unlock(){
    # create a custodian key part file, on key per line
    # read in the custodian keys and the encrypted file and produce the unencrypted output
    _custodians="$(cat km.conf |grep custodians | awk -F: '{print $2}')"
    _required="$(cat km.conf |grep required | awk -F: '{print $2}')"

    # read in $_required lines from the $_custodianKeysFile - each line is a km_key"
    declare -a km_keys
    while IFS= read -r line; do 
        if [ ${line:0:3} == "km-" ]; then 
            km_keys+=("$line")
            if [ ${#km_keys[@]} -eq $_required ]; then break;fi
        fi
    done < $_custodianKeysFile
    if [ $_required -ne ${#km_keys[@]} ]; then
      echo "Incorrect number of Shamir key parts."
      echo "Expecting $_required key parts and got ${#km_keys[@]} - aborting!."
      exit 1
    fi

    _split=""
    for i in "${km_keys[@]}"
        do
            _split=$_split"$i\n"
        done
    _split="ssss-combine -q -t $_required <<EOF\n"$_split"EOF\n"
    rm -rf km.tmp~ 2>/dev/null
    write_to_file "km.tmp~" "$_split"
    echo ""
    _secret=$(script -q -c 'source km.tmp~')
    rm -rf km.tmp~
    echo "$_secret"

    _key=${_secret:0:32} 
    _iv=${_secret:32:32}
    _salt=${_secret:64:32}

    echo "key=$_key iv=$_iv salt=$_salt" 
    openssl enc -d -aes-128-cbc -pbkdf2 -K $_key -S $_salt -iv $_iv -in $_inFile -out $_outFile

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