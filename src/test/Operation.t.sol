// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import "@tokenized-strategy/interfaces/ITokenizedStrategy.sol";
import {Setup, ERC20, IStrategyInterface} from "./utils/Setup.sol";

contract OperationTest is Setup {
    uint forkId;
    function setUp() public virtual override {
        forkId = vm.createSelectFork("",18756148);
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
        console.log("receiver address in deposit", receiver);
        strategy.tstorereceiver(receiver);
        mintAndDepositIntoStrategy((strategy),depositor, receiver, 1e18);
        console.log("block number in deposit",block.number);
    }


    function test_depositor_initial_steps() public {
        test_deposit();
        uint balanceofreceiver = callstrategygetuint("balanceOf(address)",receiver,1);
        vm.prank(receiver);
        strategy.transfer(depositor,balanceofreceiver);
        vm.prank(depositor);
        strategy.approve(receiver,1e18);
    }

    function test_withdraw_by_receiver_after_owner_death() public {
       test_depositor_initial_steps();
        vm.rollFork(forkId,18799549 );
        assertEq(block.number,18799549);

        (address _receiver,uint _time)  =  strategy.getbackup(depositor);
        console.log("receiver before withdraw",_receiver);
        console.log("timestamp saved before withdraw",_time);
        console.log("real timestamp",block.timestamp);
        console.log("time diff",block.timestamp - _time);
        withdrawfromStrategybyreceiver(strategy,depositor,0.9e18,receiver);
    }

    function test_withdraw_by_owner_before_death() public {
        test_depositor_initial_steps();
        withdrawfromStrategybyowner(strategy, depositor, 0.9e18, receiver);
    }

    function test_withdraw_by_owner_after_death() public {
        test_deposit();
        uint balanceofreceiver = callstrategygetuint("balanceOf(address)",receiver,1);
        console.log("balance of receiver",balanceofreceiver);
        vm.prank(receiver);
        strategy.transfer(depositor,balanceofreceiver);
        uint balanceofdepositor = callstrategygetuint("balanceOf(address)",depositor,1);
        console.log("balacne of depositor",balanceofdepositor);
        vm.rollFork(forkId,18799549 );
        assertEq(block.number,18799549);

        (address _receiver,uint _time)  =  strategy.getbackup(depositor);
        console.log("receiver before withdraw",_receiver);
        console.log("timestamp saved before withdraw",_time);
        console.log("real timestamp",block.timestamp);
        console.log("time diff",block.timestamp - _time);
        vm.expectRevert();
        withdrawfromStrategybyowner(strategy,depositor,0.9e18,receiver);
    }

    function test_withdraw_by_receiver_before_owner_death() public {
        test_depositor_initial_steps();
         (address _receiver,uint _time)  =  strategy.getbackup(depositor);
        console.log("receiver before withdraw",_receiver);
        console.log("timestamp saved before withdraw",_time);
        console.log("real timestamp",block.timestamp);
        console.log("time diff",block.timestamp - _time);
        vm.expectRevert("Only owner can transfer before death");
        withdrawfromStrategybyreceiver(strategy,depositor,0.9e18,receiver);
    }

    function callstrategygetaddress(string memory sig,address _address,uint _uint) public returns (address){
        (bool s ,bytes memory  data) = address(strategy).call(abi.encodeWithSignature(sig,(_address)));
        address _asset = abi.decode(data, (address));
        return _asset;
    }

     function callstrategygetuint(string memory sig,address _address,uint _uint) public returns (uint){
        (bool s ,bytes memory  data) = address(strategy).call(abi.encodeWithSignature(sig,(_address)));
        uint val = abi.decode(data, (uint256));
        return val;
    }

    function callstrategy(string memory sig) public returns (address){
        (bool s ,bytes memory  data) = address(strategy).call(abi.encodeWithSignature(sig));
        address val = abi.decode(data, (address));
        return val;
    }

    // function test_operation(uint256 _amount) public {
    //     vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

    //     // Deposit into strategy
    //     mintAndDepositIntoStrategy(strategy, user, _amount);

    //     // TODO: Implement logic so totalDebt is _amount and totalIdle = 0.
    //     assertEq(strategy.totalAssets(), _amount, "!totalAssets");
    //     assertEq(strategy.totalDebt(), 0, "!totalDebt");
    //     assertEq(strategy.totalIdle(), _amount, "!totalIdle");

    //     // Earn Interest
    //     skip(1 days);

    //     // Report profit
    //     vm.prank(keeper);
    //     (uint256 profit, uint256 loss) = strategy.report();

    //     // Check return Values
    //     assertGe(profit, 0, "!profit");
    //     assertEq(loss, 0, "!loss");

    //     skip(strategy.profitMaxUnlockTime());

    //     uint256 balanceBefore = asset.balanceOf(user);

    //     // Withdraw all funds
    //     vm.prank(user);
    //     strategy.redeem(_amount, user, user);

    //     assertGe(asset.balanceOf(user), balanceBefore + _amount, "!final balance");
    // }

    // function test_profitableReport(uint256 _amount, uint16 _profitFactor) public {
    //     vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
    //     _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));

    //     // Deposit into strategy
    //     mintAndDepositIntoStrategy(strategy, user, _amount);

    //     // TODO: Implement logic so totalDebt is _amount and totalIdle = 0.
    //     assertEq(strategy.totalAssets(), _amount, "!totalAssets");
    //     assertEq(strategy.totalDebt(), 0, "!totalDebt");
    //     assertEq(strategy.totalIdle(), _amount, "!totalIdle");

    //     // Earn Interest
    //     skip(1 days);

    //     // TODO: implement logic to simulate earning interest.
    //     uint256 toAirdrop = (_amount * _profitFactor) / MAX_BPS;
    //     airdrop(asset, address(strategy), toAirdrop);

    //     // Report profit
    //     vm.prank(keeper);
    //     (uint256 profit, uint256 loss) = strategy.report();

    //     // Check return Values
    //     assertGe(profit, toAirdrop, "!profit");
    //     assertEq(loss, 0, "!loss");

    //     skip(strategy.profitMaxUnlockTime());

    //     uint256 balanceBefore = asset.balanceOf(user);

    //     // Withdraw all funds
    //     vm.prank(user);
    //     strategy.redeem(_amount, user, user);

    //     assertGe(asset.balanceOf(user), balanceBefore + _amount, "!final balance");
    // }

    // function test_profitableReport_withFees(uint256 _amount, uint16 _profitFactor) public {
    //     vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);
    //     _profitFactor = uint16(bound(uint256(_profitFactor), 10, MAX_BPS));

    //     // Set protocol fee to 0 and perf fee to 10%
    //     setFees(0, 1_000);

    //     // Deposit into strategy
    //     mintAndDepositIntoStrategy(strategy, user, _amount);

    //     // TODO: Implement logic so totalDebt is _amount and totalIdle = 0.
    //     assertEq(strategy.totalAssets(), _amount, "!totalAssets");
    //     assertEq(strategy.totalDebt(), 0, "!totalDebt");
    //     assertEq(strategy.totalIdle(), _amount, "!totalIdle");

    //     // Earn Interest
    //     skip(1 days);

    //     // TODO: implement logic to simulate earning interest.
    //     uint256 toAirdrop = (_amount * _profitFactor) / MAX_BPS;
    //     airdrop(asset, address(strategy), toAirdrop);

    //     // Report profit
    //     vm.prank(keeper);
    //     (uint256 profit, uint256 loss) = strategy.report();

    //     // Check return Values
    //     assertGe(profit, toAirdrop, "!profit");
    //     assertEq(loss, 0, "!loss");

    //     skip(strategy.profitMaxUnlockTime());

    //     // Get the expected fee
    //     uint256 expectedShares = (profit * 1_000) / MAX_BPS;

    //     assertEq(strategy.balanceOf(performanceFeeRecipient), expectedShares);

    //     uint256 balanceBefore = asset.balanceOf(user);

    //     // Withdraw all funds
    //     vm.prank(user);
    //     strategy.redeem(_amount, user, user);

    //     assertGe(asset.balanceOf(user), balanceBefore + _amount, "!final balance");

    //     vm.prank(performanceFeeRecipient);
    //     strategy.redeem(expectedShares, performanceFeeRecipient, performanceFeeRecipient);

    //     checkStrategyTotals(strategy, 0, 0, 0);

    //     assertGe(asset.balanceOf(performanceFeeRecipient), expectedShares, "!perf fee out");
    // }

    // function test_tendTrigger(uint256 _amount) public {
    //     vm.assume(_amount > minFuzzAmount && _amount < maxFuzzAmount);

    //     (bool trigger,) = strategy.tendTrigger();
    //     assertTrue(!trigger);

    //     // Deposit into strategy
    //     mintAndDepositIntoStrategy(strategy, user, _amount);

    //     (trigger,) = strategy.tendTrigger();
    //     assertTrue(!trigger);

    //     // Skip some time
    //     skip(1 days);

    //     (trigger,) = strategy.tendTrigger();
    //     assertTrue(!trigger);

    //     vm.prank(keeper);
    //     strategy.report();

    //     (trigger,) = strategy.tendTrigger();
    //     assertTrue(!trigger);

    //     // Unlock Profits
    //     skip(strategy.profitMaxUnlockTime());

    //     (trigger,) = strategy.tendTrigger();
    //     assertTrue(!trigger);

    //     vm.prank(user);
    //     strategy.redeem(_amount, user, user);

    //     (trigger,) = strategy.tendTrigger();
    //     assertTrue(!trigger);
    // }
}
