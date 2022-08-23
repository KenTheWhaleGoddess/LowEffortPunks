pragma solidity 0.8.7;

import "./Base64.sol";
import "./SSTORE2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Metadata {
    using Strings for uint256;

    mapping(uint256 => bool) public isPunkOnChain;
    mapping(uint256 => address) onChainPunk;
    uint256 refundForArtInWei = 82781;
    bool public gasRefundEnabled = true;

    modifier onlyFren {
        //frens can map.
        require(frens[msg.sender], "not a fren");
        _;
    }

    constructor() {
        frens[msg.sender] = true;
    }

    mapping(address => bool) frens;

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return buildMetadata(tokenId);
    }

    function buildMetadata(uint256 tokenId) public view returns(string memory) {
        if (!isPunkOnChain[tokenId]) {
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

    function art(uint256 tokenId) external view returns (string memory) {
        return string(SSTORE2.read(onChainPunk[tokenId]));
    }

    function putPunkOnChain(uint256 tokenId, string memory svg) external onlyFren {
        require(tx.gasprice < 11 gwei, "too high");
        if (!isPunkOnChain[tokenId]) {
            isPunkOnChain[tokenId] = true;
        }
        SSTORE2.write(bytes(svg));
        if (gasRefundEnabled) {
            uint256 refund = tx.gasprice * refundForArtInWei;
            payable(msg.sender).call{value: refund}('');
        }
    }

    function isFren(address _user) external view returns (bool) {
        return frens[_user];
    }

    function toggleFren(address _user) external onlyFren {
        frens[_user] = !frens[_user];
    }

    function toggleGasRefund() external onlyFren {
        gasRefundEnabled = !gasRefundEnabled;
    }

}
