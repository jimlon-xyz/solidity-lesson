

    部署一个私链节点

    第一步：https://geth.ethereum.org/downloads 下载  windows  (linux)  64bit 版本 1.10.*

    第二步：初始化 genesis.json 配置 创世块

            geth init --datadir {datadir} genesis.json

    第三步：初始化 POW 账户

            geth account new --datadir {datadir}

            0x2eB0BC9D4D68A74870ACBEf513aC839846Ba25EB

            

    第四步：启动本地 POW 节点  
            
            start.bat (linux start.sh) 文件

    第五步：浏览器 MetaMask 插件  添加网络