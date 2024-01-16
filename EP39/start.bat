@echo off
geth.exe ^
--identity "PDCHAIN" ^
--datadir "E:/eth/data/" ^
--http ^
--http.port "8545" ^
--http.addr "127.0.0.1" ^
--networkid 15701 ^
--http.api "eth,net,web3,personal" ^
console ^
--unlock "0x2eB0BC9D4D68A74870ACBEf513aC839846Ba25EB" ^
--password password.txt ^
--allow-insecure-unlock ^
--gcmode archive ^
--mine ^
--miner.threads 4 ^
--miner.gaslimit 30000000