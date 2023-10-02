//SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

interface MetadataRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}