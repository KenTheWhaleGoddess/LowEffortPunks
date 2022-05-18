# LowEffortPunks

References:
- Low Effort Punks: https://opensea.io/collection/low-effort-punks
- Fast Food Punks: https://etherscan.io/address/0x51f437e4b25ce7bc7d43c13ba1140dd0e52151cb#code
- CyberKongz: https://etherscan.io/address/0x57a204aa1042f6e66dd7730813f4024114d74f37#code
- Website to convert Hex <-> Decimal: https://www.rapidtables.com/convert/number/hex-to-decimal.html

OS Token ID:
- Convert LEP OS Token ID it to hex, then shift 40 bits to the right modulo 2^14. That number will increment, some testing is done with this function:` convertOSTokenIdToNewTokenId(uint256 osTokenId) public view returns (uint256)`
- The tokens dont map 1:1, but they increase together. If they mapped 1:1 we could convert more easily, we will need some offset magic. 
Ex. 

LEP 0's Token ID is `87198930750286842836902562062466327909054195361095182156017571736294365593601`

Convert that to hex: `C0C8D886B92A811E8E41CB6AB5144E44DBBFBFA30000000000018B0000000001`

Let's quickly parse:
- Leading `C0C8D886B92A811E8E41CB6AB5144E44DBBFBFA3` will always be the same, it is deterministic from creator address
- Tailing `0000000001` will always be 1 
- The magic bit is between those. 
- Use an & operation and bitshift to get this ID: `		uint256 _id = (osTokenId & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;`

Again, these dont map 1:1, they will increment with each token but may skip slots (probably due to LEP deletions). 


Looks like CyberKongz found this too. See their code:

```

	function returnCorrectId(uint256 _id) pure internal returns(uint256) {
		_id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		if (_id > 262)
			return _id - 5;
		else if (_id > 197)
			return _id - 4;
        else if (_id > 75)
            return _id - 3;
        else if (_id > 34)
            return _id - 2;
        else if (_id > 18)
            return _id - 1;
		else
			return _id;
	}
