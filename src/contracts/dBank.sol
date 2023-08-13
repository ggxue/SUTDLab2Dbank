// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Token.sol";

contract MultiSignature {
    // Define a separate contract for multi-signature functionality
    address[] public approvers;
    uint public quorum;

    mapping(address => mapping(address => bool)) public isApproved;

    constructor(address[] memory _approvers, uint _quorum) {
        approvers = _approvers;
        quorum = _quorum;
    }

    function requestApproval(address targetContract, bytes memory functionData) public {
        require(isApproved[msg.sender][targetContract] == false, "Already approved");

        // Simplified hash function for brevity, use keccak256 in production
        bytes32 proposalHash = sha256(abi.encodePacked(targetContract, functionData));

        // Mark the sender as having approved this proposal
        isApproved[msg.sender][targetContract] = true;

        // Check if quorum has been reached
        uint approvalCount = 0;
        for (uint i = 0; i < approvers.length; i++) {
            if (isApproved[approvers[i]][targetContract]) {
                approvalCount++;
                if (approvalCount >= quorum) {
                    // Execute the function on the target contract
                    (bool success, ) = targetContract.call(functionData);
                    require(success, "Function execution failed");
                    break;
                }
            }
        }
    }
}

contract dBank {
    Token private token;

    // Multi-signature contract address and quorum
    address public multiSignatureContract;
    uint public quorum;

    // Existing mappings and events
    mapping(address => uint) public depositStart;
    mapping(address => uint) public etherBalanceOf;
    mapping(address => uint) public collateralEther;
    mapping(address => bool) public isDeposited;
    mapping(address => bool) public isBorrowed;
    
    event Deposit(address indexed user, uint etherAmount, uint timeStart);
    event Withdraw(address indexed user, uint etherAmount, uint depositTime, uint interest);
    event Borrow(address indexed user, uint collateralEtherAmount, uint borrowedTokenAmount);
    event PayOff(address indexed user, uint fee);

    constructor(Token _token, address _multiSignatureContract, uint _quorum) public {
        token = _token;
        multiSignatureContract = _multiSignatureContract;
        quorum = _quorum;
    }

    // Function to request multi-signature approval for changing interest rate
    function requestInterestRateChange(uint newInterestRate) public {
        // Construct function data for the changeInterestRate function
        bytes memory functionData = abi.encodeWithSignature("changeInterestRate(uint256)", newInterestRate);

        // Request approval through the multi-signature contract
        MultiSignature(multiSignatureContract).requestApproval(address(this), functionData);
    }
}