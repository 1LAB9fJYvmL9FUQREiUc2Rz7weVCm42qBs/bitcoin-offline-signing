# bitcoin
Offline Bitcoin Wallet - using pure OpenSSL and Linux to create transaction signatures byte-by-byte 

## Intro

Just as a teaser, allow us to introduce this framework in memento style:<br/>
At the end of the day, we we were able to broadcast our manually crafted transaction into the blockchain by pasting it into blockchain.com:<br/>
![pushtx](/images/blockchain.com-pushtx.png)
<br/>
The characteristics of the transaction were the following:<br/>
- P2PKH (pay to public key hash)
- single unspent transaction output (utxo) as input to the current transaction
- multiple target addresses in compressed public key hash format
<br/>
Before broadcasting the transaction, we verified it using blockchain.com's convenient "decode-tx" feature:<br/>
<br/>
## Objective<br/>

Inspired by a popular [bitcoin.stackexchange.com thread](https://bitcoin.stackexchange.com/questions/32628/redeeming-a-raw-transaction-step-by-step-example-required) we wanted to understand P2PKH transactions down to the byte level.<br/>
The goal was to create some automated scripts that would let us parameterize and repeat the transaction signing process without using bitcoin libraries that would abstract the inner workings of the process.<br/>
<br/>
## Trust and constraints

In terms of security, cryptocurrencies have a weak spot which is their private key.<br/>
Your assets will only be safe if all of the following conditions are met:<br/>
- you don't lose or forget your private key
- nobody except you (and the people that you fully trust) will _ever_ be able to see or otherwise copy your private key
- nobody except you (and the people that you fully trust) will _ever_ be able to _guess_ your private key
<br/>
While you can manage the first 2 conditions with discipline (and the help of paper wallets and "cutting the wire" of your sytem) quite well, the 3rd condition arises as a question of _trust_ towards the software that you use:<br/>
When secret keys are generated, we need the guarantee that the source of it is entropy (fully unpredictable bit streams). In case that a software/hardware combination had a backdoor that rendered that data generation more predictable, resulting in a pool of far less possibilities, guessing the privatethe pool of 2ˆ256 possibilities (for a 32-byte bitcoin private key) would be reduced to a 
Ideally, you would only trust software that you have fully _reviewed_ and understood, which is far from realistic even on our most secure system (which is Linux) with more lines of code than you can read of review in a lifetime. On the other hand, we make a tradeoff every day by using the system, out of the need that we have to trust _something_.<br/>
<br/>
As a consequence, we came up with a constraint list which focused on the avoidance of additional bitcoin libraries.<br/>
As per this list, we were allowed to use:<br/>
- OpenSSL as the _only_ cryptography library (which we use everyday anyway)<br/>
- standard tools available on most Linux systems
- as an additional constaint, private keys were _not_ supposed to ever reside on an online system, so we had two systems and their associated scripts in mind, one online sytem and one offline system.<br/>


