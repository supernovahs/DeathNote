// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {BaseStrategy, console, ERC20} from "./BaseStrategy.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPool} from "@aave-core/interfaces/IPool.sol";

//    DDDD   EEEEE   AAA   TTTTT  H    H  N   N   OOO   TTTTT  EEEEE
//    D   D  E      A   A    T    H    H  NN  N  O   O    T    E
//    D   D  EEEE   AAAAA    T    HHHHHH  N N N  O   O    T    EEEE
//    D   D  E      A   A    T    H    H  N  NN  O   O    T    E
//    DDDD   EEEEE  A   A    T    H    H  N   N   OOO     T    EEEEE

/// @author supernovahs.eth <https://github.com/supernovahs>
/// @notice A Yearnv3 strategy to protect funds against Death or critical disabilities
contract Strategy is BaseStrategy {
    using SafeERC20 for ERC20;

    address public immutable POOL;
    address public immutable WETH;
    IERC20 public aToken;

    struct Note {
        address backup;
        uint256 alivetimestamp;
    }

    mapping(address => Note) public DeathNote;
    mapping(address => address) public ReceivertoOwner;

    function getbackup(address _owner) public view returns (address, uint256) {
        address _depositor = DeathNote[_owner].backup;
        uint256 _time = DeathNote[_owner].alivetimestamp;
        return (_depositor, _time);
    }

    /**
     * @dev Should deploy up to '_amount' of 'asset' in the yield source.
     *
     * This function is called at the end of a {deposit} or {mint}
     * call. Meaning that unless a whitelist is implemented it will
     * be entirely permissionless and thus can be sandwiched or otherwise
     * manipulated.
     *
     * @param _amount The amount of 'asset' that the strategy should attempt
     * to deposit in the yield source.
     */
    function _deployFunds(uint256 _amount) internal override {
        // Already deposited before
        if (DeathNote[CALLER].alivetimestamp != 0) {
            // Assert owner is not dead. If dead, they cannot deposit more.
            // IMPORTANT: update 1 days to 365 days when deploying. using 1 days for testing purposes.
            assert(DeathNote[CALLER].alivetimestamp + 1 days > block.timestamp);
            DeathNote[CALLER].alivetimestamp = block.timestamp; // Death Note
            IERC20(WETH).approve(POOL, _amount);
            IPool(POOL).supply(WETH, _amount, address(this), uint16(0));
            // Depositing first time
        } else {
            require(ReceivertoOwner[RECEIVER] == address(0)); // New Caller cannot re use already used receiver
            ReceivertoOwner[RECEIVER] = CALLER;
            DeathNote[CALLER] = Note(RECEIVER, block.timestamp); // Death Note
            IERC20(WETH).approve(POOL, _amount); // aavev3
            IPool(POOL).supply(WETH, _amount, address(this), uint16(0)); // aavev3
        }
    }

    /**
     * @dev Will attempt to free the '_amount' of 'asset'.
     *
     * The amount of 'asset' that is already loose has already
     * been accounted for.
     *
     * This function is called during {withdraw} and {redeem} calls.
     * Meaning that unless a whitelist is implemented it will be
     * entirely permissionless and thus can be sandwiched or otherwise
     * manipulated.
     *
     * Should not rely on asset.balanceOf(address(this)) calls other than
     * for diff accounting purposes.
     *
     * Any difference between `_amount` and what is actually freed will be
     * counted as a loss and passed on to the withdrawer. This means
     * care should be taken in times of illiquidity. It may be better to revert
     * if withdraws are simply illiquid so not to realize incorrect losses.
     *
     * @param _amount, The amount of 'asset' to be freed.
     */
    function _freeFunds(uint256 _amount) internal override {
        address _owner = ReceivertoOwner[RECEIVER];
        // IMPORTANT: Update 1 days to 365 days ,when deploying in production.
        if (DeathNote[_owner].alivetimestamp + 1 days < block.timestamp) {
            // Owner is dead
            require(CALLER == RECEIVER); // Receiver can withdraw
            IPool(POOL).withdraw(WETH, _amount, address(this));
        } else {
            require(CALLER == _owner, "Only owner can transfer before death"); // Owner is alive
            DeathNote[_owner].alivetimestamp = block.timestamp; // Update liveness timestamp
            IPool(POOL).withdraw(WETH, _amount, address(this));
        }
    }

    /**
     * @dev Internal function to harvest all rewards, redeploy any idle
     * funds and return an accurate accounting of all funds currently
     * held by the Strategy.
     *
     * This should do any needed harvesting, rewards selling, accrual,
     * redepositing etc. to get the most accurate view of current assets.
     *
     * NOTE: All applicable assets including loose assets should be
     * accounted for in this function.
     *
     * Care should be taken when relying on oracles or swap values rather
     * than actual amounts as all Strategy profit/loss accounting will
     * be done based on this returned value.
     *
     * This can still be called post a shutdown, a strategist can check
     * `TokenizedStrategy.isShutdown()` to decide if funds should be
     * redeployed or simply realize any profits/losses.
     *
     * @return _totalAssets A trusted and accurate account for the total
     * amount of 'asset' the strategy currently holds including idle funds.
     */
    function _harvestAndReport() internal override returns (uint256 _totalAssets) {
        if (!TokenizedStrategy.isShutdown()) {
            IPool(POOL).withdraw(WETH, type(uint256).max, address(this));
        }
        _totalAssets = aToken.balanceOf(address(this)) + IERC20(WETH).balanceOf(address(this));
    }

    /// Maps the backup address using this function
    /// Asserts _recevier is indeed equal to our storage
    /// @param _receiver the receiver's address to which shares will be minted.
    function availableDepositLimit(address _receiver) public view override returns (uint256) {
        require(_receiver == RECEIVER, "sanity check failed");
        return type(uint256).max;
    }

    /// Asserts the receiver address in our Death Note is equal to the stored address in our temporary storage.
    /// @param _owner owner whose shares are being withdrawn
    function availableWithdrawLimit(address _owner) public view override returns (uint256) {
        address receiver = DeathNote[_owner].backup;
        require(receiver == RECEIVER, ";sanity check failed");
        return type(uint256).max;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _asset, string memory _name, address _weth, address _pool, address _atoken)
        BaseStrategy(_asset, _name)
    {
        WETH = _weth;
        POOL = _pool;
        aToken = IERC20(_atoken);
    }
}
