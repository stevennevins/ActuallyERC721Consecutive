// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {IERC721} from "forge-std/interfaces/IERC721.sol";
import {ERC721, ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {ERC721ConsecutiveActually} from "src/ERC721ConsecutiveActually.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

interface IERC721Batch is IERC721 {
    function tokenURI(uint256 tokenId) external;

    function mint(address to) external;

    function burn(uint256 tokenId) external;

    function safeMint(address to) external;

    function safeMint(address to, uint256 tokenId, bytes memory data) external;

    function batchMint(address to, uint256[] memory ids) external;

    function batchTransferFrom(address from, address to, uint256[] memory ids) external;

    function batchBurn(uint256[] memory ids) external;
}

contract MockERC721Batch is ERC721 {
    uint256 public nextId = 1;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function tokenURI(uint256) public pure virtual override returns (string memory) {}

    function mint(address to) public {
        _mint(to, nextId++);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function safeMint(address to) public {
        uint256 id = nextId;
        nextId++;
        _safeMint(to, id, "");
    }

    function batchTransferFrom(address from, address to, uint256[] memory ids) public virtual {
        for (uint256 i; i < ids.length; i++) {
            transferFrom(from, to, ids[i]);
        }
    }

    function batchMint(address to, uint256 amount) public virtual {
        uint256 startId = nextId;
        nextId++;
        for (uint256 i; i < amount; i++) {
            _mint(to, startId + i);
        }
    }

    function batchBurn(uint256[] memory ids) public virtual {
        for (uint256 i; i < ids.length; i++) {
            burn(ids[i]);
        }
    }
}

contract MockERC721Consecutive is ERC721ConsecutiveActually {
    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }

    function mint(address to) public {
        _mint(to, 1);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function safeMint(address to) public {
        _safeMint(to, 1);
    }

    // function batchMint(address to, uint256 amount) public virtual {
    //     _batchMint(to, ids);
    // }
    //
    // function batchBurn(uint256[] memory ids) public virtual {
    //     _batchBurn(ids);
    // }
}

contract ERC721Recipient is ERC721TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(address _operator, address _from, uint256 _id, bytes calldata _data)
        public
        virtual
        override
        returns (bytes4)
    {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract RevertingERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) public virtual override returns (bytes4) {
        revert(string(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector)));
    }
}

contract WrongReturnDataERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) public virtual override returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC721Recipient {}

