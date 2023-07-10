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
    --help                               display this help
    --version                            display the version of km
    --initialise [custodians] [required]
                                         initialise for a given number of custodians
                                         and parts required to reconstitute.

    lock -i [file]                       created the encrypted file.enc and a custodian.keys file

    unlock -i [encrypted_file] -o [file] -s [custodians.keys]
                                         decrypts the [encrypted_file] using the key parts provided

  EXAMPLE(s):
    km --initialise 5 2                                       # create a km.conf file
    km lock -i sample.txt -o sample.enc -s custodian.keys     # creates the encrypted file & custodian.keys
    km unlock -i sample.enc -o sample.txt -s custodian.keys   # use at least r of n keys in custodian.keys
    km --version
```
### How to install

Clone & copy the executable, and then remove the repo source if not required.

```
sudo apt install ssss
git clone git@github.com:kposen/mk.git
sudo cp mk/mk.sh $HOME/.local/bin/mk
sudo chmod +x $HOME/.local/bin/mk
rm -rf mk/
```
To confirm it is installed correctly simply execute `km --help` at the command prompt.

### How to test
 To test start by creating a largish 10 Mb sample file:
 ```
 fallocate -l 10M sample.txt && echo "my sample file..." >> sample.txt && cat sample.txt
 ```
 This may take a second or two to read through the empty file and finally display your last line in plain text.

 Before we begin we will create a SHA256 of our test `sample.txt` file for later comparison, as follows:
 ```
 cat sample.txt | sha256sum > km.sha256 
 ```
 

 Then we run `km --initialise 5 3` to initialise our Shamir algorithm to expect a 3/5 custodians to be able to unlock the encrypted sample file.

 Now we may encrypt our `sample.txt` file as follows:
 ```
 km lock -i sample.txt -o sample.enc -s custodian.keys 
 ```
 This will encrypt your sample.txt file and create a custodian keys file that looks something like the following:
 ```
 Generating shares using a (3,5) scheme with dynamic security level.
km-1-0480ab0dd4a3e58979dcc0a54271f1c6b9b21fcf975e5e7f209d9e360dcd99796c528bc8fc01d35dd3d6460d4a17cf0ed5c7e302c3bfcafb6653c297dec5b39c0c3ad0f767cb0c206af8488cea73564a4558815f4a2c689ec7cc1c66f1f65a42
km-2-fad281823cd70c08ad6c7af6dff3fc47c7707d25395269a13b640dbb8952b0d082a0cff7a93ec063e330e982cae1e2a1b175017d70c12124a50a2dd6b0735634f75921127981c97a5dc380e7dcb4df6c477b0d7181604030128e636489fa9f2c
km-3-11102bea463ed63b2114e3624b5afb609381832b324d97d1711253790c3c4b6107e8027cb9273a2d4793bad484c588795169b0f377407f7eab7daffb907bb8bd983875ed9c900e85af7bd3e5ee9e2e93d06d60c0edf94595d792682e3e60e23d
km-4-908281823cd70c08ad6c7af6dff3fc47c7707d25395269a13b640dbb8952b0d082a0cff7a93ec063e330e982cae1e2a1b175017d70c12124a50a2dd6b0735634f75921127981c97a5dc380e7dcb4df6c477b0d7181604030128e636489fa9f4e
km-5-43102bea463ed63b2114e3624b5afb609381832b324d97d1711253790c3c4b6107e8027cb9273a2d4793bad484c588795169b0f377407f7eab7daffb907bb8bd983875ed9c900e85af7bd3e5ee9e2e93d06d60c0edf94595d792682e3e60e269
 ```

These keys may be distributed one each to a key custodian.

---
Now, in order to put *Humpty Dumpty* together again you require at least 3 of the key parts and the `sample.enc` encrypted file.

Copy any three keys from any three key custodians and paste these one per line in a text file.  We arbitrarily call this file `custodian.key.parts` 

Now we are ready to proceed:
```
km unlock -i sample.enc -o sample.plaintext -s custodian.key.parts
```

And you may confirm your file by `cat sample.plaintext` and seeing the last line being your plain text as before or you may compare the SHA256 created during testing above as follows:
```
cat sample.plaintext | sha256sum -c km.sha256
```
And that is all there is to it ...

---
### References:

1. [ssss](https://linux.die.net/man/1/ssss) - Shamir's Secret Sharing Scheme
2. [Cryptography for Devs](https://github.com/Cyber-Mint/c4devs/blob/master/README.md)
   
---
Copyright &copy; 2023, Kevin Posen<br>
Licensed under [MIT](./LICENSE)