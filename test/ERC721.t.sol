// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {IERC721} from "forge-std/interfaces/IERC721.sol";
import {ERC721ConsecutiveActually, ERC721} from "src/ERC721ConsecutiveActually.sol";

interface IBatchERC721 is IERC721 {
    function mint(address) external;

    function batchMint(address, uint96 amount) external;
}

contract MockERC721Consecutive is ERC721ConsecutiveActually {
    function mint(address to) public {
        _mint(to);
    }

    function batchMint(address to, uint96 amount) public {
        _mintConsecutive(to, amount);
    }
}

contract MockERC721 is ERC721("", "") {
    uint256 nextId = 1;

    function mint(address to) public {
        uint256 _nextId = nextId;
        nextId++;
        _mint(to, _nextId);
    }

    function batchMint(address to, uint96 amount) public {
        uint256 _nextId = nextId;
        nextId += amount;
        for (uint256 i; i < amount; i++) {
            _mint(to, _nextId + i);
        }
    }
}

contract ERC721Test is Test {
    IBatchERC721 public nft;
}

abstract contract Mint is ERC721Test {
    function test_Mint() public {
        vm.pauseGasMetering();
        nft.mint(address(2));
        vm.resumeGasMetering();
        nft.mint(address(3));
    }
}

abstract contract BatchMint is ERC721Test {
    function test_BatchMint() public {
        vm.pauseGasMetering();
        nft.mint(address(2));
        vm.resumeGasMetering();
        nft.batchMint(address(3), 5);
    }

    function test_BatchMint2() public {
        vm.pauseGasMetering();
        nft.mint(address(2));
        vm.resumeGasMetering();
        nft.batchMint(address(3), 2);
    }

    function test_BatchMint5() public {
        vm.pauseGasMetering();
        nft.mint(address(2));
        vm.resumeGasMetering();
        nft.batchMint(address(3), 5);
    }

    function test_BatchMint20() public {
        vm.pauseGasMetering();
        nft.mint(address(2));
        vm.resumeGasMetering();
        nft.batchMint(address(3), 20);
    }

    function test_BatchMint100() public {
        vm.pauseGasMetering();
        nft.mint(address(2));
        vm.resumeGasMetering();
        nft.batchMint(address(3), 100);
    }
}

abstract contract Complex is ERC721Test {
    function test_ComplexMint() public {
        nft.batchMint(address(2), 4);
        nft.mint(address(4));
        nft.batchMint(address(5), 2);
        nft.mint(address(4));
        assertEq(nft.ownerOf(1), address(2));
        assertEq(nft.ownerOf(2), address(2));
        assertEq(nft.ownerOf(3), address(2));
        assertEq(nft.ownerOf(4), address(2));
        assertEq(nft.ownerOf(5), address(4));
        assertEq(nft.ownerOf(6), address(5));
        assertEq(nft.ownerOf(7), address(5));
        assertEq(nft.ownerOf(8), address(4));
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

        assertEq(nft.ownerOf(1), address(2));
        assertEq(nft.ownerOf(2), address(5));
        assertEq(nft.ownerOf(3), address(2));
        assertEq(nft.ownerOf(4), address(2));
        assertEq(nft.ownerOf(5), address(5));
        assertEq(nft.ownerOf(6), address(5));
        assertEq(nft.ownerOf(7), address(5));
        assertEq(nft.ownerOf(8), address(4));
    }
}

contract ERC721ConsecutiveBatchTest is Mint, BatchMint {
    function setUp() public virtual {
        nft = IBatchERC721(address(new MockERC721Consecutive()));
    }
}

contract ERC721BatchTest is Mint, BatchMint {
    function setUp() public virtual {
        nft = IBatchERC721(address(new MockERC721()));
    }
}
