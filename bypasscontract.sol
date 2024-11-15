// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol"; // Import console for logging

/*
Your mission: Find a way to bypass this security measure.
Objective: Make vaultManager.accessGranted() return true
Difficulty: Medium
FLAG FORMAT: "CTF{address_that_succeeded}"

RULES:
1. The VaultManager contract cannot be modified
2. You can only write code in testVaultAccess()
3. The vault must be accessed programmatically
4. No external contract deployments allowed
*/

contract ContractTest is Test {
    VaultManager public vaultManager;   
    
    constructor() {
        vaultManager = new VaultManager();
    }
    
    function testVaultAccess() public {
        // Initial check to ensure vault access is initially denied
        assertFalse(vaultManager.accessGranted(), "Invalid initial state");

        // Expect the AccessGranted event to be emitted
        vm.expectEmit(true, true, true, true);
        emit VaultManager.AccessGranted();
        
        address eoa = address(0x123);
        vm.prank(eoa);
        vaultManager.authenticateAccess();
        
        // Ensure the accessGranted flag is now true
        assertTrue(vaultManager.accessGranted(), "Challenge incomplete: The vault remains locked");
    }
}

contract VaultManager {
    bool public accessGranted;
    event AccessGranted();
    
    function validateUser(address account) public view returns (bool) {
        uint256 codeFootprint;
        assembly {
            codeFootprint := extcodesize(account)
        }
        return codeFootprint > 0;
    }
    
    function authenticateAccess() external {
        require(!validateUser(msg.sender), "Access denied: Contracts not allowed");
        accessGranted = true;
        emit AccessGranted();
    }
}
