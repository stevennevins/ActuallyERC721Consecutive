// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {IERC721} from "forge-std/interfaces/IERC721.sol";
import {ERC721ConsecutiveActually} from "src/ERC721ConsecutiveActually.sol";

contract MockERC721Consecutive is ERC721ConsecutiveActually {
    function mint(address to) public {
        _mint(to);
    }

    function batchMint(address to, uint96 amount) public {
        _mintConsecutive(to, amount);
    }
}

contract ERC721Test is Test {
    MockERC721Consecutive public nft;

    function setUp() public {
        nft = new MockERC721Consecutive();
    }
}

contract Mint is ERC721Test {
    function test_Mint() public {
        nft.mint(address(2));
    }
}

contract BatchMint is ERC721Test {
    function test_BatchMint() public {
        nft.batchMint(address(2), 5);
    }

    function test_BatchMint20() public {
        nft.batchMint(address(2), 20);
    }

    function test_BatchMint100() public {
        nft.batchMint(address(2), 100);
    }
}

contract Complex is ERC721Test {
    function test_ComplexMint() public {
        nft.batchMint(address(2), 4);
        nft.mint(address(4));
        nft.batchMint(address(5), 2);
        nft.mint(address(4));
    }

    function test_ComplexMintTransfer() public {
        nft.batchMint(address(2), 4);
        nft.mint(address(4));
        vm.prank(address(4));
        nft.transferFrom(address(4), address(5), 5);
        vm.prank(address(2));
        nft.transferFrom(address(2), address(5), 2);
        nft.batchMint(address(5), 2);
        nft.mint(address(4));
    }
}
