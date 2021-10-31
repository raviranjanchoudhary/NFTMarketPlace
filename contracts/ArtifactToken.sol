// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ArtifactToken is ERC721{

    struct Artifact{
        string name;
        string createdBy;
    }

    Artifact[] private artificats;

    event Mint(uint256 artIndex, address owner);

    constructor() ERC721("Artifact Token","ATT"){
        _mintArtifcat(msg.sender, "Rosetta Stone", "John");
    }

    function _mintArtifcat(address owner, 
                           string memory name, 
                           string memory createdBy) internal returns (uint256){

        Artifact memory artifact = Artifact({
            name:name,
            createdBy:createdBy
        });

        artificats.push(artifact);

        uint256 index = artificats.length-1;
        emit Mint(index,msg.sender);

        super._mint(owner, index);
        emit Transfer(address(0), owner, index);

        return index;
    }
}