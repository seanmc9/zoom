// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@v3-core/interfaces/IUniswapV3Pool.sol";

contract Zoom is ERC20, Ownable {
    uint160 internal constant MIN_SQRT_RATIO = 4295128739; // (from TickMath) The minimum value that can be returned from getSqrtRatioAtTick

    IUniswapV3Pool public pool;

    error PoolNotMadeYet();

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(msg.sender, 100000 ether);
    }

    /**
     * @dev This pool needs to have this contract's token as token1, and the native asset to the chain as token0.
     */
    function setPool(IUniswapV3Pool pool_) public onlyOwner {
        pool = pool_;
    }

    /**
     * @dev Mint this token by taking the money sent and buying it from the market.
     */
    function mint() public payable {
        // Make sure the pool exists. credit: https://github.com/jbx-protocol/juice-buyback/blob/b76f84b8bc55fad2f58ade2b304434cac52efc55/contracts/JBBuybackDelegate.sol#L485
        try pool.slot0() returns (uint160, int24, uint16, uint16, uint16, uint8, bool unlocked) {
            // If the pool hasn't been initialized, return an empty quote.
            if (!unlocked) revert PoolNotMadeYet();
        } catch {
            // If the address is invalid or if the pool has not yet been deployed, return an empty quote.
            revert PoolNotMadeYet();
        }

        pool.swap(msg.sender, true, int256(msg.value), MIN_SQRT_RATIO + 1, "");
    }
}
