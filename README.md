# Kevin's Magic
> **km ver 0.9** is a linux utility to securely encrypt a file and using Shamir's secret sharing algorithm
>  break the keys into key parts, allowing a certain number of key parts to rebuild the key required
>  to decrypt the file again later.

### Usage:
```
Usage km [COMMAND] [OPTIONS]
ver 0.9
   Kevin's Magic (km) is a wrapper to encrypt a payload, split the master-key to be distributed
   to the key custodians, and then join it all back together again.

  [COMMAND]:
    --initialise [custodians] [required] [--force]
                                         initialise for a given number of custodians
                                         and parts required to reconstitute.
                                         Where a .conf already exists the optional --force
                                         will regenerate the master-key instead of only just
                                         regenerating the custodian key parts.

    lock -i [file]                       created the encrypted file.enc and a custodian.keys file

    unlock -i [file.enc] -o [file] -s [custodians.keys]  
                                         decrypts the [file]using the key parts provided

  EXAMPLE(s):
    km --initialise 5 2                                       # create a km.conf file
    km lock -i sample.txt -o sample.enc -s custodian.keys     # creates the encrypted file & custodian.keys 
    km unlock -i sample.enc -o sample.txt  -s custodian.keys  # use at least r of n keys in custodian.keys
    km --version
```

### References:

1. [ssss](https://linux.die.net/man/1/ssss) - Shamir's Secret Sharing Scheme
2. [Cryptography for Devs](https://github.com/Cyber-Mint/c4devs/blob/master/README.md)



---
Copyright &copy; 2023, Kevin Posen<br>
Licensed under [MIT](./LICENSE)