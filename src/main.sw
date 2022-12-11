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
    }
};

/**
    The Token Standard for the Fuel Network
*/

abi FRC20 {
    /// Initialize
    #[storage(read, write)]
    fn initialize(config: FRC20Config, owner: Address);

    /// Get the token config
    #[storage(read)]
    fn config() -> FRC20Config;

    /// Get the owner address
    #[storage(read)]
    fn owner() -> Address;

    /// Get the total supply
    #[storage(read)]
    fn total_supply() -> u64;

    /// Get unspent token balance for an address
    #[storage(read)]
    fn balance_of(address: Address) -> u64;

}

const ZERO_ADDRESS = 0x0000000000000000000000000000000000000000000000000000000000000000;

pub struct FRC20Config {
    name: str[16],
    symbol: str[8],
    decimals: u8
}

enum Error {
    AlreadyInitialized: (),
    AddressIsZero: (),
    SenderNotOwner: (),
}

storage {
    config__: FRC20Config = FRC20Config {
        name: "                ",
        symbol: "        ",
        decimals: 1u8 // 8 decimals by default
    },
    owner__: Address = Address { value: ZERO_ADDRESS },
    balances__: StorageMap<Address, u64> = StorageMap{},
    total_supply__: u64 = 0u64
}


impl FRC20 for Contract {
    /// Initialize
    #[storage(read, write)]
    fn initialize(
        config: FRC20Config,
        owner: Address
    ) {
        require(storage.owner__.into() == ZERO_ADDRESS, Error::AlreadyInitialized);
        require(owner.into() != ZERO_ADDRESS, Error::AddressIsZero);

        storage.config__ = config;
        storage.owner__ = owner;
    }


    #[storage(read)]
    fn config() -> FRC20Config {
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
}
