// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ExploitMitigationTest is Test {
    GalacticTokenMitigate tokenContract;
    address deployer = vm.addr(1);
    address victim = vm.addr(2);
    address attacker = vm.addr(3);

    function setUp() public {
        vm.prank(deployer);
        tokenContract = new GalacticTokenMitigate();

        // Initial setup
        vm.warp(block.timestamp + 1 hours);
        vm.prank(deployer);
        tokenContract.mint(5000);

        // Give victim some tokens
        vm.prank(deployer);
        tokenContract.transfer(victim, 1000);
    }

    function testMitigatedExploit() public {
        console.log("Victim initial balance:", tokenContract.balanceOf(victim));
        console.log(
            "Attacker initial balance:",
            tokenContract.balanceOf(attacker)
        );

        // Step 1: Victim approves attacker for a limited amount (500 tokens)
        vm.prank(victim);
        tokenContract.approve(attacker, 500);

        // Step 2: Attacker drains the approved amount
        vm.prank(attacker);
        tokenContract.transferFrom(victim, attacker, 500);

        console.log(
            "Victim balance after first drain:",
            tokenContract.balanceOf(victim)
        );
        console.log(
            "Attacker balance after first drain:",
            tokenContract.balanceOf(attacker)
        );

        // Step 3: Victim receives more tokens (e.g., as a reward or transfer)
        vm.prank(deployer);
        tokenContract.transfer(victim, 500);

        console.log(
            "Victim balance after receiving more tokens:",
            tokenContract.balanceOf(victim)
        );

        // Step 4: Attacker tries to drain additional tokens without new approval
        vm.expectRevert("Insufficient allowance");
        vm.prank(attacker);
        tokenContract.transferFrom(victim, attacker, 500);

        console.log(
            "Victim balance after failed second drain attempt:",
            tokenContract.balanceOf(victim)
        );
        console.log(
            "Attacker balance after failed second drain attempt:",
            tokenContract.balanceOf(attacker)
        );

        // Verify the second drain was prevented
        assertEq(
            tokenContract.balanceOf(victim),
            1000,
            "Victim should retain the second set of tokens"
        );
        assertEq(
            tokenContract.balanceOf(attacker),
            500,
            "Attacker should not gain additional tokens"
        );

        console.log("Mitigation successful - Second drain attempt failed!");
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract GalacticTokenMitigate is IERC20 {
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

    function transfer(
        address recipient,
        uint amount
    ) external onlyPositive(amount) returns (bool) {
        require(recipient != address(0), "Invalid recipient");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Invalid spender");
        require(amount <= balanceOf[msg.sender], "Approval exceeds balance");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function revokeApproval(address spender) external {
        allowance[msg.sender][spender] = 0;
        emit Approval(msg.sender, spender, 0);
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool) {
        require(spender != address(0), "Invalid spender");
        uint256 newAllowance = allowance[msg.sender][spender] + addedValue;
        require(
            newAllowance <= balanceOf[msg.sender],
            "Allowance exceeds balance"
        );
        allowance[msg.sender][spender] = newAllowance;
        emit Approval(msg.sender, spender, newAllowance);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool) {
        require(spender != address(0), "Invalid spender");
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "Decreased allowance below zero"
        );
        allowance[msg.sender][spender] = currentAllowance - subtractedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external onlyPositive(amount) returns (bool) {
        require(recipient != address(0), "Invalid recipient");
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(
            allowance[sender][msg.sender] >= amount,
            "Insufficient allowance"
        );
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        require(
            block.timestamp >= lastMintTime + MINT_COOLDOWN,
            "Minting in cooldown"
        );
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