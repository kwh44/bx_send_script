#!/bin/bash

# generate random seed value  
seed=$(bx seed)

# generate a private key from the seed value
privatekey=$(bx ec-new "$seed")

# generate bitcoin public key from the private key
publickey=$(bx ec-to-public "$privatekey")

# generate bitcoin address from the public key or insert already created one
address=myWg93cczRQYAkduZq2b28iP2S8MBp5M7z # $(bx ec-to-address $publickey)

# fetch the history of the address, some bitcoins must belong to the address provided
history=$(bx fetch-history --format=xml "$address")

# fetch the	transfers[0].received.hash
hash=$(xml select -t --match "/transfers/transfer/received" -v hash <<< "$history")

# fetch transaction details 
dits=$(bx fetch-tx --format=xml "$hash")

# fetch amount received 
amount=$(xml select -t --match "/transfers/transfer" -v value <<< "$history")

# subtract fee
amount=$((amount - 10000))

# wallet address of recipient or paste one of your choice
recipient_wallet=mkWjygaxCoTY2ywq8qjzHJpgz59HHRphVZ

# construct transaction 
transaction=$(bx tx-encode -i "$hash":0 -o "$recipient_wallet":"$amount")

# previous output script
previous_out_script=$(xml select -t --match "/transaction/outputs/output" -v script <<< "$dits")

# create an endorsement 
endorsement=$(bx input-sign "$privatekey" ${previous_out_script[0]} "$transaction")

# create an endorsement script 
transaction=$(bx input-set "[$endorsement] [$publickey]" "$transaction")

# broadcast the transaction to the blockchain
bx send-tx "$transaction"