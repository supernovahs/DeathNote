// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {IStrategy} from "@tokenized-strategy/interfaces/IStrategy.sol";

interface IStrategyInterface is IStrategy {
//TODO: Add your specific implementation interface in here.

    function tstorereceiver(address receiver) external ;

    function getbackup(address _owner) external returns (address,uint);
}
