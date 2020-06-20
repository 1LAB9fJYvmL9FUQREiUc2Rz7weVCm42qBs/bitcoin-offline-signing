# bitcoin
Offline Bitcoin Wallet - using pure OpenSSL and Linux to create transaction signatures byte-by-byte 

## Intro

Just as a teaser, allow us to introduce this framework in 'memento' style, going _backwards_ in time:<br/>
At the end of the day, we were able to broadcast our manually crafted transaction into the blockchain by pasting it into blockchain.com:<br/>

![pushtx](/images/blockchain.info-pushtx.png)<br/>

The above was the success message indicating that the submitted signature had been accepted. Here's the submission form with the bytes in hex format that we had been pasting:<br/>

![pushtx](/images/blockchain.com-btc-pushtx.png)

<br/>
<sup>In case that you're a newbie to blockchain technology, we want to avoid a misunderstanding of the site blockchain.com:<br/>
It is just one of MANY blockchain explorers that lets you query data of the public decentralized blockchain.<br/></sup>
Notice the "tip" in the upper part of the "Broadcast transaction" screen: Of course we had taken the chance to conveniently verify our decoded transaction details before submission. Here's the decoded transaction:<br/>

    {
      "version": 1,
      "locktime": 0,
      "ins": [
        {
          "n": 0,
          "script": {
            "asm": "304402203127ad4a48b7265dae93d5b09c2211ca82775478542dca4acd926b94d0d1d65202202557027d26c265513fc84e3a62332770ed3dfec652f498139690b756b5384e1d01 0345d57c07db0a538dd3dc2341cb6f80b780aa7a5a7750d29ce4f00f00874b3bf3",
            "hex": "47304402203127ad4a48b7265dae93d5b09c2211ca82775478542dca4acd926b94d0d1d65202202557027d26c265513fc84e3a62332770ed3dfec652f498139690b756b5384e1d01210345d57c07db0a538dd3dc2341cb6f80b780aa7a5a7750d29ce4f00f00874b3bf3"
          },
          "sequence": 4294967295,
          "txid": "127ea67612d6e217f99b2b28cc9f8347eb518f99c45102f925774ad8f4958d0f",
          "witness": []
        }
      ],
      "outs": [
        {
          "script": {
            "addresses": [
              "1FaqXRmQiYyGizWS9fK3GN6Y9GeSxPyRt1"
            ],
            "asm": "OP_DUP OP_HASH160 9ff7fe77800570e8959bb953f4380ea442cb7f32 OP_EQUALVERIFY OP_CHECKSIG",
            "hex": "76a9149ff7fe77800570e8959bb953f4380ea442cb7f3288ac"
          },
          "value": 1000
        },
        {
          "script": {
            "addresses": [
              "1DESJbwXNkqbFWuTnygNnGWtzz85KNSfKm"
            ],
            "asm": "OP_DUP OP_HASH160 862c0a08e5aa3e1ea796a85f9af376848c0352c7 OP_EQUALVERIFY OP_CHECKSIG",
            "hex": "76a914862c0a08e5aa3e1ea796a85f9af376848c0352c788ac"
          },
          "value": 3000
        }
      ],
      "hash": "180d08561d4f85e22bfcde890a17f353250c302e995042a1e42b226984e3e9da",
      "txid": "180d08561d4f85e22bfcde890a17f353250c302e995042a1e42b226984e3e9da"
    }

As you can see, this is a transaction sending a couple of satoshis to 2 separate recipient addresses.<br/>
The characteristics of the transaction are the following:

- P2PKH (pay to public key hash)
- single unspent transaction output (utxo) of the previous transaction (_127ea67612d6e217f99b2b28cc9f8347eb518f99c45102f925774ad8f4958d0f_)
- multiple target addresses (_1FaqXRmQiYyGizWS9fK3GN6Y9GeSxPyRt1_ and _1DESJbwXNkqbFWuTnygNnGWtzz85KNSfKm_) in compressed public key hash format

