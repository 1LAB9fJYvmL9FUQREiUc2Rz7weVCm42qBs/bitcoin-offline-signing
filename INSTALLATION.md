# Installation

## Hardware requirements

Make sure that, besides your _online_ Linux system, you have another "_airgap_" Linux system available, which should:<br/>

- be _offline_ (which means that it should, from the time of first private key creation onwards, never be connected to the internet or to any other system that might be compromised/connected)
- have reliable storage for your private keys (still, you will need to have a backup plan for your private keys, preferably on paper. But do _not_ use a printer that's connected to the internet.)

## ONLINE system

On the _online_ system, clone this github repository underneath a folder of your choice:<br/>
`git clone git@github.com:1LAB9fJYvmL9FUQREiUc2Rz7weVCm42qBs/bitcoin.git`

If you don't have `git` installed, use the https download option of the repository.<br/>
A _bitcoin_ folder should have been created. Make a copy of that folder and all of its subfolders and store it on a clean thumb drive.

## AIRGAP system

Make sure that the requirements (see [Requirements](README.md#Requirements)) are met.<br/>
Then copy the _bitcoin_ folder and all of its subfolders from your thumb drive to a location of your choice on the _offline_ system.<br/>

## ONLINE system

As a precautionary measure, _delete_ the subfolder called _offline_ from your _online_ system. This will prevent human mistake, like creating private keys on an online system.<br/>
Make sure that the requirements (see [Requirements](README.md#Requirements)) are met.<br/>
