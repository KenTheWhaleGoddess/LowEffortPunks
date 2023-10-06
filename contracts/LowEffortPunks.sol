//SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {OwnableRoles} from "./solady/auth/OwnableRoles.sol";
import {ERC721} from "./solady/tokens/ERC721.sol";
import {IERC1155} from "./interfaces/IERC1155.sol";
import {MetadataRenderer} from "./interfaces/MetadataRenderer.sol";

contract LowEffortPunks is ERC721, OwnableRoles {

    error NotSharedStorefrontToken();
    error NotLEP();
    error GasRefundFailed();
    error ZeroTokenTransfer();
    error MetadataLocked();

    struct GasRefundSettings {
        uint40 maxRefundBaseFee;
        uint40 maxRefundPriorityFee;
        uint40 baseRefundGasUnits;
        uint40 perTokenRefundGasUnits;
        bool gasRefundEnabled;
    }

    GasRefundSettings gasRefundSettings;
    
    address private constant LEP_DEPLOYER_1 = 0xc0c8d886B92a811E8E41cb6AB5144E44DBBFBFA3;
    address private constant LEP_DEPLOYER_2 = 0x11E98c6eb7495fE047D08d14feEc64Ca683c73CB;
    address private constant OPENSEA_SHARED_STOREFRONT = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656; //0x495f947276749Ce646f68AC8c248420045cb7b5e
    address public metadataRenderer;
    bool public metadataLocked;
    
    mapping(address => mapping(uint256 => uint256)) private validLEPTokens;

    constructor(
        GasRefundSettings memory _gasRefundSettings,
        uint256[] memory _lepDeployer1TokenMap,
        uint256[] memory _lepDeployer2TokenMap
    ) {
        _initializeOwner(msg.sender);

        gasRefundSettings = _gasRefundSettings;
        
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
        uint256 gasUsed = gasleft();
        uint256 tokensEligibleForRefund;

        if(msg.sender != OPENSEA_SHARED_STOREFRONT) revert NotSharedStorefrontToken();
        if(value == 0) revert ZeroTokenTransfer();
        if(!isLEP(id)) revert NotLEP();

        if(_exists(id)) {
            _transfer(address(0), address(this), from, id);
        } else {
            _mint(from, id);
            unchecked {
                gasUsed -= gasleft();
            }
            GasRefundSettings memory grs = gasRefundSettings;
            if(grs.gasRefundEnabled) {
                processGasRefund(grs, from, 1, gasUsed);
            }
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
        uint256 gasUsed = gasleft();
        uint256 tokensEligibleForRefund;

        if(msg.sender != OPENSEA_SHARED_STOREFRONT) revert NotSharedStorefrontToken();
        
        uint256 arrayLength = ids.length;
        for(uint256 tokenIndex; tokenIndex < arrayLength;) {
            if(amounts[tokenIndex] == 0) revert ZeroTokenTransfer();
            uint256 id = ids[tokenIndex];
            if(!isLEP(id)) revert NotLEP();

            if(_exists(id)) {
                unchecked {
                    gasUsed -= gasleft(); //deduct gas refund for repeats 
                }
                _transfer(address(0), address(this), from, id);
                unchecked {
                    gasUsed += gasleft(); //deduct gas refund for repeats 
                }
            } else {
                _mint(from, id);
                unchecked {
                    ++tokensEligibleForRefund;
                }
            }

            unchecked {
                ++tokenIndex;
            }
        }

        unchecked {
            gasUsed -= gasleft();
        }
        GasRefundSettings memory grs = gasRefundSettings;
        if(grs.gasRefundEnabled) {
            processGasRefund(grs, from, tokensEligibleForRefund, gasUsed);
        }

        return 0xbc197c81;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external view returns(bytes4) {
        if(msg.sender == address(this)) return 0xf0b9e5ba;

        return 0x00000000;
    }

    function processGasRefund(GasRefundSettings memory grs, address refundTo, uint256 gasUsed, uint256 tokensEligibleForRefund) internal {
        if(tokensEligibleForRefund == 0) return;
        if(address(this).balance == 0) return;
        
        uint256 gasRefund = block.basefee;
        unchecked {
            if(block.basefee > grs.maxRefundBaseFee) gasRefund = grs.maxRefundBaseFee;
            uint256 priorityFee = tx.gasprice - block.basefee;
            if(priorityFee > grs.maxRefundPriorityFee) priorityFee = grs.maxRefundPriorityFee;
            gasRefund += priorityFee;

            gasUsed += grs.baseRefundGasUnits;
            gasUsed += (grs.perTokenRefundGasUnits * tokensEligibleForRefund);
            gasRefund *= gasUsed;
        }

        if(gasRefund > address(this).balance) gasRefund = address(this).balance;

        (bool success, ) = payable(refundTo).call{value: gasRefund}('');
        if(!success) revert GasRefundFailed();
    }

    function transferFrom(address from, address to, uint256 id) public payable override {
        super.transferFrom(from, to, id);

        if(to == address(this)) {
            IERC1155(OPENSEA_SHARED_STOREFRONT).safeTransferFrom(address(this), from, id, 1, "");
        }
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

    function setGasRefundSettings(GasRefundSettings calldata _gasRefundSettings) external onlyOwner {
        gasRefundSettings = _gasRefundSettings;
    }

    function withdrawETH() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success);
    }
}