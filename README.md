# LowEffortPunks

References:
- Low Effort Punks: https://opensea.io/collection/low-effort-punks
- Fast Food Punks: https://etherscan.io/address/0x51f437e4b25ce7bc7d43c13ba1140dd0e52151cb#code
- CyberKongz: https://etherscan.io/address/0x57a204aa1042f6e66dd7730813f4024114d74f37#code


OS Token ID:
- Convert it to hex, then shift 40 bits to the right. That number will increment, some testing is done with this function:` convertOSTokenIdToNewTokenId(uint256 osTokenId) public view returns (uint256)`
- The tokens dont map 1:1, but they increase together. If they mapped 1:1 we could convert more easily, we will need some offset magic. 
