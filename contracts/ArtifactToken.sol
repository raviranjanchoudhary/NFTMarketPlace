// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract ArtifactToken is ERC721{

    struct Artifact{
        string name;
        string createdBy;
    }

    Artifact[] private artifacts;

    event Mint(uint256 artifactIndex, address owner);

    constructor() ERC721("Artifact Token","ATT"){
        _mintArtifact(msg.sender, "Rosetta Stone", "John");
        _mintArtifact(msg.sender, "Rosetta Stone1", "John1");
        _mintArtifact(msg.sender, "Rosetta Stone1", "John1");
    }

    function _mintArtifact(address owner, 
                           string memory name, 
                           string memory createdBy) internal returns (uint256){

        Artifact memory artifact = Artifact({
            name:name,
            createdBy:createdBy
        });

        artifacts.push(artifact);

        uint256 index = artifacts.length-1;
        emit Mint(index,msg.sender);

        super._mint(owner, index);
        emit Transfer(address(0), owner, index);

        return index;
    }

    function getTotalArtifacts()public view returns(uint){
        return artifacts.length;
    }
}