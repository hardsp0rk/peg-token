// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../../src/PegToken.sol";

contract MockERC20 is PegToken {
    constructor() {
        initialize("Mock Token", "MOCK");
    }
}
