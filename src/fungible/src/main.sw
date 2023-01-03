// SPDX-License-Identifier: Apache-2.0
contract;

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

/*
    The Token Standard for the Fuel Network
*/

abi FungibleCore {
    /// Initialize
    #[storage(read, write)]
    fn initialize(config: FungibleCoreConfig, owner: Address);

    /// Get the token config
    #[storage(read)]
    fn config() -> FungibleCoreConfig;

    /// Get the owner address
    #[storage(read)]
    fn owner() -> Address;

    /// Get the total supply
    #[storage(read)]
    fn total_supply() -> u64;

    /// Get unspent token balance for an address
    #[storage(read)]
    fn balance_of(address: Address) -> u64;

    /// Get the amount of the owner's tokens that a spender can spend
    #[storage(read)]
    fn allowance(owner: Address, spender: Address) -> u64;

    /// Approve an address to spend the caller's tokens
    #[storage(write)]
    fn approve(spender: Address, amount: u64) -> bool;

    /// Mint tokens
    #[storage(read, write)]
    fn mint(address: Address, amount: u64) -> bool;

    /// Burn tokens
    #[storage(read, write)]
    fn burn(address: Address,amount: u64) -> bool;

    /// Transfer tokens
    #[storage(read, write)]
    fn transfer(address: Address, amount: u64) -> bool;

    /// Transfer tokens from one address to another via an approved intermediary
    #[storage(read, write)]
    fn transfer_from(from: Address, to: Address, amount: u64) -> bool;
}


/*
    Utils
*/
const ZERO_ADDRESS = 0x0000000000000000000000000000000000000000000000000000000000000000;

pub fn get_sender() -> Address {
    match msg_sender().unwrap() {
        Identity::Address(addr) => addr,
        _ => revert(0),
    }
}

pub struct FungibleCoreConfig {
    name: str[16],
    symbol: str[8],
    decimals: u8
}

pub struct HashableAllowance {
    owner: Address,
    spender: Address
    
}

enum Error {
    AlreadyInitialized: (),
    AddressIsZero: (),
    SenderNotOwner: (),
    SenderNotAuthorized: (),
    InsufficientAllowance: ()
}


pub fn hash_allowance(owner: Address, spender: Address) -> b256 {
    keccak256(HashableAllowance { owner, spender })
}

storage {
    config__: FungibleCoreConfig = FungibleCoreConfig {
        name: "                ",
        symbol: "        ",
        decimals: 1u8 // 8 decimals by default
    },
    owner__: Address = Address::from(ZERO_ADDRESS),
    balances__: StorageMap<Address, u64> = StorageMap{},
    allowances__: StorageMap<b256, u64> = StorageMap{},
    total_supply__: u64 = 0u64
}


impl FungibleCore for Contract {
    /// Initialize
    #[storage(read, write)]
    fn initialize(config: FungibleCoreConfig, owner: Address) {
        require(storage.owner__.into() == ZERO_ADDRESS, Error::AlreadyInitialized);
        require(owner.into() != ZERO_ADDRESS, Error::AddressIsZero);

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
    fn balance_of(address: Address) -> u64 {
        storage.balances__.get(address)
    }

    #[storage(read)]
    fn allowance(owner: Address, spender: Address) -> u64 {
        let hash = hash_allowance(owner, spender);
        storage.allowances__.get(hash)
    }

    #[storage(write)]
    fn approve(spender: Address, amount: u64) -> bool {
        let owner = get_sender();
        require(owner.into() != ZERO_ADDRESS, Error::AddressIsZero);
        require(spender.into() != ZERO_ADDRESS, Error::AddressIsZero);

        let hash = hash_allowance(owner, spender);
        storage.allowances__.insert(hash, amount);

        true
    }

    #[storage(read, write)]
    fn mint(address: Address, amount: u64) -> bool {
        require(get_sender() == storage.owner__, Error::SenderNotOwner);
        require(address.into() != ZERO_ADDRESS, Error::AddressIsZero);

        storage.balances__.insert(address, storage.balances__.get(address) + amount);
        storage.total_supply__ += amount;

        true
    }

    #[storage(read, write)]
    fn burn(address: Address,amount: u64) -> bool {
        require(address.into() != ZERO_ADDRESS, Error::AddressIsZero);
        require(get_sender() == address, Error::SenderNotAuthorized);
        
        storage.balances__.insert(address, storage.balances__.get(address) - amount);

        true 
    }

    #[storage(read, write)]
    fn transfer(to: Address, amount: u64) -> bool {
        let sender = get_sender();
        require(to.into() != ZERO_ADDRESS, Error::AddressIsZero);

        storage.balances__.insert(sender, storage.balances__.get(sender) - amount);
        storage.balances__.insert(to, storage.balances__.get(to) + amount);

        true
    }

    #[storage(read, write)]
    fn transfer_from(from: Address, to: Address, amount: u64) -> bool {
        let spender = get_sender();
        require(from.into() != ZERO_ADDRESS, Error::AddressIsZero);

        // Ensure that the sender has enough allowance
        let hash = hash_allowance(from, spender);
        require(storage.allowances__.get(hash) >= amount, Error::InsufficientAllowance);

        storage.balances__.insert(from, storage.balances__.get(from) - amount);
        storage.balances__.insert(to, storage.balances__.get(to) + amount);
        storage.allowances__.insert(hash, storage.allowances__.get(hash) - amount);

        true
    }
}