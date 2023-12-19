// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import "@tokenized-strategy/interfaces/ITokenizedStrategy.sol";
import {Setup, ERC20, IStrategyInterface} from "./utils/Setup.sol";

contract OperationTest is Setup {
    uint256 forkId;

    function setUp() public virtual override {
        string memory eth_rpc_url = vm.envString("ETH_RPC_URL");
        forkId = vm.createSelectFork(eth_rpc_url, 18756148);
        super.setUp();
    }

    address public depositor = makeAddr("depositor");
    address public receiver = makeAddr("receiver");

    function test_setupStrategyOK() public {
        assertTrue(address(0) != address(strategy));
        address _asset = callstrategy("asset()");
        address _management = callstrategy("management()");
        address _performanceFeeRecipient = callstrategy("performanceFeeRecipient()");
        address _keeper = callstrategy("keeper()");
        assertEq(_asset, address(asset));
        assertEq(management, _management);
        assertEq(performanceFeeRecipient, _performanceFeeRecipient);
        assertEq(keeper, _keeper);
    }

    function test_deposit() public {
        strategy.tstorereceiver(receiver);
        mintAndDepositIntoStrategy((strategy), depositor, receiver, 1e18);
    }

    function test_depositor_initial_steps() public {
        test_deposit();
        uint256 balanceofreceiver = callstrategygetuint("balanceOf(address)", receiver, 1);
        vm.prank(receiver);
        strategy.transfer(depositor, balanceofreceiver);
        vm.prank(depositor);
        strategy.approve(receiver, 1e18);
    }

    function test_withdraw_by_receiver_after_owner_death() public {
        test_depositor_initial_steps();
        vm.rollFork(forkId, 18799549);
        assertEq(block.number, 18799549);

        (address _receiver, uint256 _time) = strategy.getbackup(depositor);

        withdrawfromStrategybyreceiver(strategy, depositor, 0.9e18, receiver);
    }

    function test_withdraw_by_owner_before_death() public {
        test_depositor_initial_steps();
        withdrawfromStrategybyowner(strategy, depositor, 0.9e18, receiver);
    }

    function test_withdraw_by_owner_after_death() public {
        test_deposit();
        uint256 balanceofreceiver = callstrategygetuint("balanceOf(address)", receiver, 1);
        vm.prank(receiver);
        strategy.transfer(depositor, balanceofreceiver);
        uint256 balanceofdepositor = callstrategygetuint("balanceOf(address)", depositor, 1);
        vm.rollFork(forkId, 18799549);
        assertEq(block.number, 18799549);

        (address _receiver, uint256 _time) = strategy.getbackup(depositor);

        vm.expectRevert();
        withdrawfromStrategybyowner(strategy, depositor, 0.9e18, receiver);
    }

    function test_withdraw_by_receiver_before_owner_death() public {
        test_depositor_initial_steps();
        (address _receiver, uint256 _time) = strategy.getbackup(depositor);
        vm.expectRevert("Only owner can transfer before death");
        withdrawfromStrategybyreceiver(strategy, depositor, 0.9e18, receiver);
    }
}
