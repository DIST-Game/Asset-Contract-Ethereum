pragma solidity ^0.4.4;

contract AssetControllerContract {

    address internal proxyContractAddress;

    struct Asset {
        //基因，一般来说保持不变属性
        //最后20位作为同一类资产的索引号，来保持其唯一性
        uint256 genes;
        //这里status表示的是临时状态
        //从右向左：
        //1bit:0,未分配owner，1，表示已分配用户
       //2bit:0,未处于上市状态，1，处于上市状态
        //...
        uint16   status;
    }
    //所有资产的列表
    Asset[] internal assetSet;
    //从资产index到owner地址的映射
    mapping(uint256=>address) assertIndexToOwner;
    //从资产index到价格的映射，只有挂在市场的资产才有价格与之对应
    mapping(uint256=>uint256) assetIndexToPrices;
    //每一类资产当前数目
    mapping(uint256=>uint256) latestNumber;

    function AssetControllerContract(address _proxyContractAddress) public{
        proxyContractAddress = _proxyContractAddress;
    }

    /*
    function changeAttribute(uint256 hashIndex,string[] attributeNames,uint256[] values) public{
        require(msg.sender == assertIndexToOwner[hashIndex]);
        //获取value里面的key，然后根据key决定修改那个attribute
        for(uint256 index=0;index<attributeNames.length;index++){
            string memory attributeName = attributeNames[index];
            if(keccak256(attributeName)==keccak256("status")){
                assetSet[hashIndex].status = assetSet[hashIndex].status & uint16(values[index]);
            }
            else if(keccak256(attributeName)==keccak256("prices")){
                assetIndexToPrices[hashIndex] = values[index];
            }
            else if(keccak256(attributeName)==keccak256("owner")){
                assertIndexToOwner[hashIndex] = address(values[index]);
            }
            //to do other attribute
        }
    }
    */

    function launch(address caller,uint256 hashIndex, uint256 prices) public{
        require(caller == assertIndexToOwner[hashIndex]);
        assetSet[hashIndex].status = assetSet[hashIndex].status | 2;
        assetIndexToPrices[hashIndex] = prices;
    }

    function withdraw(address caller,uint256 hashIndex) public{
        require(caller== assertIndexToOwner[hashIndex]);
        assetSet[hashIndex].status = assetSet[hashIndex].status & 65533;
        //assetIndexToPrices[hashIndex] = prices;
    }

    function switchOwner(address caller,uint256 hashIndex) public{
        assetSet[hashIndex].status = assetSet[hashIndex].status & 65533;
        assertIndexToOwner[hashIndex] = caller;
    }

    function listGoods(uint256 gameIndex, uint256 showStartIndex) public constant returns(uint256[100] goodsList,uint8 len){
        uint8   tempIndex = 0;
        uint16  tmpCount = 0;
        //uint256 a = 0x0000FFFF00000000000000000000000000000000000000000000000000000000; 
        for(uint256 i=0;i<assetSet.length && tempIndex<100;i++){
            //if(assetSet[i].genes & a == gameIndex){
               if(assetSet[i].status & 2 != 0){
                   if(uint256(tmpCount)>=showStartIndex){
                       goodsList[tempIndex++]=i;
                   } 
                   tmpCount++;
               }
            //}
        }
        return (goodsList,tempIndex);
    }

    function generateAssetN(address caller,uint256 baseGenes,uint256 number) public returns(uint256 newStartIndex,uint256 newEndIndex){
        //生成指定数目个asset
        //调用generate方法生产Asset
        //将生成的assert加入到assertSet里面

        //1.查询当前这个baseGenes已经创建的个数
        uint256 latest = latestNumber[baseGenes];
        require(latest + number < 1048576);//2^20
        for(uint256 i=0;i<number;i++){
           var tmpgenes = baseGenes | latest;
            Asset memory _asset = Asset({
                genes : tmpgenes,
                status:0
                });
            uint256 index = assetSet.push(_asset) - 1;
            if(i==0){
                newStartIndex = index;
            }
            newEndIndex = index;
            latest++;
            //默认资产创建之后先分配給游戏发行者
            assertIndexToOwner[index]=caller;
        }
        latestNumber[baseGenes] = latest;
        return (newStartIndex,newEndIndex);
    }

    function getBaseGenesCount(uint256 baseGenes) public constant returns(uint256){
        return latestNumber[baseGenes];
    }

    function queryAsset(uint256 hashIndex) public constant returns(uint256 genes,uint16 status){
        require(hashIndex < assetSet.length);
        return (assetSet[hashIndex].genes, assetSet[hashIndex].status);
    }

    function approvalAsset(address caller,uint256 hashIndex,address newOwnerAddress) public {
        require(caller==assertIndexToOwner[hashIndex]);
        assertIndexToOwner[hashIndex]=newOwnerAddress;
    }

    function queryAssetPrice(uint256 hashIndex) public constant returns(uint256 prices){
        require(hashIndex < assetSet.length);
        require(assetSet[hashIndex].status & 2 == 1);
        return assetIndexToPrices[hashIndex];
    }
    
    function queryAssetOwner(uint256 hashIndex) public constant returns(address owner){
        require(hashIndex < assetSet.length);
        return assertIndexToOwner[hashIndex];
    }

    function querySelfAsset(address caller,uint256 queryStartIndex) public constant returns(uint256[100] assetIndexList, uint8 len){
        //uint256 startIndex = queryStartIndex;
        uint256 tmpIndex = 0;
        uint256 tmpCount = 0;
        for(uint256 i=0;i<assetSet.length && tmpIndex <100;i++){
            if(assertIndexToOwner[i] == caller){
                if(tmpCount>=queryStartIndex){
                    assetIndexList[tmpIndex++] = queryStartIndex+i;
                }
                tmpCount++;
            }
        }
        return (assetIndexList,uint8(tmpCount));
    }
    
    function queryMsgSender() public constant returns(address address1){
        return msg.sender;
    }
}
