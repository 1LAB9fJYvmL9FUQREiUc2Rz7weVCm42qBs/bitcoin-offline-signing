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
![decode-tx](/images/blockchain.com-decode-tx.png)
<br/>
## Objective<br/>

Inspired by a popular ![bitcoin.stackexchange.com thread](https://bitcoin.stackexchange.com/questions/32628/redeeming-a-raw-transaction-step-by-step-example-required) we wanted to understand P2PKH transactions down to the byte level.<br/>
The goal was to create some automated scripts that would let us parameterize and repeat the transaction signing process without using bitcoin libraries that would abstract the inner workings of the process.<br/>
<br/>
## Trust and constraints

In terms of security, cryptocurrencies have a weak spot which is their private key.<br/>
Your assets will only be safe if all of the following conditions are met:<br/>
- you don't lose or forget yout private key
- nobody except you (and the people that you fully trust) will _ever_ be able to see or otherwise copy your private key
- nobody except you (and the people that you fully trust) will _ever_ be able to guess your private key
<br/>
While you can manage the first 2 conditions with discipline (and the help of paper wallets) quite well, the 3rd condition arises as a question of _trust_ towards that the software that you use:<br/>

