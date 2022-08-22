pragma solidity 0.8.7;

import "./Base64.sol";
import "./SSTORE2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Metadata is Ownable {
    using Strings for uint256;

    address ipfs;
    address public description;

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return buildMetadata(tokenId);
    }

  
    function buildMetadata(uint256 tokenId) public view returns(string memory) {
        return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name": Low Effort Punk ', tokenId.toString(), 
                          ', "description":"', 
                          string(SSTORE2.read(description)),
                          '", "image": "', 
                          string(SSTORE2.read(ipfs)),
                          '"}')))));
    }


    function setIpfs(string calldata _ipfs) public onlyOwner {
        ipfs = SSTORE2.write(bytes(_ipfs));
    }

    function setDescription(string calldata desc) public onlyOwner {
        description = SSTORE2.write(bytes(desc));
    }

}
