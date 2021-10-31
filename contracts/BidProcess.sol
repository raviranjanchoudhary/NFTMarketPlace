// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AddressUtils.sol";

contract BidProcess{

    using AddressUtils for address;

    struct BidInfo{
        address assetAddress;
        uint256 assetId;
        address tokenAddress;
        address creator;
        uint256 startTime;
        uint256 duration;
        uint256 currentBidAmount;
        uint256 currentBidOwner;
        uint256 bidCount;
    }

    BidProcess[] private bidings;

    function createNewBid(address _assetAddress,
                          uint256 _assetId,
                          address _tokenAddress,
                          uint256 _startPrice,
                          uint256 _startTime,
                          uint256 _duration) public returns(uint256){
        require(_assetAddress.isContract());
        ERC721 asset = ERC721(_assetAddress);
        require(asset.ownerOf(_assetId)=msg.sender);
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

                          }
}