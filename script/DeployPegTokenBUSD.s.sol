// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../src/PegToken.sol";

contract DeployPegTokenBUSDScript is Script {
    string internal constant NAME = "Binance-Peg BUSD Token";
    string internal constant SYMBOL = "BUSD";

    function setUp() public {}

    function run() public {
        vm.broadcast();

        PegToken impl = new PegToken();
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl),
            address(proxyAdmin),
            abi.encodeWithSignature("initialize(string,string)", NAME, SYMBOL)
        );
        impl.initialize(NAME, SYMBOL); // prevent uninitialized implementation

        vm.stopBroadcast();
    }
}
