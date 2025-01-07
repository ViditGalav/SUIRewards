#[test_only]
module grantproject::proofOfLoyalty_tests{
    use sui::coin::{Self, Coin};

    use sui::clock::{Self, Clock};
    // simpler at the begening only sui coin
    use sui::sui::SUI;
    use grantproject::proofOfLoyalty::{Self,Winner,ProofOfLoyalty, AdminCap, ContainerManager};
    use std::debug;

    use sui::test_scenario;

    const ErrWithdraw: u64 = 1;
    const ErrWithdrawSendMoney: u64 = 2;
    const ErrContainerAmount: u64 = 3;
    const ErrContainerSize: u64 = 4;
    const ErrContainerWinner: u64 = 5;
    const ErrContainerWinnerTime: u64 = 6;

    #[test]
    fun test_POF(){

        let admin = @0x1;
        let user1 = @0x2;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;

        let clock = clock::create_for_testing(test_scenario::ctx(scenario));

        {
            proofOfLoyalty::init_for_testing(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, user1);
        {

            let coin = coin::mint_for_testing<SUI>(1000, test_scenario::ctx(scenario) );
            let containerManager = test_scenario::take_shared<ContainerManager>(scenario);

            proofOfLoyalty::depositFlexMoney( &mut containerManager, coin, &clock,test_scenario::ctx(scenario));

            assert!(proofOfLoyalty::getContainerAmount(&containerManager) == 1000, ErrContainerAmount);
            assert!(proofOfLoyalty::getContainerSize(&containerManager)== 1,ErrContainerSize );

            test_scenario::return_shared<ContainerManager>(containerManager);
        };

        test_scenario::next_tx(scenario, user1);
        {
            // > 3 days
            clock::increment_for_testing(&mut clock,266400000);

            // to pay minitng fees
            let coin = coin::mint_for_testing<SUI>(9, test_scenario::ctx(scenario) );

            let containerManager = test_scenario::take_shared<ContainerManager>(scenario);
            proofOfLoyalty::mintFlexNFT(&mut containerManager, coin, &clock, test_scenario::ctx(scenario));

            let winnerAmount = proofOfLoyalty::getContainerWinnerAmount(&containerManager);
            let winnerTime = proofOfLoyalty::getContainerWinnerTime(&containerManager);

            debug::print(&containerManager);
            debug::print(&clock::timestamp_ms(&clock));

            //assert!(test_scenario::take_from_sender<ProofOfLoyalty>(scenario) , 9);
            
            assert!(proofOfLoyalty::getWinnerAmount(winnerAmount) == 1000, ErrContainerWinner);
            assert!(proofOfLoyalty::getWinnerAmount(winnerTime) == 266400000/86400000 , ErrContainerWinnerTime);

            test_scenario::return_shared<ContainerManager>(containerManager);

        };

        test_scenario::next_tx(scenario, user1);
        {
            
            let containerManager = test_scenario::take_shared<ContainerManager>(scenario);

            proofOfLoyalty::redeemFlexMoney( &mut containerManager, test_scenario::ctx(scenario));

            assert!(proofOfLoyalty::getContainerAmount(&containerManager)== 0, ErrContainerAmount);

            // take the user balance to check if he received well the money
            //let coin = test_scenario::take_from_sender<Coin<SUI>>(scenario);
            //assert!(coin::value(&coin) == 1000, 404);
            //test_scenario::return_to_sender(scenario, coin);

            test_scenario::return_shared<ContainerManager>(containerManager);
        };

        test_scenario::next_tx(scenario, admin);
        {
            let containerManager = test_scenario::take_shared<ContainerManager>(scenario);
            let cap = test_scenario::take_from_sender<AdminCap>(scenario);


            proofOfLoyalty::takeProfit(&cap, &mut containerManager, test_scenario::ctx(scenario));
            assert!(proofOfLoyalty::getContainerFees(&containerManager)== 0, ErrWithdraw);

           

            test_scenario::return_to_sender(scenario, cap);
            test_scenario::return_shared<ContainerManager>(containerManager);
        };
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }
}