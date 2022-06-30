// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../src/PegToken.sol";

contract DeployPegTokenBUSDTest is Test {
    uint256 internal ownerPrivateKey;
    address internal owner;
    string internal constant NAME = "Binance-Peg BUSD Token";
    string internal constant SYMBOL = "BUSD";
    PegToken internal impl;
    ProxyAdmin internal proxyAdmin;
    TransparentUpgradeableProxy internal proxy;

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);

        vm.startPrank(owner);
        
        // refer to script/DeployPegTokenBUSD.s.sol
        impl = new PegToken();
        proxyAdmin = new ProxyAdmin();
        proxy = new TransparentUpgradeableProxy(
            address(impl),
            address(proxyAdmin),
            abi.encodeWithSignature("initialize(string,string)", NAME, SYMBOL)
        );
        impl.initialize(NAME, SYMBOL);

        vm.stopPrank();
    }

    function test_Initialize() public {
        assertEq(proxyAdmin.owner(), owner);
        assertEq(proxyAdmin.getProxyAdmin(proxy), address(proxyAdmin));
        assertEq(proxyAdmin.getProxyImplementation(proxy), address(impl));
        assertEq(keccak256(abi.encodePacked(PegToken(address(proxy)).name())), keccak256(abi.encodePacked(NAME)));
        assertEq(keccak256(abi.encodePacked(PegToken(address(proxy)).symbol())), keccak256(abi.encodePacked(SYMBOL)));
        assertEq(keccak256(abi.encodePacked(impl.name())), keccak256(abi.encodePacked(NAME)));
        assertEq(keccak256(abi.encodePacked(impl.symbol())), keccak256(abi.encodePacked(SYMBOL)));
    }
}
