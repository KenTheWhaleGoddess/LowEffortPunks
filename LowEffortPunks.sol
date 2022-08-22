pragma solidity 0.8.7;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface Metadata {
    function tokenURI(uint256 tokenId) external returns (string memory);
}

contract LEP is ERC721('Low Effort Punks', 'LEP'), Ownable, ERC1155Holder, ReentrancyGuard, Pausable {

    address OS = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
    address MD;
    bool gasRefundEnabled;
    uint256 refundInWei;
    uint256 refundForMappingInWei;

    modifier onlyFren {
        //frens can map.
        require(frens[msg.sender] || msg.sender == owner(), "not a fren");
        _;
    }

    mapping(uint256 => bool) isIdMapped;
    mapping(uint256 => uint256) map;
    mapping(address => bool) frens;

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
            address operator, address from, uint256 id, uint256 value, bytes calldata data
    ) public virtual override returns (bytes4) {
        require(operator == OS, "not an os token");
        require(isIdMapped[id], "token not mapped");
        require(!paused(), "paused");
        require(!gasRefundEnabled || tx.gasprice < 11 gwei, "gas refund is enabled but gas is too high");
        _safeMint(from, map[id]);
        payable(msg.sender).call{value: tx.gasprice * refundForMappingInWei}('');

        return this.onERC1155Received.selector;
    }

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
        require(!gasRefundEnabled || tx.gasprice < 11 gwei, "gas refund is enabled but gas is too high");
        isIdMapped[osTokenId] = true;
        map[osTokenId] = newTokenId;
        payable(msg.sender).call{value: tx.gasprice * refundForMappingInWei}('');
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function retrieveOldLep(uint256 tokenId) external onlyOwner {
        IERC1155(OS).safeTransferFrom(address(this), msg.sender, tokenId, 1, '');
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
}
