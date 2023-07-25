pragma solidity 0.8.18;

import "solady/src/utils/Base64.sol";
import "solady/src/utils/SSTORE2.sol";
import "solady/src/auth/OwnableRoles.sol";
import "solady/src/utils/LibString.sol";

contract Metadata is OwnableRoles {
     using LibString for uint256;

    uint256 firstNewLEP = 6900;
    string oldLeps;

    uint256 LEP_CONTRACT = _ROLE_1;

    mapping(uint256 => string) public newLeps;

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (tokenId < firstNewLEP) {
            return string(abi.encodePacked(oldLeps,'/',tokenId.toString()));
        } else {
            return newLeps[tokenId];
        }
    }
    function storeOld(string memory ipfs) external onlyOwnerOrRoles(LEP_CONTRACT) {
        oldLeps = ipfs;
    }
    function storeOneNew(uint256 tokenId, string memory ipfs) external onlyOwnerOrRoles(LEP_CONTRACT) {
        newLeps[tokenId] = ipfs;
    }
}
