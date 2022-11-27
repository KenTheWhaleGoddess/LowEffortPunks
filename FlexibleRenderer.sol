pragma solidity 0.8.7;

import "solady/src/utils/Base64.sol";
import "solady/src/utils/SSTORE2.sol";
import "solady/src/auth/OwnableRoles.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Metadata is OwnableRoles {
    using Strings for uint256;

    mapping(uint256 => address) onChainPunk;

    uint256 LEP_CONTRACT = _ROLE_1;

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return buildMetadata(tokenId);
    }

    function buildMetadata(uint256 tokenId) public view returns(string memory) {
        return string(abi.encodePacked(
                'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                            '{"name": "low effort punk ', tokenId.toString(), 
                            '", "image": "data:image/png;base64,', 
                            SSTORE2.read(onChainPunk[tokenId]),
                            '"}')))));
    }

    function onChainLep(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked('data:image/png;base64,',SSTORE2.read(onChainPunk[tokenId])));
    }

    function onChainLepAddress(uint256 tokenId) external view returns (address) {
        return onChainPunk[tokenId];
    }

    receive() external payable { }

    function putPunkOnChain(uint256 tokenId, string calldata svg) external onlyOwnerOrRoles(LEP_CONTRACT) {
        onChainPunk[tokenId] = SSTORE2.write(bytes(svg));
    }
}
