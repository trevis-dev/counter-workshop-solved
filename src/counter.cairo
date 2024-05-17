
#[starknet::interface]
trait ICounter<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(ref self: TContractState);
}

#[starknet::interface]
trait IKillSwitch<TContractState> {
    fn is_active(self: @TContractState) -> bool;
}

#[starknet::contract]
mod Counter {
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::ContractAddress;
    use super::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        counter: u32,
        kill_switch: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncreased,
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        #[key]
        value: u32
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_value: u32, kill_switch: ContractAddress, initial_owner: ContractAddress) {
        self.counter.write(initial_value);
        self.kill_switch.write(kill_switch);
        self.ownable.initializer(initial_owner);
    }

    #[abi(embed_v0)]
    impl Counter of super::ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }
        fn increase_counter(ref self: ContractState) {
            self.ownable.assert_only_owner();
            if (IKillSwitchDispatcher { contract_address: self.kill_switch.read()}).is_active() {
                panic!("Kill Switch is active");  // test doesn't want a single felt252.
            }
            self.counter.write(self.counter.read() + 1);
            self.emit(CounterIncreased { value:  self.counter.read() });
        }
    }
}
