// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721Consecutive, ERC721} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Consecutive.sol";

contract ERC721ConsecutiveActually is ERC721("",""), ERC721Consecutive{

    function _firstConsecutiveId() internal view virtual returns (uint96) {
        return 1;
    }

    function _ownerOf(uint256 tokenId) internal view virtual override(ERC721, ERC721Consecutive) returns (address) {
        return super._ownerOf(tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Consecutive) {
        super._mint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Consecutive) {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }

}
