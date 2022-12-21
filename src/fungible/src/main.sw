// SPDX-License-Identifier: Apache-2.0
contract;

use std::{
    auth::{
        AuthError,
        msg_sender
    },
    revert::require,
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

    /// Approve an address to spend the caller's tokens
    #[storage(write)]
    fn approve(spender: Address, amount: u64) -> bool;

    /// Mint tokens
    #[storage(read, write)]
    fn mint(address: Address, amount: u64) -> bool;

    #[storage(read, write)]
    fn burn(address: Address,amount: u64) -> bool;
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

enum Error {
    AlreadyInitialized: (),
    AddressIsZero: (),
    SenderNotOwner: (),
    SenderNotAuthorized: ()
}


storage {
    config__: FungibleCoreConfig = FungibleCoreConfig {
        name: "                ",
        symbol: "        ",
        decimals: 1u8 // 8 decimals by default
    },
    owner__: Address = Address::from(ZERO_ADDRESS),
    balances__: StorageMap<Address, u64> = StorageMap{},
    allowances__: StorageMap<Address, (Address, u64)> = StorageMap{},
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

    #[storage(write)]
    fn approve(spender: Address, amount: u64) -> bool {
        let sender = get_sender();
        require(sender.into() != ZERO_ADDRESS, Error::AddressIsZero);
        require(spender.into() != ZERO_ADDRESS, Error::AddressIsZero);

        storage.allowances__.insert(sender, (spender, amount));

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
}