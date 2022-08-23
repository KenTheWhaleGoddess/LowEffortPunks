pragma solidity 0.8.7;

import "./Base64.sol";
import "./SSTORE2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Metadata is Ownable {
    using Strings for uint256;

    mapping(uint256 => address) tokenIdToArt;
    mapping(uint256 => address) tokenIdToDescription;

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return buildMetadata(tokenId);
    }

  
    function buildMetadata(uint256 tokenId) public view returns(string memory) {
        return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name": "low effort punk ', tokenId.toString(), 
                          '", "description":"', 
                          string(SSTORE2.read(tokenIdToDescription[tokenId])),
                          '", "image": "', 
                          string(SSTORE2.read(tokenIdToArt[tokenId])),
                          '"}')))));
    }


    function setArt(uint256 tokenId, string calldata _art) public onlyOwner {
        tokenIdToArt[tokenId] = SSTORE2.write(bytes(_art));
    }

    function setDescription(uint256 tokenId, string calldata desc) public onlyOwner {
        tokenIdToDescription[tokenId] = SSTORE2.write(bytes(desc));
    }

}
