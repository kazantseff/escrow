// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error NoUpkeepNeeded();

contract Escrow is AutomationCompatibleInterface {
    /* ======== GLOBAL VARIABLES ======== */

    /** @notice Struct to track possible buyer's request for a refund */
    struct RefundRequest {
        uint index;
        bool isApproved;
        bool executed;
    }

    RefundRequest[] public requests;

    address public arbiter;
    address public beneficiary;
    address public depositor;
    // Variable to check if escrow is open/closed
    bool public isOpen;
    // Variables for time-lock mechanic
    uint public lastTimeStamp;
    uint public interval;
    uint public fee; // 1%

    /* ======== MODIFIERS ======== */
    modifier OnlyArbiter() {
        require(msg.sender == arbiter);
        _;
    }

    modifier OnlyDepositor() {
        require(msg.sender == depositor);
        _;
    }

    modifier NotApproved(uint id) {
        require(requests[id].isApproved == false);
        _;
    }

    modifier Approved(uint id) {
        require(requests[id].isApproved == true);
        _;
    }

    modifier NotExecuted(uint id) {
        require(requests[id].executed == false);
        _;
    }

    /* ======== EVENTS ======== */
    event Deposited(address indexed depositor, uint indexed value);

    event FeeWithdrawn(uint indexed amount);
    event RefundRequested(uint indexed id);
    event RefundApproved(uint indexed id);
    event RefundExecuted(uint indexed id);
    event TimeLockRefunded();

    /* ======== CONSTRUCTOR ======== */
    constructor(
        address _arbiter,
        address _beneficiary,
        uint _interval,
        uint _fee
    ) payable {
        require(msg.value > 0, "Must deposit ETH");
        arbiter = _arbiter;
        beneficiary = _beneficiary;
        depositor = msg.sender;
        lastTimeStamp = block.timestamp;
        interval = _interval;
        fee = _fee;
        isOpen = true;

        emit Deposited(depositor, msg.value);
    }

    /* ======== FUNCTIONS ======== */

    /** @notice Function to approve transfer of funds to the beneficiary */
    function releaseFunds() public OnlyArbiter {
        uint balance = (address(this).balance * (1000 - fee)) / 1000;
        (bool sent, ) = payable(beneficiary).call{value: balance}("");
        require(sent, "Failed to send Ether");

        isOpen = false;
    }

    /** @notice Function to request refund */
    function requestRefund() public OnlyDepositor {
        uint index = requests.length;
        requests.push(
            RefundRequest({index: index, isApproved: false, executed: false})
        );

        emit RefundRequested(index);
    }

    /** @notice Function to approve refund by its id */
    function approveRefund(uint id) public OnlyArbiter NotApproved(id) {
        requests[id].isApproved = true;

        emit RefundApproved(id);
    }

    function executeRefund(
        uint id
    ) public OnlyArbiter Approved(id) NotExecuted(id) {
        uint balance = (address(this).balance * (1000 - fee)) / 1000;
        (bool success, ) = payable(depositor).call{value: balance}("");
        require(success, "Failed transfer of funds");
        requests[id].executed = true;

        isOpen = false;
        emit RefundExecuted(id);
    }

    function checkUpkeep(
        bytes memory /* checkdata */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* PerformData */)
    {
        bool open = true;
        bool intervalPassed = (block.timestamp - lastTimeStamp) > interval;
        bool enoughETH = address(this).balance > 0;
        upkeepNeeded = (open && intervalPassed && enoughETH);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* PerformData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) revert NoUpkeepNeeded();

        uint balance = (address(this).balance * (1000 - fee)) / 1000;

        (bool success, ) = payable(depositor).call{value: balance}("");
        require(success);
        isOpen = false;

        emit TimeLockRefunded();
    }

    function withdrawFees() public OnlyArbiter {
        uint balance = address(this).balance * (fee / 100);
        (bool success, ) = payable(arbiter).call{value: balance}("");
        require(success);

        emit FeeWithdrawn(balance);
    }
}
