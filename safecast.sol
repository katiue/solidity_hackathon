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
        console.log(secureVault.getFlag());
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
    bytes32 private internalHash = hex"466c61675f5377246e4275356e335f564e";

    function store(uint256 value) public {
        require(value < 256, "Value must be less than 256");
        uint8 limitedValue = uint8(value);
        records[msg.sender] = limitedValue;
    }

    function retrieve() public view returns (uint) {
        return records[msg.sender];
    }

    function getFlag() public view returns (string memory) {
        bytes32 hexData = internalHash; // Use the internalHash as bytes32
        uint256 length = 0;

        // Calculate the number of meaningful bytes (non-zero trailing bytes)
        for (uint256 i = 0; i < 32; i++) {
            if (hexData[i] != 0) {
                length = i + 1;
            }
        }

        // Allocate a dynamic bytes array for the ASCII result
        bytes memory asciiString = new bytes(length);

        // Convert the hex bytes to ASCII
        for (uint256 i = 0; i < length; i++) {
            asciiString[i] = hexData[i];
        }

        return string(asciiString);
    }
}