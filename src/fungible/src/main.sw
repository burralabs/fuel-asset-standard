// SPDX-License-Identifier: Apache-2.0
contract;

dep fungible_abi;

use std::{
    auth::{
        AuthError,
        msg_sender
    },
    revert::require,
    hash::{keccak256, sha256},
    storage::{
        StorageMap
    },
};
use fungible_abi::*;


storage {
    config__: FungibleCoreConfig = FungibleCoreConfig {
        name: "                ",
        symbol: "        ",
        decimals: 1u8 // 8 decimals by default
    },
    owner__: Address = ZERO_ADDRESS,
    balances__: StorageMap<Identity, u64> = StorageMap{},
    allowances__: StorageMap<b256, u64> = StorageMap{},
    total_supply__: u64 = 0u64
}


impl FungibleCore for Contract {
    /// Initialize
    #[storage(read, write)]
    fn initialize(config: FungibleCoreConfig, owner: Address) {
        require(storage.owner__.into() == ZERO, Error::AlreadyInitialized);
        require(owner.into() != ZERO, Error::AddressIsZero);

        storage.config__ = config;
        storage.owner__ = owner;
    }


    #[storage(read)]
    fn config() -> FungibleCoreConfig {
        storage.config__
    }


    #[storage(read)]
    fn owner() -> Address {
        storage.owner__
    }


    #[storage(read)]
    fn total_supply() -> u64 {
        storage.total_supply__
    }


    #[storage(read)]
    fn balance_of(address: Identity) -> u64 {
        storage.balances__.get(address)
    }


    #[storage(read)]
    fn allowance(owner: Identity, spender: Identity) -> u64 {
        let hash = hash_allowance(owner, spender);
        storage.allowances__.get(hash)
    }


    #[storage(write)]
    fn approve(spender: Identity, amount: u64) -> bool {
        let owner = Identity::Address(get_sender());
        require(check_nonzero(owner), Error::AddressIsZero);
        require(check_nonzero(spender), Error::AddressIsZero);

        let hash = hash_allowance(owner, spender);
        storage.allowances__.insert(hash, amount);

        true
    }


    #[storage(read, write)]
    fn _mint(address: Identity, amount: u64) -> bool {
        require(get_sender() == storage.owner__, Error::SenderNotOwner);
        require(check_nonzero(address), Error::AddressIsZero);

        storage.balances__.insert(address, storage.balances__.get(address) + amount);
        storage.total_supply__ += amount;

        true
    }


    #[storage(read, write)]
    fn _burn(address: Identity,amount: u64) -> bool {
        require(check_nonzero(address), Error::AddressIsZero);
        match address {
            Identity::Address(addr) => { require(addr == get_sender(), Error::AddressIsZero); },
            _ => revert(0),
        }
        
        storage.balances__.insert(address, storage.balances__.get(address) - amount);

        true 
    }


    #[storage(read, write)]
    fn transfer(to: Identity, amount: u64) -> bool {
        let sender = Identity::Address(get_sender());
        require(check_nonzero(to), Error::AddressIsZero);

        storage.balances__.insert(sender, storage.balances__.get(sender) - amount);
        storage.balances__.insert(to, storage.balances__.get(to) + amount);

        true
    }


    #[storage(read, write)]
    fn transfer_from(from: Identity, to: Identity, amount: u64) -> bool {
        let spender = Identity::Address(get_sender());
        require(check_nonzero(from), Error::AddressIsZero);

        // Ensure that the sender has enough allowance
        let hash = hash_allowance(from, spender);
        require(storage.allowances__.get(hash) >= amount, Error::InsufficientAllowance);

        storage.balances__.insert(from, storage.balances__.get(from) - amount);
        storage.balances__.insert(to, storage.balances__.get(to) + amount);
        storage.allowances__.insert(hash, storage.allowances__.get(hash) - amount);

        true
    }
}