// SPDX-License-Identifier: MIT
// Find the vuln, write the exploit POC, and how to mitigate
pragma solidity ^0.8.18;

contract TreasureVault {
    uint256 public totalTreasure = 2500;
    address public currentExplorer;
    address public vaultKeeper = msg.sender;
    bool public isActive = true;
    uint256 private lastAccessTime;
    
    event ExplorerSelected(address indexed explorer, uint256 timestamp);
    
    modifier onlyVaultKeeper() {
        require(msg.sender == vaultKeeper, "Not authorized");
        _;
    }
    
    modifier onlyDuringExpedition() {
        if (msg.sender == getVaultAccess() || msg.sender == vaultKeeper) {
            _;
        } else {
            checkCurrentExplorer();
        }
    }

    function getVaultAccess() internal view returns (address authorized) {
        return vaultKeeper;  // Directly return the vaultKeeper address
    }
    
    function initiateExpedition(
        address explorer, 
        uint256 timestamp
    ) public onlyDuringExpedition {
        require(isActive, "Expedition ended");
        lastAccessTime = timestamp;
        
        currentExplorer = explorer;  // Safely set the explorer through a regular function
        
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
