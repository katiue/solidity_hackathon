// SPDX-License-Identifier: MIT
// Find the vuln, write the exploit POC, how to mitigate, and what is the flag
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ChallengeTest is Test {
    Vault public vault;
    SecureVault public secureVault;

    function setUp() public {
        vault = new Vault();
        secureVault = new SecureVault();
    }

    function testVulnerableCast() public {
        vault.store(257);

        console.log(
            "Balance in vault:",
            vault.retrieve()
        );

        assertEq(vault.retrieve(), 1);
    }

    function testSafeCast() public {
        vm.expectRevert();
        secureVault.store(257);
    }

    receive() external payable {}
}

contract Vault {
    mapping(address => uint) private records;

    function store(uint256 value) public {
        uint8 limitedValue = uint8(value);
        records[msg.sender] = limitedValue;
    }

    function retrieve() public view returns (uint) {
        return records[msg.sender];
    }
}

contract SecureVault {
    mapping(address => uint) private records;
    bytes32 private internalHash;

    constructor() {
        // Set a default value for internalHash (e.g., hash of the contract address)
        internalHash = keccak256(abi.encodePacked(address(this)));
    }

    function store(uint256 value) public {
        require(value < 256, "Value must be less than 256");
        uint8 limitedValue = uint8(value);
        records[msg.sender] = limitedValue;
    }

    function retrieve() public view returns (uint) {
        return records[msg.sender];
    }

    // Restricted setter for updating the hash
    function updateHash(bytes32 newHash) public onlyOwner {
        require(newHash != bytes32(0), "Hash cannot be empty");
        internalHash = newHash;
    }

    // Restricted access modifier for owner-only functions
    modifier onlyOwner() {
        require(msg.sender == owner(), "Caller is not the owner");
        _;
    }

    function owner() internal view returns (address) {
        // Replace with actual ownership logic
        return address(this); // owner address
    }
}