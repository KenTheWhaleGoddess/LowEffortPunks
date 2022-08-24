pragma solidity 0.8.7;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface Metadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract LEP is ERC721('Low Effort Punks', 'LEP'), Ownable, ERC1155Receiver, ReentrancyGuard, Pausable {

    //address OS = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
    address OS = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656;
    address MD = 0x005A20Ba09425A3F9A0dDAf1B0764e9CAF0E8dfc;
    bool gasRefundEnabled;
    uint256 refundInWei = 1;
    uint256 refundForMappingInWei = 82781;
    uint256 maxGasForRefund = 11 gwei;

    modifier onlyFren {
        //frens can map.
        require(frens[msg.sender] || msg.sender == owner(), "not a fren");
        _;
    }

    mapping(uint256 => bool) isIdMapped;
    mapping(uint256 => uint256) map;
    mapping(address => bool) frens;

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return Metadata(MD).tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
            address operator, address from, uint256 id, uint256 value, bytes calldata data
    ) public virtual override nonReentrant returns (bytes4) {
        require(msg.sender == OS, "not an os token");
        require(isIdMapped[id], "token not mapped");
        require(!paused(), "paused");
        _safeMint(from, map[id]);

        if (gasRefundEnabled) {
            require(tx.gasprice < maxGasForRefund, "gas refund enabled but gas too high"); 
            payable(from).call{value: tx.gasprice * refundInWei}('');
        }

        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(
            address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data
    ) public virtual override returns (bytes4) {
        revert('please send 1 at a time');        
        return this.onERC1155BatchReceived.selector;
    }

    receive() external payable {}

    function isLepReadyToMigrate(uint256 osTokenId) external view returns (bool) {
        return isIdMapped[osTokenId];
    }
    function isFren(address _user) external view returns (bool) {
        return frens[_user];
    }
    function isGasRefundEnabled() external view returns (bool) {
        return gasRefundEnabled;
    }

    function mapLep(uint256 osTokenId, uint256 newTokenId) external onlyFren {
        isIdMapped[osTokenId] = true;
        map[osTokenId] = newTokenId;
        if (gasRefundEnabled) {
            require(tx.gasprice < maxGasForRefund, "gas refund enabled but gas too high"); 
            payable(msg.sender).call{value: tx.gasprice * refundForMappingInWei}('');
        }   
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function retrieveOldLep(uint256 tokenId) external onlyOwner {
        IERC1155(OS).safeTransferFrom(address(this), msg.sender, tokenId, 1, '');
    }
    function forceMint(uint256 newTokenId, address _user) external onlyOwner {
        _safeMint(_user, newTokenId);
    }
    function retrieveNewLep(uint256 tokenId) external onlyOwner {
        safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function setOpenSeaContract(address _os) external onlyOwner {
        OS = _os;
    }
    function setMetadataContract(address _md) external onlyOwner {
        MD = _md;
    }
    function toggleGasRefundEnabled() external onlyOwner {
        gasRefundEnabled = !gasRefundEnabled;
    }
    function setRefundInWei(uint256 _amount) external onlyOwner {
        refundInWei = _amount;
    }
    function setRefundForMappingInWei(uint256 _amount) external onlyOwner {
        refundForMappingInWei = _amount;
    }
    function addFren(address fren) external onlyOwner {
        frens[fren] = true;
    }
    function withdraw() external onlyOwner {
        payable(owner()).call{value: address(this).balance}('');
    }
}
