// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721A.sol";
import "./IRenderer.sol";
import "./IOpenseaStorefront.sol";

contract LowEffortPunks is Ownable, ERC721A, Pausable {
    IOpenseaStorefront os;
    IRenderer renderer;

    uint256 migrateTilToken = 0xC0C8D886B92A811E8E41CB6AB5144E44DBBFBFA3000000000015C00000000001;

    constructor(address _renderer, address _os, uint256 _migrateTilToken) ERC721A("Low Effort Punks", "LEP") {
        os = IOpenseaStorefront(_os);
        renderer = IRenderer(_renderer);
        migrateTilToken = _migrateTilToken;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function migrateFromOpensea(uint256 osTokenId) external whenNotPaused {
        require(osTokenId >= 0xC0C8D886B92A811E8E41CB6AB5144E44DBBFBFA30000000000018B0000000001, "not a LEP");
        require(osTokenId <= 0xC0C8D886B92A811E8E41CB6AB5144E44DBBFBFA3000000000015C00000000001, "not a LEP");
    }

    function convertOSTokenIdToNewTokenId(uint256 osTokenId) public view returns (uint256) {
		uint256 _id = (osTokenId & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
        //offset magic needed... doesnt line up 1:1
        return _id;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return renderer.tokenURI(tokenId);
    }

    function setOS(address _newOS) external onlyOwner {
        os = IOpenseaStorefront(_newOS);
    }

    function setRenderer(address _newRenderer) external onlyOwner {
        renderer = IRenderer(_newRenderer);
    }
}
