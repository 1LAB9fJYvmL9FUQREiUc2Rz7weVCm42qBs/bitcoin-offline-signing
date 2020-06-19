# bitcoin
Offline Bitcoin Wallet - using pure OpenSSL and Linux to create transaction signatures byte-by-byte 

## Intro

Just as a teaser, allow us to introduce this framework in 'memento' style, going backwards in time:<br/>
At the end of the day, we were able to broadcast our manually crafted transaction into the blockchain by pasting it into blockchain.com:<br/>
![pushtx](/images/blockchain.com-pushtx.png)<br/>
<br/>
The characteristics of the transaction were the following:<br/>
- P2PKH (pay to public key hash)
- single unspent transaction output (utxo) as input to the current transaction
- multiple target addresses in compressed public key hash format
<br/>
Before broadcasting the transaction, we had verified it using blockchain.com's convenient "decode-tx" feature:<br/>
<br/>

## Objective

Inspired by a popular [bitcoin.stackexchange.com thread](https://bitcoin.stackexchange.com/questions/32628/redeeming-a-raw-transaction-step-by-step-example-required) we wanted to understand P2PKH transactions down to the byte level.<br/>
The goal was to (as an academic exercise) create some automated scripts that would let us parameterize and repeat the transaction signing process without using bitcoin libraries that would abstract the inner workings of the process.<br/>

## Trust and constraints

In terms of security, cryptocurrencies have a weak spot which is their private key.<br/>
Your assets will only be safe if all of the following conditions are met:<br/>
- you don't lose or forget your private key
- nobody except you (and the people that you fully trust) will _ever_ be able to see or otherwise copy your private key
- nobody except you (and the people that you fully trust) will _ever_ be able to _guess_ your private key
<br/>
While the first 2 conditions are manageable with discipline (by "cutting the wire" of your system and with the help of paper wallets), the 3rd condition arises as a question of _trust_ towards the software that you use:<br/>
When secret keys are generated, we need the guarantee that the source of it is _entropy_ (fully unpredictable bit streams). In case that a software/hardware combination had a backdoor that rendered "random" data generation more predictable, then guessing the private key could become feasible because the pool of 2ˆ256 possibilities (for a 32-byte bitcoin private key with uncompromised entropy) would be reduced to a much smaller pool which could make bruteforcing possible.<br/>
<br/>
Ideally, you would only trust software that you have fully _reviewed_ and understood, which is far from realistic even on our favourite system (which is Linux) with more lines of code than you can read of review in a lifetime. On the other hand, we make a tradeoff every day by using that system, out of the need that we have to trust _something_.<br/>
<br/>
As a consequence of the academic nature of our little project and the before mentioned security considerations, we came up with a __*constraint list*__ which focused on the avoidance of additional bitcoin libraries.<br/>
As per this list, we were allowed to use:<br/>
- OpenSSL as the _only_ cryptography library (which we use everyday anyway)<br/>
- standard tools available on most Linux systems<br/>
- as an additional constaint, private keys were _not_ supposed to ever reside on an online system, so we had two systems and their associated scripts in mind, one online sytem and one offline system.<br/>


