// SPDX-License-Identifier: Apache-2.0
library fungible_abi;

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

pub const ZERO = 0x0000000000000000000000000000000000000000000000000000000000000000;
pub const ZERO_ADDRESS = Address::from(ZERO);


pub fn get_sender() -> Address {
    match msg_sender().unwrap() {
        Identity::Address(addr) => addr,
        _ => revert(0),
    }
}

pub fn check_nonzero(identity: Identity) -> bool {
    match identity {
        Identity::Address(addr) => addr.value != ZERO,
        Identity::ContractId(addr) => addr.value != ZERO,
    }
}

pub struct FungibleCoreConfig {
    name: str[16],
    symbol: str[8],
    decimals: u8
}

pub struct HashableAllowance {
    owner: Identity,
    spender: Identity
    
}

pub enum Error {
    AlreadyInitialized: (),
    AddressIsZero: (),
    SenderNotOwner: (),
    SenderNotAuthorized: (),
    InsufficientAllowance: ()
}


pub fn hash_allowance(owner: Identity, spender: Identity) -> b256 {
    keccak256(HashableAllowance { owner, spender })
}


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
    fn balance_of(address: Identity) -> u64;

    /// Get the amount of the owner's tokens that a spender can spend
    #[storage(read)]
    fn allowance(owner: Identity, spender: Identity) -> u64;

    /// Approve an address to spend the caller's tokens
    #[storage(write)]
    fn approve(spender: Identity, amount: u64) -> bool;

    /// Mint tokens
    #[storage(read, write)]
    fn mint(address: Identity, amount: u64) -> bool;

    /// Burn tokens
    #[storage(read, write)]
    fn burn(address: Identity,amount: u64) -> bool;

    /// Transfer tokens
    #[storage(read, write)]
    fn transfer(address: Identity, amount: u64) -> bool;

    /// Transfer tokens from one address to another via an approved intermediary
    #[storage(read, write)]
    fn transfer_from(from: Identity, to: Identity, amount: u64) -> bool;
}