// abstract contract ERC721SpecTest is DSTestPlus, ERC721TokenReceiver {
//     mapping(uint256 => bool) public uniques;
//     uint256[] newarr;
//     IERC721Batch public token;
//
//     function setUp() public virtual {}
//
//     function uniquify(uint256[] memory input) public returns (uint256[] memory ret) {
//         newarr = new uint256[](0);
//         for (uint256 i; i < input.length; i++) {
//             if (!uniques[input[i]]) newarr.push(input[i]);
//             uniques[input[i]] = true;
//         }
//         for (uint256 i; i < newarr.length; i++) {
//             delete uniques[newarr[i]];
//         }
//         return newarr;
//     }
//
//     function testMint() public {
//         token.mint(address(0xBEEF), 1337);
//
//         assertEq(token.balanceOf(address(0xBEEF)), 1);
//         assertEq(token.ownerOf(1337), address(0xBEEF));
//     }
//
//     function testBurn() public {
//         token.mint(address(0xBEEF), 1337);
//         hevm.prank(address(0xBEEF));
//         token.burn(1337);
//
//         assertEq(token.balanceOf(address(0xBEEF)), 0);
//
//         hevm.expectRevert("NOT_MINTED");
//         token.ownerOf(1337);
//     }
//
//     function testApprove() public {
//         token.mint(address(this), 1337);
//
//         token.approve(address(0xBEEF), 1337);
//
//         assertEq(token.getApproved(1337), address(0xBEEF));
//     }
//
//     function testApproveBurn() public {
//         token.mint(address(this), 1337);
//
//         token.approve(address(0xBEEF), 1337);
//
//         token.burn(1337);
//
//         assertEq(token.balanceOf(address(this)), 0);
//         assertEq(token.getApproved(1337), address(0));
//
//         hevm.expectRevert("NOT_MINTED");
//         token.ownerOf(1337);
//     }
//
//     function testApproveAll() public {
//         token.setApprovalForAll(address(0xBEEF), true);
//
//         assertTrue(token.isApprovedForAll(address(this), address(0xBEEF)));
//     }
//
//     function testTransferFrom() public {
//         address from = address(0xABCD);
//
//         token.mint(from, 1337);
//
//         hevm.prank(from);
//         token.approve(address(this), 1337);
//
//         token.transferFrom(from, address(0xBEEF), 1337);
//
//         assertEq(token.getApproved(1337), address(0));
//         assertEq(token.ownerOf(1337), address(0xBEEF));
//         assertEq(token.balanceOf(address(0xBEEF)), 1);
//         assertEq(token.balanceOf(from), 0);
//     }
//
//     function testTransferFromSelf() public {
//         token.mint(address(this), 1337);
//
//         token.transferFrom(address(this), address(0xBEEF), 1337);
//
//         assertEq(token.getApproved(1337), address(0));
//         assertEq(token.ownerOf(1337), address(0xBEEF));
//         assertEq(token.balanceOf(address(0xBEEF)), 1);
//         assertEq(token.balanceOf(address(this)), 0);
//     }
//
//     function testTransferFromApproveAll() public {
//         address from = address(0xABCD);
//
//         token.mint(from, 1337);
//
//         hevm.prank(from);
//         token.setApprovalForAll(address(this), true);
//
//         token.transferFrom(from, address(0xBEEF), 1337);
//
//         assertEq(token.getApproved(1337), address(0));
//         assertEq(token.ownerOf(1337), address(0xBEEF));
//         assertEq(token.balanceOf(address(0xBEEF)), 1);
//         assertEq(token.balanceOf(from), 0);
//     }
//
//     function testSafeTransferFromToEOA() public {
//         address from = address(0xABCD);
//
//         token.mint(from, 1337);
//
//         hevm.prank(from);
//         token.setApprovalForAll(address(this), true);
//
//         token.safeTransferFrom(from, address(0xBEEF), 1337);
//
//         assertEq(token.getApproved(1337), address(0));
//         assertEq(token.ownerOf(1337), address(0xBEEF));
//         assertEq(token.balanceOf(address(0xBEEF)), 1);
//         assertEq(token.balanceOf(from), 0);
//     }
//
//     function testSafeTransferFromToERC721Recipient() public {
//         address from = address(0xABCD);
//         ERC721Recipient recipient = new ERC721Recipient();
//
//         token.mint(from, 1337);
//
//         hevm.prank(from);
//         token.setApprovalForAll(address(this), true);
//
//         token.safeTransferFrom(from, address(recipient), 1337);
//
//         assertEq(token.getApproved(1337), address(0));
//         assertEq(token.ownerOf(1337), address(recipient));
//         assertEq(token.balanceOf(address(recipient)), 1);
//         assertEq(token.balanceOf(from), 0);
//
//         assertEq(recipient.operator(), address(this));
//         assertEq(recipient.from(), from);
//         assertEq(recipient.id(), 1337);
//         assertBytesEq(recipient.data(), "");
//     }
//
//     function testSafeTransferFromToERC721RecipientWithData() public {
//         address from = address(0xABCD);
//         ERC721Recipient recipient = new ERC721Recipient();
//
//         token.mint(from, 1337);
//
//         hevm.prank(from);
//         token.setApprovalForAll(address(this), true);
//
//         token.safeTransferFrom(from, address(recipient), 1337, "testing 123");
//
//         assertEq(token.getApproved(1337), address(0));
//         assertEq(token.ownerOf(1337), address(recipient));
//         assertEq(token.balanceOf(address(recipient)), 1);
//         assertEq(token.balanceOf(from), 0);
//
//         assertEq(recipient.operator(), address(this));
//         assertEq(recipient.from(), from);
//         assertEq(recipient.id(), 1337);
//         assertBytesEq(recipient.data(), "testing 123");
//     }
//
//     function testSafeMintToEOA() public {
//         token.safeMint(address(0xBEEF), 1337);
//
//         assertEq(token.ownerOf(1337), address(address(0xBEEF)));
//         assertEq(token.balanceOf(address(address(0xBEEF))), 1);
//     }
//
//     function testSafeMintToERC721Recipient() public {
//         ERC721Recipient to = new ERC721Recipient();
//
//         token.safeMint(address(to), 1337);
//
//         assertEq(token.ownerOf(1337), address(to));
//         assertEq(token.balanceOf(address(to)), 1);
//
//         assertEq(to.operator(), address(this));
//         assertEq(to.from(), address(0));
//         assertEq(to.id(), 1337);
//         assertBytesEq(to.data(), "");
//     }
//
//     function testSafeMintToERC721RecipientWithData() public {
//         ERC721Recipient to = new ERC721Recipient();
//
//         token.safeMint(address(to), 1337, "testing 123");
//
//         assertEq(token.ownerOf(1337), address(to));
//         assertEq(token.balanceOf(address(to)), 1);
//
//         assertEq(to.operator(), address(this));
//         assertEq(to.from(), address(0));
//         assertEq(to.id(), 1337);
//         assertBytesEq(to.data(), "testing 123");
//     }
//
//     function testFailMintToZero() public {
//         token.mint(address(0), 1337);
//     }
//
//     function testFailDoubleMint() public {
//         token.mint(address(0xBEEF), 1337);
//         token.mint(address(0xBEEF), 1337);
//     }
//
//     function testFailBurnUnMinted() public {
//         token.burn(1337);
//     }
//
//     function testFailDoubleBurn() public {
//         token.mint(address(0xBEEF), 1337);
//
//         token.burn(1337);
//         token.burn(1337);
//     }
//
//     function testFailApproveUnMinted() public {
//         token.approve(address(0xBEEF), 1337);
//     }
//
//     function testFailApproveUnAuthorized() public {
//         token.mint(address(0xCAFE), 1337);
//
//         token.approve(address(0xBEEF), 1337);
//     }
//
//     function testFailTransferFromUnOwned() public {
//         token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
//     }
//
//     function testFailTransferFromWrongFrom() public {
//         token.mint(address(0xCAFE), 1337);
//
//         token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
//     }
//
//     function testFailTransferFromToZero() public {
//         token.mint(address(this), 1337);
//
//         token.transferFrom(address(this), address(0), 1337);
//     }
//
//     function testFailTransferFromNotOwner() public {
//         token.mint(address(0xFEED), 1337);
//
//         token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
//     }
//
//     function testFailSafeTransferFromToNonERC721Recipient() public {
//         token.mint(address(this), 1337);
//
//         token.safeTransferFrom(address(this), address(new NonERC721Recipient()), 1337);
//     }
//
//     function testFailSafeTransferFromToNonERC721RecipientWithData() public {
//         token.mint(address(this), 1337);
//
//         token.safeTransferFrom(address(this), address(new NonERC721Recipient()), 1337, "testing 123");
//     }
//
//     function testFailSafeTransferFromToRevertingERC721Recipient() public {
//         token.mint(address(this), 1337);
//
//         token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 1337);
//     }
//
//     function testFailSafeTransferFromToRevertingERC721RecipientWithData() public {
//         token.mint(address(this), 1337);
//
//         token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 1337, "testing 123");
//     }
//
//     function testFailSafeTransferFromToERC721RecipientWithWrongReturnData() public {
//         token.mint(address(this), 1337);
//
//         token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 1337);
//     }
//
//     function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData() public {
//         token.mint(address(this), 1337);
//
//         token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 1337, "testing 123");
//     }
//
//     function testFailSafeMintToNonERC721Recipient() public {
//         token.safeMint(address(new NonERC721Recipient()), 1337);
//     }
//
//     function testFailSafeMintToNonERC721RecipientWithData() public {
//         token.safeMint(address(new NonERC721Recipient()), 1337, "testing 123");
//     }
//
//     function testFailSafeMintToRevertingERC721Recipient() public {
//         token.safeMint(address(new RevertingERC721Recipient()), 1337);
//     }
//
//     function testFailSafeMintToRevertingERC721RecipientWithData() public {
//         token.safeMint(address(new RevertingERC721Recipient()), 1337, "testing 123");
//     }
//
//     function testFailSafeMintToERC721RecipientWithWrongReturnData() public {
//         token.safeMint(address(new WrongReturnDataERC721Recipient()), 1337);
//     }
//
//     function testFailSafeMintToERC721RecipientWithWrongReturnDataWithData() public {
//         token.safeMint(address(new WrongReturnDataERC721Recipient()), 1337, "testing 123");
//     }
//
//     function testFailBalanceOfZeroAddress() public view {
//         token.balanceOf(address(0));
//     }
//
//     function testFailOwnerOfUnminted() public view {
//         token.ownerOf(1337);
//     }
//
//     function testMetadata(string memory name, string memory symbol) public {
//         MockERC721Batch tkn = new MockERC721Batch(name, symbol);
//
//         assertEq(tkn.name(), name);
//         assertEq(tkn.symbol(), symbol);
//     }
//
//     function testMint(address to, uint256 id) public {
//         if (to == address(0)) to = address(0xBEEF);
//
//         token.mint(to, id);
//
//         assertEq(token.balanceOf(to), 1);
//         assertEq(token.ownerOf(id), to);
//     }
//
//     function testBurn(address to, uint256 id) public {
//         if (to == address(0)) to = address(0xBEEF);
//
//         token.mint(to, id);
//         hevm.prank(to);
//         token.burn(id);
//
//         assertEq(token.balanceOf(to), 0);
//
//         hevm.expectRevert("NOT_MINTED");
//         token.ownerOf(id);
//     }
//
//     function testApprove(address to, uint256 id) public {
//         if (to == address(0)) to = address(0xBEEF);
//
//         token.mint(address(this), id);
//
//         token.approve(to, id);
//
//         assertEq(token.getApproved(id), to);
//     }
//
//     function testApproveBurn(address to, uint256 id) public {
//         token.mint(address(this), id);
//
//         token.approve(address(to), id);
//
//         token.burn(id);
//
//         assertEq(token.balanceOf(address(this)), 0);
//         assertEq(token.getApproved(id), address(0));
//
//         hevm.expectRevert("NOT_MINTED");
//         token.ownerOf(id);
//     }
//
//     function testApproveAll(address to, bool approved) public {
//         token.setApprovalForAll(to, approved);
//
//         assertBoolEq(token.isApprovedForAll(address(this), to), approved);
//     }
//
//     function testTransferFrom(uint256 id, address to) public {
//         address from = address(0xABCD);
//
//         if (to == address(0) || to == from) to = address(0xBEEF);
//
//         token.mint(from, id);
//
//         hevm.prank(from);
//         token.approve(address(this), id);
//
//         token.transferFrom(from, to, id);
//
//         assertEq(token.getApproved(id), address(0));
//         assertEq(token.ownerOf(id), to);
//         assertEq(token.balanceOf(to), 1);
//         assertEq(token.balanceOf(from), 0);
//     }
//
//     function testBatchMint(uint256[] memory ids, address to) public {
//         hevm.assume(ids.length > 0);
//         hevm.assume(ids.length <= 20);
//         ids = uniquify(ids);
//         uint256 id;
//         if (to == address(0)) to = address(0xBEEF);
//
//         token.batchMint(to, ids);
//
//         for (uint256 i; i < ids.length; i++) {
//             id = ids[i];
//             assertEq(token.getApproved(id), address(0));
//             assertEq(token.ownerOf(id), to);
//             assertEq(token.balanceOf(to), ids.length);
//         }
//     }
//
//     function testBatchTransferFrom(uint256[] memory ids, address to, address from) public {
//         if (from == address(0)) from = address(0xBEEF);
//         if (to == address(0) || to == from) to = address(0xCAFE);
//         ids = uniquify(ids);
//         hevm.assume(ids.length > 0);
//
//         testBatchMint(ids, from);
//
//         hevm.startPrank(from);
//         for (uint256 i; i < ids.length; i++) {
//             token.approve(address(this), ids[i]);
//         }
//         hevm.stopPrank();
//
//         token.batchTransferFrom(from, to, ids);
//
//         for (uint256 i; i < ids.length; i++) {
//             assertEq(token.getApproved(ids[i]), address(0));
//             assertEq(token.ownerOf(ids[i]), to);
//             assertEq(token.balanceOf(to), ids.length);
//             assertEq(token.balanceOf(from), 0);
//         }
//     }
//
//     function testBatchBurn(uint256[] memory ids, address to) public {
//         ids = uniquify(ids);
//         hevm.assume(ids.length > 0);
//
//         testBatchMint(ids, to);
//
//         hevm.startPrank(to);
//         for (uint256 i; i < ids.length; i++) {
//             token.approve(address(this), ids[i]);
//         }
//         hevm.stopPrank();
//
//         hevm.prank(to);
//         token.batchBurn(ids);
//     }
//
//     function testTransferFromSelf(uint256 id, address to) public {
//         if (to == address(0) || to == address(this)) to = address(0xBEEF);
//
//         token.mint(address(this), id);
//
//         token.transferFrom(address(this), to, id);
//
//         assertEq(token.getApproved(id), address(0));
//         assertEq(token.ownerOf(id), to);
//         assertEq(token.balanceOf(to), 1);
//         assertEq(token.balanceOf(address(this)), 0);
//     }
//
//     function testTransferFromApproveAll(uint256 id, address to) public {
//         address from = address(0xABCD);
//
//         if (to == address(0) || to == from) to = address(0xBEEF);
//
//         token.mint(from, id);
//
//         hevm.prank(from);
//         token.setApprovalForAll(address(this), true);
//
//         token.transferFrom(from, to, id);
//
//         assertEq(token.getApproved(id), address(0));
//         assertEq(token.ownerOf(id), to);
//         assertEq(token.balanceOf(to), 1);
//         assertEq(token.balanceOf(from), 0);
//     }
//
//     function testSafeTransferFromToEOA(uint256 id, address to) public {
//         address from = address(0xABCD);
//
//         if (to == address(0) || to == from) to = address(0xBEEF);
//
//         if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;
//
//         token.mint(from, id);
//
//         hevm.prank(from);
//         token.setApprovalForAll(address(this), true);
//
//         token.safeTransferFrom(from, to, id);
//
//         assertEq(token.getApproved(id), address(0));
//         assertEq(token.ownerOf(id), to);
//         assertEq(token.balanceOf(to), 1);
//         assertEq(token.balanceOf(from), 0);
//     }
//
//     function testSafeTransferFromToERC721Recipient(uint256 id) public {
//         address from = address(0xABCD);
//
//         ERC721Recipient recipient = new ERC721Recipient();
//
//         token.mint(from, id);
//
//         hevm.prank(from);
//         token.setApprovalForAll(address(this), true);
//
//         token.safeTransferFrom(from, address(recipient), id);
//
//         assertEq(token.getApproved(id), address(0));
//         assertEq(token.ownerOf(id), address(recipient));
//         assertEq(token.balanceOf(address(recipient)), 1);
//         assertEq(token.balanceOf(from), 0);
//
//         assertEq(recipient.operator(), address(this));
//         assertEq(recipient.from(), from);
//         assertEq(recipient.id(), id);
//         assertBytesEq(recipient.data(), "");
//     }
//
//     function testSafeTransferFromToERC721RecipientWithData(uint256 id, bytes calldata data) public {
//         address from = address(0xABCD);
//         ERC721Recipient recipient = new ERC721Recipient();
//
//         token.mint(from, id);
//
//         hevm.prank(from);
//         token.setApprovalForAll(address(this), true);
//
//         token.safeTransferFrom(from, address(recipient), id, data);
//
//         assertEq(token.getApproved(id), address(0));
//         assertEq(token.ownerOf(id), address(recipient));
//         assertEq(token.balanceOf(address(recipient)), 1);
//         assertEq(token.balanceOf(from), 0);
//
//         assertEq(recipient.operator(), address(this));
//         assertEq(recipient.from(), from);
//         assertEq(recipient.id(), id);
//         assertBytesEq(recipient.data(), data);
//     }
//
//     function testSafeMintToEOA(uint256 id, address to) public {
//         if (to == address(0)) to = address(0xBEEF);
//
//         if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;
//
//         token.safeMint(to, id);
//
//         assertEq(token.ownerOf(id), address(to));
//         assertEq(token.balanceOf(address(to)), 1);
//     }
//
//     function testSafeMintToERC721Recipient(uint256 id) public {
//         ERC721Recipient to = new ERC721Recipient();
//
//         token.safeMint(address(to), id);
//
//         assertEq(token.ownerOf(id), address(to));
//         assertEq(token.balanceOf(address(to)), 1);
//
//         assertEq(to.operator(), address(this));
//         assertEq(to.from(), address(0));
//         assertEq(to.id(), id);
//         assertBytesEq(to.data(), "");
//     }
//
//     function testSafeMintToERC721RecipientWithData(uint256 id, bytes calldata data) public {
//         ERC721Recipient to = new ERC721Recipient();
//
//         token.safeMint(address(to), id, data);
//
//         assertEq(token.ownerOf(id), address(to));
//         assertEq(token.balanceOf(address(to)), 1);
//
//         assertEq(to.operator(), address(this));
//         assertEq(to.from(), address(0));
//         assertEq(to.id(), id);
//         assertBytesEq(to.data(), data);
//     }
//
//     function testFailMintToZero(uint256 id) public {
//         token.mint(address(0), id);
//     }
//
//     function testFailDoubleMint(uint256 id, address to) public {
//         if (to == address(0)) to = address(0xBEEF);
//
//         token.mint(to, id);
//         token.mint(to, id);
//     }
//
//     function testFailBurnUnMinted(uint256 id) public {
//         token.burn(id);
//     }
//
//     function testFailDoubleBurn(uint256 id, address to) public {
//         if (to == address(0)) to = address(0xBEEF);
//
//         token.mint(to, id);
//
//         token.burn(id);
//         token.burn(id);
//     }
//
//     function testFailApproveUnMinted(uint256 id, address to) public {
//         token.approve(to, id);
//     }
//
//     function testFailApproveUnAuthorized(address owner, uint256 id, address to) public {
//         if (owner == address(0) || owner == address(this)) {
//             owner = address(0xBEEF);
//         }
//
//         token.mint(owner, id);
//
//         token.approve(to, id);
//     }
//
//     function testFailTransferFromUnOwned(address from, address to, uint256 id) public {
//         token.transferFrom(from, to, id);
//     }
//
//     function testFailTransferFromWrongFrom(address owner, address from, address to, uint256 id) public {
//         if (owner == address(0)) to = address(0xBEEF);
//         if (from == owner) revert();
//
//         token.mint(owner, id);
//
//         token.transferFrom(from, to, id);
//     }
//
//     function testFailTransferFromToZero(uint256 id) public {
//         token.mint(address(this), id);
//
//         token.transferFrom(address(this), address(0), id);
//     }
//
//     function testFailTransferFromNotOwner(address from, address to, uint256 id) public {
//         if (from == address(this)) from = address(0xBEEF);
//
//         token.mint(from, id);
//
//         token.transferFrom(from, to, id);
//     }
//
//     function testFailSafeTransferFromToNonERC721Recipient(uint256 id) public {
//         token.mint(address(this), id);
//
//         token.safeTransferFrom(address(this), address(new NonERC721Recipient()), id);
//     }
//
//     function testFailSafeTransferFromToNonERC721RecipientWithData(uint256 id, bytes calldata data) public {
//         token.mint(address(this), id);
//
//         token.safeTransferFrom(address(this), address(new NonERC721Recipient()), id, data);
//     }
//
//     function testFailSafeTransferFromToRevertingERC721Recipient(uint256 id) public {
//         token.mint(address(this), id);
//
//         token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), id);
//     }
//
//     function testFailSafeTransferFromToRevertingERC721RecipientWithData(uint256 id, bytes calldata data) public {
//         token.mint(address(this), id);
//
//         token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), id, data);
//     }
//
//     function testFailSafeTransferFromToERC721RecipientWithWrongReturnData(uint256 id) public {
//         token.mint(address(this), id);
//
//         token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), id);
//     }
//
//     function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData(uint256 id, bytes calldata data)
//         public
//     {
//         token.mint(address(this), id);
//
//         token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), id, data);
//     }
//
//     function testFailSafeMintToNonERC721Recipient(uint256 id) public {
//         token.safeMint(address(new NonERC721Recipient()), id);
//     }
//
//     function testFailSafeMintToNonERC721RecipientWithData(uint256 id, bytes calldata data) public {
//         token.safeMint(address(new NonERC721Recipient()), id, data);
//     }
//
//     function testFailSafeMintToRevertingERC721Recipient(uint256 id) public {
//         token.safeMint(address(new RevertingERC721Recipient()), id);
//     }
//
//     function testFailSafeMintToRevertingERC721RecipientWithData(uint256 id, bytes calldata data) public {
//         token.safeMint(address(new RevertingERC721Recipient()), id, data);
//     }
//
//     function testFailSafeMintToERC721RecipientWithWrongReturnData(uint256 id) public {
//         token.safeMint(address(new WrongReturnDataERC721Recipient()), id);
//     }
//
//     function testFailSafeMintToERC721RecipientWithWrongReturnDataWithData(uint256 id, bytes calldata data) public {
//         token.safeMint(address(new WrongReturnDataERC721Recipient()), id, data);
//     }
//
//     function testFailOwnerOfUnminted(uint256 id) public view {
//         token.ownerOf(id);
//     }
// }

// contract ERC721BatchTest is ERC721SpecTest {
//     function setUp() public override {
//         super.setUp();
//         token = IERC721Batch(address(new MockERC721Batch("Token", "TKN")));
//     }
// }
//
// contract ERC721ConsecutiveTest is ERC721SpecTest {
//     function setUp() public override {
//         super.setUp();
//         token = IERC721Batch(address(new MockERC721Consecutive("Token", "TKN")));
//     }
// }
