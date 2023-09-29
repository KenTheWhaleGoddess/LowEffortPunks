pragma solidity 0.8.18;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "solady/src/auth/OwnableRoles.sol";

interface Metadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function storeOneNew(uint256 tokenId, string memory ipfs) external;
}

contract LEP is ERC721('Low Effort Punks', 'LEP'), OwnableRoles, ERC1155Receiver, Pausable, ReentrancyGuard {

    //address OS = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
    address OS = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656;
    address MD = 0x005A20Ba09425A3F9A0dDAf1B0764e9CAF0E8dfc;
    bool gasRefundEnabled;
    uint256 maxGweiForRefund = 11 gwei;
    uint256 maxMinerTip = 2 gwei;
    
    uint256 FREN_ROLE = _ROLE_1;

    mapping(uint256 => bool) isIdMapped;
    mapping(uint256 => uint256) map;    

    uint256 refundConst;

    // masks used to identify punks by OS ID standard, used in isPunk(tokenId)
    uint256 mask =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000FFFFFFFFFF;
    uint256 maskedPunkValue = 0xC0C8D886B92A811E8E41CB6AB5144E44DBBFBFA3000000000000000000000001;

    constructor(uint256 refundInit) {
        refundConst = refundInit;
        _initializeOwner(msg.sender);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return Metadata(MD).tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
            address operator, address from, uint256 id, uint256 value, bytes calldata data
    ) public virtual override whenNotPaused nonReentrant returns (bytes4) {
        uint gasAtStart = gasleft();
        require(msg.sender == OS, "not an os token");
        require(isPunk(id), "not a Punk");
        _safeMint(from, id);

        uint256 refund = refundConst * (gasAtStart - gasleft());
        payable(msg.sender).call{value: refund}('');
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(
            address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data
    ) public virtual override whenNotPaused nonReentrant returns (bytes4) {
        uint gasAtStart = gasleft();
        require(msg.sender == OS, "not an os token"); 
        for(uint i; i < ids.length; i++) {
            require(isPunk(ids[i]), "not a Punk");

            _safeMint(from, ids[i]);
        }

        uint256 refund = refundConst * (gasAtStart - gasleft());
        payable(msg.sender).call{value: refund}('');
        return this.onERC1155BatchReceived.selector;
    }


    function isPunk(uint256 tokenId) public view returns (bool) {
        return ((tokenId & mask) == maskedPunkValue);
    }

    receive() external payable {}

    function getRenderer() external view returns (address) {
        return MD;
    }

    function isLepReadyToMigrate(uint256 osTokenId) external view returns (bool) {
        return isIdMapped[osTokenId];
    }

    function isGasRefundEnabled() external view returns (bool) {
        return gasRefundEnabled;
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
    function forceMint(address _user, uint256 newTokenId) external onlyOwner {
        _safeMint(_user, newTokenId, '');
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
    function setMaxPriceForRefundInWei(uint256 _amount) external onlyOwner {
        maxGweiForRefund = _amount;
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).call{value: address(this).balance}('');
    }
}
