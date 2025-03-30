#[starknet::contract]
pub mod MockERC1155Receiver {
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc1155::ERC1155ReceiverComponent;

    component!(
        path: ERC1155ReceiverComponent, storage: erc1155_receiver, event: ERC1155ReceiverEvent
    );
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // ERC1155Receiver Mixin
    #[abi(embed_v0)]
    impl ERC1155ReceiverMixinImpl =
        ERC1155ReceiverComponent::ERC1155ReceiverMixinImpl<ContractState>;
    impl ERC1155ReceiverInternalImpl = ERC1155ReceiverComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc1155_receiver: ERC1155ReceiverComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC1155ReceiverEvent: ERC1155ReceiverComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.erc1155_receiver.initializer();
    }
}
// src/lib.cairo
#[starknet::contract]
mod NftScavenger {
    use starknet::{ContractAddress, get_caller_address};
    use traits::ISRC12;
    use super::ISRC12DispatcherTrait;
    use array::ArrayTrait;
    use option::OptionTrait;

    #[storage]
    struct Storage {
        // Player progress: (player => [completed_puzzle_ids])
        progress: LegacyMap<ContractAddress, Array<u256>>,
        // NFT ownership: (nft_id => owner)
        owners: LegacyMap<u256, ContractAddress>,
        // Leaderboard: (player => score)
        leaderboard: LegacyMap<ContractAddress, u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PuzzleSolved: PuzzleSolved,
        NftMinted: NftMinted,
    }

    #[derive(Drop, starknet::Event)]
    struct PuzzleSolved {
        player: ContractAddress,
        puzzle_id: u256,
    }

    #[external(v0)]
    impl NftScavenger {
        /// Solve a puzzle and mint NFT reward
        #[payable]
        fn solve_puzzle(ref self: ContractState, puzzle_id: u256, solution: Array<u256>) {
            let player = get_caller_address();
            
            // Validate solution (example: hash matches)
            assert(is_valid_solution(puzzle_id, solution), 'Wrong answer!');

            // Update progress
            let mut completed = self.progress.read(player);
            completed.append(puzzle_id);
            self.progress.write(player, completed);

            // Mint NFT
            let nft_id = next_nft_id(self); // Implement auto-increment
            self.owners.write(nft_id, player);

            // Update leaderboard
            self.leaderboard.write(player, self.leaderboard.read(player) + 1);

            // Emit events
            self.emit(PuzzleSolved { player, puzzle_id });
            self.emit(NftMinted { player, nft_id });
        }

        /// Check if player solved a puzzle
        #[view]
        fn has_solved(self: @ContractState, player: ContractAddress, puzzle_id: u256) -> bool {
            let completed = self.progress.read(player);
            completed.contains(puzzle_id)
        }
    }

    /// Helper: Validate puzzle solution (mock)
    fn is_valid_solution(puzzle_id: u256, solution: Array<u256>) -> bool {
        // Replace with real logic (e.g., hash check)
        match puzzle_id {
            1 => solution[0] == 42, // Example: "Answer to the Universe"
            _ => false,
        }
    }
}
