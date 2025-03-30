#[starknet::contract]
mod NftScavenger {
    use starknet::{ContractAddress, get_caller_address};
    use traits::ISRC12;
    use option::OptionTrait;
    use array::ArrayTrait;

    #[storage]
    struct Storage {
        // Track player progress (level, attempts)
        player_level: LegacyMap<ContractAddress, u256>,
        question_attempts: LegacyMap<(ContractAddress, u256), u256>, // (player, question_id) => attempts
        // Hints configuration
        hint_access_level: LegacyMap<u256, u256>, // question_id => required_level
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        HintRequested: HintRequested,
    }

    #[derive(Drop, starknet::Event)]
    struct HintRequested {
        player: ContractAddress,
        question_id: u256,
        timestamp: u64,
    }

    #[external(v0)]
    impl NftScavenger {
        /// Initialize player (call this first)
        fn init_player(ref self: ContractState) {
            let player = get_caller_address();
            assert(self.player_level.read(player) == 0, 'Already initialized');
            self.player_level.write(player, 1); // Start at level 1
        }

        /// Request hint with access control
        #[view]
        fn request_hint(
            ref self: ContractState,
            question_id: u256
        ) -> Array<felt252> {
            let player = get_caller_address();
            
            // 1. Check player initialized
            assert(self.player_level.read(player) > 0, 'Player not initialized');
            
            // 2. Verify level access
            let required_level = self.hint_access_level.read(question_id);
            assert(
                self.player_level.read(player) >= required_level,
                'Insufficient level'
            );
            
            // 3. Check attempt exists
            let attempts = self.question_attempts.read((player, question_id));
            assert(attempts > 0, 'No attempts detected');
            
            // 4. Emit event
            self.emit(HintRequested {
                player,
                question_id,
                timestamp: get_block_timestamp(),
            });
            
            // Return hint (mock - implement your logic)
            array!['HINT: Think about StarkNet storage proofs']
        }

        /// Register question attempt (call before requesting hints)
        fn record_attempt(ref self: ContractState, question_id: u256) {
            let player = get_caller_address();
            let key = (player, question_id);
            self.question_attempts.write(key, self.question_attempts.read(key) + 1);
        }
    }
}