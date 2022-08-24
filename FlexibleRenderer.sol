pragma solidity 0.8.7;

import "./Base64.sol";
import "./SSTORE2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Metadata is Ownable {
    using Strings for uint256;

    mapping(uint256 => bool) public isPunkOnChain;
    mapping(uint256 => address) onChainPunk;
    bool public gasRefundEnabled = true;

    modifier onlyFren {
        //frens can map.
        require(frens[msg.sender] || msg.sender == owner(), "not a fren");
        _;
    }

    mapping(address => bool) frens;

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return buildMetadata(tokenId);
    }

    function buildMetadata(uint256 tokenId) public view returns(string memory) {
        if (onChainPunk[tokenId] == address(0)) {
            return string(abi.encodePacked(
                'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                            '{"name": "low effort punk ', tokenId.toString(), 
                            '", "image": "', 
                            'https://storage.googleapis.com/lep123/', tokenId.toString(), '.png',
                            '"}')))));
        } else {
            return string(abi.encodePacked(
                'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                            '{"name": "low effort punk ', tokenId.toString(), 
                            '", "image": "', 
                            string(SSTORE2.read(onChainPunk[tokenId])),
                            '"}')))));
        }
    }

    function onChainLep(uint256 tokenId) external view returns (string memory) {
        return string(SSTORE2.read(onChainPunk[tokenId]));
    }

    receive() external payable { }

    function putPunkOnChain(uint256 tokenId, string calldata svg) external onlyFren {
        uint gasAtStart = gasleft();
        onChainPunk[tokenId] = SSTORE2.write(bytes(svg));
        if (gasRefundEnabled) {
            require(tx.gasprice < 11 gwei, "too high");
            uint256 refund = tx.gasprice * (gasAtStart - gasleft());
            payable(msg.sender).call{value: refund}('');
        }
    }

    function isFren(address _user) external view returns (bool) {
        return frens[_user];
    }

    function toggleFren(address _user) external onlyOwner {
        frens[_user] = !frens[_user];
    }

    function toggleGasRefund() external onlyOwner {
        gasRefundEnabled = !gasRefundEnabled;
    }

}
