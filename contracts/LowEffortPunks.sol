pragma solidity 0.8.34;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {MetadataRenderer} from "./renderer/MetadataRenderer.sol";

contract LowEffortPunks is ERC721, Ownable, IERC1155Receiver {

    error NotSharedStorefrontToken();
    error NotLEP();
    error ZeroTokenTransfer();
    error MetadataLocked();
    
    address private constant LEP_DEPLOYER_1 = 0xc0c8d886B92a811E8E41cb6AB5144E44DBBFBFA3;
    mapping(uint256 => uint256) LEP_DEPLOYER_MAP;
    address private constant LEP_DEPLOYER_2 = 0x11E98c6eb7495fE047D08d14feEc64Ca683c73CB;
    address private constant OPENSEA_SHARED_STOREFRONT = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656; //0x495f947276749Ce646f68AC8c248420045cb7b5e
    IERC1155 private constant OS = IERC1155(OPENSEA_SHARED_STOREFRONT);
    address public metadataRenderer;
    bool public metadataLocked;
    
    mapping(uint256 => bool) tokenExists;

    mapping(address => mapping(uint256 => uint256)) private validLEPTokens;


    constructor(uint256[] memory _lepDeployer1TokenMap,
        uint256[] memory _lepDeployer2TokenMap
    ) Ownable(msg.sender) ERC721("", "") {
        unchecked {
            uint256 tokenMapLength = _lepDeployer1TokenMap.length;
            for(uint256 tokenMapIndex;tokenMapIndex < tokenMapLength;++tokenMapIndex) {
                validLEPTokens[LEP_DEPLOYER_1][tokenMapIndex] = _lepDeployer1TokenMap[tokenMapIndex];
            }
            tokenMapLength = _lepDeployer2TokenMap.length;
            for(uint256 tokenMapIndex;tokenMapIndex < tokenMapLength;++tokenMapIndex) {
                validLEPTokens[LEP_DEPLOYER_2][tokenMapIndex] = _lepDeployer2TokenMap[tokenMapIndex];
            }
        }
    }

    function name() public pure override returns (string memory) {
        return "Low Effort Punks";
    }

    function symbol() public pure override returns (string memory) {
        return "LEP";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return MetadataRenderer(metadataRenderer).tokenURI(tokenId);
    }

    function onERC1155Received(
            address, //operator
            address from, 
            uint256 id, 
            uint256 value, 
            bytes calldata //data
    ) external returns (bytes4) {
        if(msg.sender != OPENSEA_SHARED_STOREFRONT) revert NotSharedStorefrontToken();
        if(value == 0) revert ZeroTokenTransfer();
        if(!isLEP(id)) revert NotLEP();

        if(_exists(id)) {
            _transfer(address(this), from, id);
        } else {
            _mint(from, id);
        }

        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
            address, //operator
            address from, 
            uint256[] calldata ids, 
            uint256[] calldata amounts, 
            bytes calldata //data
    ) external returns (bytes4) {
        if(msg.sender != OPENSEA_SHARED_STOREFRONT) revert NotSharedStorefrontToken();
        
        uint256 arrayLength = ids.length;
        for(uint256 tokenIndex; tokenIndex < arrayLength;) {
            if(amounts[tokenIndex] == 0) revert ZeroTokenTransfer();
            uint256 id = ids[tokenIndex];
            if(!isLEP(id)) revert NotLEP();

            if(_exists(id)) {
                _transfer(address(this), from, id);
            } else {
                _mint(from, id);
            }

            unchecked {
                ++tokenIndex;
            }
        }


        return 0xbc197c81;
    }

    //return portal
    //if receiving the LEP, transfer the 1155 to the sender
    function _transfer(address from, address to, uint256 tokenId) internal override {
        if (to == address(this)) {
            OS.safeTransferFrom(address(this), from, tokenId, 1, '');
        }
        ERC721._transfer(from, to, tokenId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external view returns(bytes4) {
        if(msg.sender == address(this)) return 0xf0b9e5ba;

        return 0x00000000;
    }

    function _exists(uint256 tokenId) internal returns (bool) {
        return tokenExists[tokenId];
    }


    function isLEP(uint256 tokenId) public view returns (bool) {
        address deployer = address(uint160(tokenId >> 96));
        if(deployer != LEP_DEPLOYER_1) {
            if(deployer != LEP_DEPLOYER_2) {
                return false;
            }
        }
        
        uint256 tokenIndex = (tokenId << 160) >> 136;
        uint256 tokenBucket = tokenIndex >> 8;
        uint256 tokenSlot = tokenIndex & 0xFF;

        return ((validLEPTokens[deployer][tokenBucket] >> tokenSlot) & 0x01 == 0x01);
    }

    receive() external payable {}

    function setMetadataContract(address _metadataRenderer) external onlyOwner {
        if (metadataLocked) {
            revert MetadataLocked(); 
        }
        metadataRenderer = _metadataRenderer;
    }

    function lockMetadataContract() external onlyOwner {
        metadataLocked = true;
    }

    function withdrawETH() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success);
    }

}
