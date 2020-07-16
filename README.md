# bitcoin transaction signing
Offline Bitcoin Transaction Signing - using pure __*OpenSSL*__ and _Linux_ to create transaction signatures byte-by-byte 

## Intro

Just as a _teaser_, allow us to introduce this framework in 'memento' style, going _backwards_ in time:<br/>
At the end of the day, we were able to broadcast our manually crafted transaction into the blockchain by pasting it into blockchain.com:<br/>

![pushtx](/images/blockchain.info-pushtx.png)<br/>

The above was the success message indicating that the submitted signature had been accepted. Here's the submission form with the bytes in hex format that we had been pasting:<br/>

![pushtx](/images/blockchain.com-btc-pushtx.png)

<br/>
<sup>In case that you're a newbie to blockchain technology, we want to avoid a misunderstanding of the site _blockchain.com_:<br/>
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


Going further back in time: How did we create the transaction signature in the first place?<br/>
It was our final transaction signing script _offline/sign.sh_ on the _offline_ computer that provided us with a __*QR code*__ which we scanned with our online system. See the tailed output of our signing session:<br/>

    txid: 180d08561d4f85e22bfcde890a17f353250c302e995042a1e42b226984e3e9da
    signedtransaction: 01000000010f8d95f4d84a7725f90251c4998f51eb47839fcc282b9bf917e2d61276a67e12000000006a47304402203127ad4a48b7265dae93d5b09c2211ca82775478542dca4acd926b94d0d1d65202202557027d26c265513fc84e3a62332770ed3dfec652f498139690b756b5384e1d01210345d57c07db0a538dd3dc2341cb6f80b780aa7a5a7750d29ce4f00f00874b3bf3ffffffff02e8030000000000001976a9149ff7fe77800570e8959bb953f4380ea442cb7f3288acb80b0000000000001976a914862c0a08e5aa3e1ea796a85f9af376848c0352c788ac00000000                                                                                                                                                                                         
    signedtransaction QR code:
                                                                                                                                                      
                                                                                                                                                      
                                                                                                                                                      
                                                                                                                                                      
            ██████████████  ██    ████    ██  ████████  ████    ████      ██  ██      ██    ██████    ████          ████    ██  ██████  ██████████████        
            ██          ██      ████████  ██      ████      ████  ██    ██████        ████    ████████        ████  ████████            ██          ██        
            ██  ██████  ██    ██    ██    ██████      ██████      ██████  ██  ██  ████████      ████  ██████████████    ██      ██      ██  ██████  ██        
            ██  ██████  ██        ████  ██████  ██████  ████    ██  ██  ██  ██  ██      ██  ██████  ██  ██████████████    ████      ██  ██  ██████  ██        
            ██  ██████  ██      ██████████████  ██  ████  ██    ██          ████████████████  ██    ████  ████  ██  ██████  ██  ██  ██  ██  ██████  ██        
            ██          ██    ██████    ██████  ████████  ████        ██    ██      ██      ██    ██    ██████      ██      ██  ██      ██          ██        
            ██████████████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████████████        
                            ████  ████    ████  ████████    ██    ████  ██████      ████████    ██  ██      ██████        ████  ██  ██                        
            ████  ████  ██      ██  ██        ██        ██  ██    ██  ████████████████  ████  ████████  ████          ████  ██  ██  ██  ██          ██        
            ██              ██  ████    ████    ████    ████  ████████  ██  ██  ██████  ████████  ████    ████    ████    ████    ██    ████    ██████        
            ████        ████    ██  ██      ████    ████  ████████  ██████████  ██        ████████  ██    ██    ████  ████  ██████  ████████████  ██          
            ██        ██      ██  ██████  ████      ██          ██  ██████  ██  ██████  ████████████      ████    ██████    ██    ████    ██    ████          
              ██    ██████████████    ██      ██    ██████████████  ██████  ██            ████  ████  ██████████  ████████  ██████    ██  ██  ██  ██          
            ████  ██  ██  ████    ████  ██    ██  ██████    ██████████  ██      ██████████          ██      ████████  ██            ████████    ██  ██        
                  ██  ████            ██    ██  ██    ████          ██████  ██  ██  ██  ██    ██  ██    ██  ██  ██    ██████      ██    ██████  ████          
            ██████              ██    ████████          ██  ████            ████████    ████    ██████    ██    ██  ██  ██████  ██  ██  ██  ██  ██  ██        
              ██████    ██      ██  ████    ██████  ████  ██      ██    ████  ██  ██  ██████    ██        ██  ██    ██  ██  ██    ██████    ██████            
                ██    ██    ████  ████        ████████  ████        ██  ██      ██████  ████      ██        ██    ██████  ████    ████    ████                
            ██  ████████████  ██████  ██  ██  ██  ████  ██    ██  ████████████  ████████████████████████  ██      ██    ████████      ██  ████████████        
              ██████  ██  ██████        ██        ██  ██          ██  ██  ████  ████            ██████      ██      ██████  ██  ██  ██████  ██    ████        
              ██████    ████  ████████  ██  ██      ████████  ██    ██  ████          ██  ██████      ██████  ██    ████  ██    ██    ██    ████  ████        
            ████      ██        ██  ██  ████  ██    ████    ██  ██    ██    ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████████████  ██  ██        ████            
                    ██████    ██████    ██████    ██    ████    ████        ████  ████  ████    ██    ██  ██  ██████  ██  ██  ██  ██    ████  ██    ██        
                ████  ██            ██        ████      ██    ████  ████      ████            ██    ██            ██  ████████      ██  ████  ██              
              ████████████    ██      ██    ██    ██████  ████████    ████████████████  ██████    ████  ████      ████  ██████  ████    ████  ██  ████        
            ████      ██  ████    ██████          ██  ██    ████        ██████      ████  ████  ██    ████████████████          ██  ████  ██  ████  ██        
              ██  ██  ██████  ████          ██  ██    ██    ████  ██    ████    ██████  ████  ██████  ████  ██    ████████████  ████  ██  ██  ██████          
                ██  ████  ██████  ██    ██  ████          ██    ██████████████      ██  ██  ██              ██      ██          ██  ██    ██    ██  ██        
                ████  ██████  ██  ██    ████████████████        ██  ████          ██  ██    ██  ██  ██    ████  ██      ████████      ████████    ██          
            ██  ████          ██████████    ██      ████  ██        ██  ████████    ██      ██████████    ████        ████  ██████████      ████████          
            ████      ████    ██████    ██████████    ██████      ████  ██    ██████    ████  ██  ████████████        ██████████  ████    ██  ████████        
            ██████    ██      ██  ██            ████        ██  ██        ██████  ████████        ████  ██  ██████        ██      ████████████  ██  ██        
              ████  ██████████  ██    ██  ████  ██    ████  ██    ████████  ██████████    ██  ██    ██      ██        ██████        ██████████  ████          
            ██  ██████      ████  ██  ████████  ████████        ██      ██████      ████  ████  ██████  ████      ████    ██    ██  ██      ██  ██            
            ████    ██  ██  ████  ████  ████  ████  ████  ████  ██    ████  ██  ██  ██  ████    ██  ████  ██      ██  ██      ██  ████  ██  ██  ██  ██        
            ██    ████      ████████    ██  ████    ██  ████  ██            ██      ██████    ██  ██    ████    ██      ██      ██  ██      ████              
            ██      ████████████████  ████    ████    ██  ████  ████████████████████████  ██  ████  ████████    ██  ████    ██████  ██████████  ██████        
              ████  ████  ██  ████  ██      ████  ██  ██    ████    ████  ██  ██    ██████        ████    ██  ████      ██████      ██  ██      ██████        
                ██  ██  ████    ████    ██  ██  ████  ██    ██    ██████  ██  ██  ████    ████  ████        ████  ██  ██  ████████      ██      ████          
            ████  ██████    ██  ██  ██  ██      ████    ██  ██        ██████  ██        ████        ██          ████    ██          ██  ██      ██  ██        
                  ████████████████    ██  ██      ████  ██████████      ██    ██    ██████████          ████  ████████  ██                ████████████        
              ████        ██      ████    ██    ██████  ██      ██████  ██████    ██    ████████████    ██  ██  ████████  ██  ██          ██████              
            ████████  ████  ██      ████  ██  ██████████████████████  ████  ██  ██    ██████  ██  ██      ████    ██████  ████████████████  ██████████        
            ████  ████    ████████  ██    ████      ██        ██████    ██████        ██  ██  ██  ██  ████  ██████    ██      ██  ████████  ██  ██████        
            ████████    ████████  ██    ██████        ██      ██  ████  ██        ████    ██████████  ██    ████  ██      ██    ████  ██  ██  ██  ██          
            ██    ██████  ████  ██      ██████  ██  ██████████  ██████  ██    ████    ██      ████  ██      ██████  ██████  ██████  ██████    ██████          
            ██  ██████████████    ██          ██████████  ████  ████  ██████  ████  ██  ██          ████  ████    ██████████████████            ██            
            ████  ██████    ██              ██████    ██████████  ████      ████    ██      ████████      ████  ██    ██████        ██████  ██████  ██        
            ██████      ██████████  ██      ██████  ████  ████████  ██████    ████████  ████      ██    ██████  ████    ████    ██████  ██  ████  ██          
              ██████████            ██████  ██  ██████    ██  ██████  ██    ██████    ██  ██    ██  ██  ████  ██  ██        ██  ████    ██  ██                
              ██  ██    ████  ████  ████    ██  ██████    ██  ██  ████  ████████  ████  ████████  ████      ████  ██    ████          ██  ████████████        
                  ██  ██    ██████      ██████  ████    ██████  ██    ████████████  ██      ██  ██  ██  ██  ████  ██    ██████████  ████        ██  ██        
            ██  ██  ██  ██  ████████  ████    ██  ██████████████████████    ██        ██████  ████  ██    ████  ████      ██  ██  ██      ████  ██  ██        
              ██████  ██      ██████████              ████████████  ██████  ████████████  ██  ████    ██████████    ██████          ████  ██  ████  ██        
              ████  ██████████  ██████    ██████████      ██  ████    ██      ██  ██  ████████    ████  ██  ██  ████      ██    ████  ██    ████    ██        
            ██        ██  ████    ██    ████████████  ██        ██    ████  ██      ████          ██      ██████  ██        ██    ██  ██      ████████        
            ████████████████  ██████  ████████            ██████  ██      ██████  ██      ██  ████████      ██    ████████████                  ██  ██        
            ████  ██████  ████  ████  ██    ████████    ████    ██████  ██      ██  ██    ████    ████  ████  ██  ██      ████  ████  ████  ██                
            ██  ██  ████████    ██  ██  ████  ██    ████████    ██████████  ██  ██    ██████████          ██    ██████████    ██████  ██        ██  ██        
            ██                ██  ██        ██████████    ████    ████████        ██        ████      ██    ██    ████    ████  ██  ██  ██████████            
            ██    ████  ██████  ██  ██    ██  ████    ████████████████████████████████  ██████  ██████  ████████  ██  ████████  ██████████████    ████        
                            ████  ██  ██  ██    ████████    ██████  ██  ██████      ████        ██████  ██  ████████      ████    ████      ██  ██  ██        
            ██████████████      ████  ██  ████  ████  ██    ████    ██████████  ██  ██████████  ████  ██    ██          ██        ████  ██  ██  ████          
            ██          ██    ██      ████████  ████    ██  ██  ██████    ████      ██    ██    ██████      ██    ████              ██      ██  ██            
            ██  ██████  ██  ██      ████  ██  ████  ██  ██  ██  ██      ██  ████████████████    ██  ██    ██  ██  ██        ██      ██████████████  ██        
            ██  ██████  ██  ██    ██      ██  ████    ██████      ████████          ██  ████      ████      ██    ██  ████████    ██    ██    ██              
            ██  ██████  ██    ████    ██  ██████████  ██  ████    ██  ██████  ██  ██████  ██████████      ██████  ██    ██████      ██    ████  ██████        
            ██          ██  ██          ████                ██████████████        ████    ██    ██████  ██  ████  ████  ██  ██  ████  ████████  ██  ██        
            ██████████████  ██              ██        ██  ████  ██  ██    ██      ████    ████    ██    ██  ██    ████    ██    ██  ████████  ██████          
                                                                                                                                                      
                                                                                                                                                      
                                                                                                                                                      
                                                                                                                                                      
    For verification, paste your signedtransaction into https://blockchain.com/btc/decode-tx and check if everything looks as you planned.
    After verification, paste your signedtransaction into https://blockchain.com/btc/pushtx to broadcast it.
    Once you have successfully broadcast your tansaction, watch its status on the blockchain: https://blockchain.com/btc/tx/180d08561d4f85e22bfcde890a17f353250c302e995042a1e42b226984e3e9da.


