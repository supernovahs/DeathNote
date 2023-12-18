// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {ExtendedTest} from "./ExtendedTest.sol";
import {console2} from "forge-std/console2.sol";
import {Strategy, ERC20} from "../../Strategy.sol";
import {IStrategyInterface} from "../../interfaces/IStrategyInterface.sol";
import "@tokenized-strategy/interfaces/ITokenizedStrategy.sol";
// Inherit the events so they can be checked if desired.
import {IEvents} from "@tokenized-strategy/interfaces/IEvents.sol";

interface IFactory {
    function governance() external view returns (address);

    function set_protocol_fee_bps(uint16) external;

    function set_protocol_fee_recipient(address) external;
}

contract Setup is ExtendedTest, IEvents {
    // Contract instances that we will use repeatedly.
    ERC20 public asset;
    IStrategyInterface public strategy;

    mapping(string => address) public tokenAddrs;

    // Addresses for different roles we will use repeatedly.
    address public user = address(10);
    address public keeper = address(4);
    address public management = address(1);
    address public performanceFeeRecipient = address(3);

    // Address of the real deployed Factory
    address public factory;

    // Integer variables that will be used repeatedly.
    uint256 public decimals;
    uint256 public MAX_BPS = 10_000;

    // Fuzz from $0.01 of 1e6 stable coins up to 1 trillion of a 1e18 coin
    uint256 public maxFuzzAmount = 1e30;
    uint256 public minFuzzAmount = 10_000;

    // Default profit max unlock time is set for 10 days
    uint256 public profitMaxUnlockTime = 10 days;

    function setUp() public virtual {
        _setTokenAddrs();

        // Set asset
        asset = ERC20(tokenAddrs["WETH"]);
        decimals = 18;
        // Deploy strategy and set variables
        strategy = IStrategyInterface(setUpStrategy());

        //    factory = strategy.FACTORY();
        // factory = callstrategy("FACTORY()");
        // label all the used addresses for traces
        vm.label(keeper, "keeper");
        // vm.label(factory, "factory");
        vm.label(address(asset), "asset");
        vm.label(management, "management");
        vm.label(address(strategy), "strategy");
        vm.label(performanceFeeRecipient, "performanceFeeRecipient");
    }

    function setUpStrategy() public returns (address) {
        console2.log("setting up strategy");
        // we save the strategy as a IStrategyInterface to give it the needed interface
        IStrategyInterface _strategy = IStrategyInterface(
            address(
                new Strategy(address(asset), "Death Note",0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2,0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8)
            )
        );
        // set keeper
        _strategy.setKeeper(keeper);
        // set treasury
        _strategy.setPerformanceFeeRecipient(performanceFeeRecipient);
        // set management of the strategy
        _strategy.setPendingManagement(management);

        vm.prank(management);
        _strategy.acceptManagement();

        return address(_strategy);
    }

    function callstrategygetaddress(string memory sig, address _address, uint256 _uint) public returns (address) {
        (bool s, bytes memory data) = address(strategy).call(abi.encodeWithSignature(sig, (_address)));
        address _asset = abi.decode(data, (address));
        return _asset;
    }

    function callstrategygetuint(string memory sig, address _address, uint256 _uint) public returns (uint256) {
        (bool s, bytes memory data) = address(strategy).call(abi.encodeWithSignature(sig, (_address)));
        uint256 val = abi.decode(data, (uint256));
        return val;
    }

    function callstrategy(string memory sig) public returns (address) {
        (bool s, bytes memory data) = address(strategy).call(abi.encodeWithSignature(sig));
        address val = abi.decode(data, (address));
        return val;
    }

    function depositIntoStrategy(IStrategyInterface _strategy, address depositor, address receiver, uint256 _amount)
        public
    {
        vm.label(address(_strategy), "strategy");
        vm.label(receiver, "receiver");
        vm.label(depositor, "depositor");
        vm.prank(depositor);
        asset.approve(address(_strategy), _amount);
        console2.log("approved");
        console.log("block number just right before", block.number);
        vm.prank(depositor);
        _strategy.deposit(_amount, receiver);
        console2.log("deposited");
    }

    function withdrawfromStrategybyowner(
        IStrategyInterface _strategy,
        address depositor,
        uint256 _amount,
        address _receiver
    ) public {
        vm.prank(depositor);
        _strategy.withdraw(_amount, _receiver, depositor);
    }

    function withdrawfromStrategybyreceiver(
        IStrategyInterface _strategy,
        address depositor,
        uint256 _amount,
        address _receiver
    ) public {
        vm.prank(_receiver);
        _strategy.withdraw(_amount, _receiver, depositor);
    }

    function mintAndDepositIntoStrategy(
        IStrategyInterface _strategy,
        address depositor,
        address receiver,
        uint256 _amount
    ) public {
        airdrop(asset, depositor, _amount);
        depositIntoStrategy(_strategy, depositor, receiver, _amount);
    }

    // For checking the amounts in the strategy
    function checkStrategyTotals(
        IStrategyInterface _strategy,
        uint256 _totalAssets,
        uint256 _totalDebt,
        uint256 _totalIdle
    ) public {
        assertEq(_strategy.totalAssets(), _totalAssets, "!totalAssets");
        assertEq(_strategy.totalDebt(), _totalDebt, "!totalDebt");
        assertEq(_strategy.totalIdle(), _totalIdle, "!totalIdle");
        assertEq(_totalAssets, _totalDebt + _totalIdle, "!Added");
    }

    function airdrop(ERC20 _asset, address _to, uint256 _amount) public {
        uint256 balanceBefore = _asset.balanceOf(_to);
        deal(address(_asset), _to, balanceBefore + _amount);
    }

    function setFees(uint16 _protocolFee, uint16 _performanceFee) public {
        address gov = IFactory(factory).governance();

        // Need to make sure there is a protocol fee recipient to set the fee.
        vm.prank(gov);
        IFactory(factory).set_protocol_fee_recipient(gov);

        vm.prank(gov);
        IFactory(factory).set_protocol_fee_bps(_protocolFee);

        vm.prank(management);
        strategy.setPerformanceFee(_performanceFee);
    }

    function _setTokenAddrs() internal {
        tokenAddrs["WBTC"] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        tokenAddrs["YFI"] = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
        tokenAddrs["WETH"] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        tokenAddrs["LINK"] = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
        tokenAddrs["USDT"] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        tokenAddrs["DAI"] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        tokenAddrs["USDC"] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }
}
