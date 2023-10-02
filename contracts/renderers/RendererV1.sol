pragma solidity 0.8.21;

import "solady/src/utils/Base64.sol";
import "solady/src/utils/SSTORE2.sol";
import "solady/src/auth/OwnableRoles.sol";
import "solady/src/utils/LibString.sol";

contract Metadata is OwnableRoles {
    using LibString for uint256;

    string ipfs;

    uint256 LEP_CONTRACT = _ROLE_1;

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(ipfs,'/',tokenId.toString()));
    }
    function setIPFS(string memory ipfs) external onlyOwner {
        ipfs = ipfs;
    }
}