<br/>
Going further back in time: How did we create the transaction signature in the first place?<br/>
Answer: For a detailed usage example, see:

[USAGE.md](USAGE.md)

<br/>

## Objective

Inspired by a popular [bitcoin.stackexchange.com thread](https://bitcoin.stackexchange.com/questions/32628/redeeming-a-raw-transaction-step-by-step-example-required) we wanted to understand P2PKH transactions down to the byte level.<br/>
We soon discovered that the topic of the stackexchange thread had its functional restrictions because it only described a transaction to a _single_ output in uncompressed format.<br/>
As an academic exercise, our goal was to create some automated _bash_ scripts that would let us parameterize _multiple_ outputs (think of change addresses for example) and repeat the transaction signing process without using bitcoin libraries that would abstract the inner workings of the process.<br/>

## Trust and constraints

In terms of security, cryptocurrencies have a weak spot which is their private key.<br/>
Your assets will only be safe if all of the following conditions are met:<br/>

- you don't lose or forget your private key
- nobody except you (and the people that you fully trust) will _ever_ be able to see or otherwise copy your private key
- nobody except you (and the people that you fully trust) will _ever_ be able to _guess_ your private key

While the first 2 conditions are manageable with personal discipline, (e.g. by "cutting the wire" of your system and with the help of paper wallets), the 3rd condition arises as a question of _trust_ towards the software that you use:<br/>
When secret keys are generated, we need the guarantee that the source of it is _entropy_ (fully unpredictable bit streams). In case that a software/hardware combination had a backdoor that rendered "random" data generation more predictable, then guessing the private key could become feasible because the pool of 2ˆ256 possibilities (for a 32-byte bitcoin private key with uncompromised entropy) would be reduced to a much smaller pool which could make bruteforcing possible.<br/>
<br/>
Ideally, you would only trust software that you have fully _reviewed_ and understood, which is far from realistic, considering that our favourite Linux system has been compiled from more lines of code than either one of us could read or review in a lifetime. On the other hand, for open-source systems it's the community that is always free to review the code and keep the software quality and reliability on a high level. To make a long story short, we make a tradeoff every day by _using_ our system, out of the need that we have to trust _something_.<br/>
<br/>
As a consequence of the academic nature of our little project and the before mentioned security considerations, we came up with a __*constraint list*__ which focuses on the avoidance of additional bitcoin libraries.<br/>
As per this list, we were allowed to use:<br/>
- OpenSSL as the _only_ cryptography library (we use it on a day-to-day basis anyway)<br/>
- standard tools available on most Linux systems<br/>
- as an additional constaint, private keys were _not_ supposed to ever reside on an online system

## Design

Given the before mentioned _constaint list_, we came up with a design that has _two_ systems and their associated scripts in mind, one __*online sytem*__ and one __*offline system*__.<br/>
This is reflected in the folder structure, with the scripts that deal with __*private keys*__ _only_ being available underneath the _offline_ folder.

## Restrictions and disadvantages

The current set of signature scripts _only_ supports P2PKH transactions, segregated witness and P2SH transactions are not yet supported. Multisig transactions are not yet supported either.<br/>
<br/>
Also, some critics will argument that it is recommendable to use existing bitcoin libraries because of their maturity level, because of the fact that they are tested assets and because of their ease-of-use. Although the same holds true for OpenSSL, they have a valid point.<br/>
However, besides the fact that we only need a subset of the functionality, our goal is different as we aim to go down to the bit level without having a library abstract implementation details from us, and we guess that we have an audience of people who have the same curiousity and want to see how signatures can be done in the __*bash*__ shell with the tools that they're familiar with.

## Prerequisites

- Linux (we used an up-to-date Debian)
- OpenSSL (we used preinstalled version 1.1.1)
- xxd (we used the preinstalled V1.10)
- base58 (we installed it with "sudo apt install base58")
- xmlstarlet (we used the preinstalled version 1.6.1)


