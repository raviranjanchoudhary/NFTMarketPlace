// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AddressUtils.sol";

contract BidProcess{

    using AddressUtils for address;

    event CreateNewBid(uint256 _index, address _creator, address _asset, address _token);
    event NewBid(uint256 _index, address _bidder, uint256 _amount);
    event Claim(uint256 _bidIndex, address _claimer);

    
    enum Status { pending, active, finished }

    struct BidInfo{
        address assetAddress;
        uint256 assetId;
        address tokenAddress;
        address creator;
        uint256 startTime;
        uint256 duration;
        uint256 currentBidAmount;
        address currentBidOwner;
        uint256 bidCount;
    }

    BidInfo[] private bidings;

    function createNewBid(address _assetAddress,
                          uint256 _assetId,
                          address _tokenAddress,
                          uint256 _startPrice,
                          uint256 _startTime,
                          uint256 _duration) public returns(uint256){
        require(_assetAddress.isContract());
        ERC721 asset = ERC721(_assetAddress);
        require(asset.ownerOf(_assetId)==msg.sender);
        require(asset.getApproved(_assetId)==address(this));
        require(_tokenAddress.isContract());

        if(_startTime==0){
            _startTime=block.timestamp;
        }

        BidInfo memory bidInfo = BidInfo({
            assetAddress:_assetAddress,
            assetId:_assetId,
            tokenAddress:_tokenAddress,
            creator:msg.sender,
            startTime:_startTime,
            duration:_duration,
            currentBidAmount:_startPrice,
            currentBidOwner:address(0),
            bidCount:0
        });

        bidings.push(bidInfo);

        uint256 index=bidings.length-1;

        emit CreateNewBid(index,bidInfo.creator,bidInfo.assetAddress,bidInfo.tokenAddress);
        
        return index;
     }

    function bid(uint256 _bidIndex,
                 uint256 _amount) public returns(bool){
        
        BidInfo storage bidInfo = bidings[_bidIndex];
        require(bidInfo.creator!=address(0));
        require(isActive(_bidIndex));

        if(_amount>bidInfo.currentBidAmount){

            ERC20 token=ERC20(bidInfo.tokenAddress);
            require(token.transferFrom(msg.sender,address(this),_amount));
            if(bidInfo.currentBidAmount!=0){
                token.transfer(bidInfo.currentBidOwner,bidInfo.currentBidAmount);
            }

            bidInfo.currentBidAmount=_amount;
            bidInfo.currentBidOwner=msg.sender;
            bidInfo.bidCount=bidInfo.bidCount+1;

            emit NewBid(_bidIndex,msg.sender,_amount);
            return true;
            }
        
        return false;
        }

    function isActive(uint256 _index) public view returns (bool) {
        return getStatus(_index) == Status.active; 
        }

    function isFinished(uint256 _index) public view returns (bool) { 
        return getStatus(_index) == Status.finished; 
        }

    function getStatus(uint256 _index) public view returns (Status) {
        BidInfo storage bidInfo = bidings[_index];
        if (block.timestamp < bidInfo.startTime) {
            return Status.pending;
        } else if (block.timestamp < (bidInfo.startTime + (bidInfo.duration))) {
            return Status.active;
        } else {
            return Status.finished;
        }
    }

    function getWinner(uint256 _index) public view returns (address) {
        require(isFinished(_index));
        return bidings[_index].currentBidOwner;
    }

    function claimAsset(uint256 _bidIndex) public{
        require(isFinished(_bidIndex));
        BidInfo storage bidInfo = bidings[_bidIndex];

        address winner = getWinner(_bidIndex);
        require(winner==msg.sender);

        ERC721 asset = ERC721(bidInfo.assetAddress);
        asset.transferFrom(bidInfo.creator,winner,bidInfo.assetId);

        emit Claim(_bidIndex,winner);
    }

    function claimTokens(uint256 _bidIndex) public{
        require(isFinished(_bidIndex));
        BidInfo storage bidInfo = bidings[_bidIndex];

        require(bidInfo.creator==msg.sender);

        ERC20 token = ERC20(bidInfo.tokenAddress);
        require(token.transfer(bidInfo.creator,bidInfo.currentBidAmount));

        emit Claim(_bidIndex,bidInfo.creator);
    }
}