Want to know more? For a detailed chronological usage example, see:

[USAGE.md](USAGE.md)

<br/>

## Objective

Inspired by a popular [bitcoin.stackexchange.com thread](https://bitcoin.stackexchange.com/questions/32628/redeeming-a-raw-transaction-step-by-step-example-required) we wanted to understand P2PKH transactions down to the byte level.<br/>
We soon discovered that the topic of the stackexchange thread had its functional restrictions because it only described a transaction to a _single_ output in uncompressed format.<br/>
As an academic exercise, our goal was to create some automated _bash_ scripts that would let us parameterize __*multiple inputs and outputs*__ (think of change addresses for example) and repeat the transaction signing process without using bitcoin libraries that would abstract the inner workings of the process.<br/>

## Trust

In terms of security, cryptocurrencies have a weak spot which is their private key.<br/>
Your assets will only be safe if all of the following conditions are met:<br/>

- you don't lose or forget your private key
- nobody except you (and the people that you fully trust) will _ever_ be able to see or otherwise copy your private key
- nobody except you (and the people that you fully trust) will _ever_ be able to __*guess*__ your private key

While the first 2 conditions are manageable with personal discipline, (e.g. by "cutting the wire" of your system and with the help of paper wallets), the 3rd condition arises as a question of _trust_ towards the software that you use:<br/>
When secret keys are generated, we need the guarantee that the source of it is _entropy_ (fully unpredictable bit streams). In case that a software/hardware combination had a backdoor that rendered supposedly "random" data generation more predictable, then guessing the private key could become feasible because the pool of 2ˆ256 possibilities (for a 32-byte bitcoin private key with uncompromised entropy) would be reduced to a much smaller pool which could make bruteforcing possible.<br/>
Please read the details of our approach to entropy here: [ENTROPY.md](ENTROPY.md) <br/>
<br/>
<sub>On a sidenote: Ideally, you would only trust software that you have fully _reviewed_ and understood, which is far from realistic, considering that our favourite Linux system has been compiled from more lines of code than either one of us could read or review in a lifetime. On the other hand, for open-source systems it's the _community_ that is always free to review the code and keep the software quality and reliability on a high level.<br/>
Can you trust _us_? Of course not. Not unless you (or somebody that you trust) have reviewed our code.<br/>
The good news is that our code is very lightweight, so anyone who is good in bash scripting and has an understanding of cryptographic hashes can quickly understand what we're doing here.</sub>
<br/>

## Design

As a consequence of the academic nature of our little project and the before mentioned trust considerations, we came up with a __*constraint list*__ which avoids the use of additional bitcoin libraries.<br/>
As per this list, we were allowed to use:<br/>

- OpenSSL as the _only_ cryptography library (given the fact that _we_ use to use it on a day-to-day basis anyway)<br/>
- standard tools available on most Linux systems<br/>
- as an additional constaint, private keys were _not_ supposed to ever reside on an online system<br/>

Given this _constaint list_, we came up with a design that has _two_ systems and their associated scripts in mind, one __*online sytem*__ and one __*offline system*__ (also called __*airgap*__).<br/>
This is reflected in the folder structure, with the scripts that deal with __*private keys*__ _only_ being available underneath the _offline_ folder.

## Restrictions and disadvantages

The current set of signature scripts _only_ supports P2PKH transactions, segregated witness and P2SH transactions are not yet supported. Multisig transactions are not yet supported either.<br/>
<br/>
Critics will argument that it is recommendable to use existing bitcoin libraries because of their maturity level and because of their ease-of-use. Although the same holds true for OpenSSL, they have a valid point.<br/>
However, besides the fact that we only need a _subset_ of the functionality that a fullblown bitcoin lib offered, our goal is different as we aim to debug down to the bit level without having a library abstract implementation details from us, and we guess that we have an audience of people who have the same curiousity and want to see how signatures can be done in the __*bash*__ shell with the tools that they're familiar with.

## Requirements

- Linux (we used an up-to-date Debian)
- OpenSSL (we used preinstalled version 1.1.1)
- xxd (we used the preinstalled V1.10)
- base58 (is a lightweight package, we installed it with "sudo apt install base58")
- qrencode (is a lightweight package, we installed it with "sudo apt install qrencode") 
- xmlstarlet (we used the preinstalled version 1.6.1)

<br/>
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, LOSS OF FUNDS OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
