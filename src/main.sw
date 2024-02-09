// SPDX-License-Identifier: Apache-2.0
contract;

mod errors;
mod fungible_abi;

use std::{
    asset::*,
    auth::{
        AuthError,
        msg_sender,
    },
    call_frames::contract_id,
    context::{this_balance, balance_of},
    hash::{
        Hash,
        sha256,
    },
    revert::require,
    storage::storage_string::*,
    string::String,
};
use src20::SRC20;
use src3::SRC3;
use fungible_abi::*;
use errors::*;

storage {
    /// The name associated with a particular asset.
    name: StorageMap<AssetId, StorageString> = StorageMap {},
    /// The symbol associated with a particular asset.
    symbol: StorageMap<AssetId, StorageString> = StorageMap {},
    /// The decimals associated with a particular asset.
    decimals: StorageMap<AssetId, u8> = StorageMap {},
    /// The total number of coins minted for a particular asset.
    total_supply: StorageMap<AssetId, u64> = StorageMap {},
    /// The total number of unique assets minted by this contract.
    total_assets: u64 = 0,
}

impl FungibleAsset for Contract {
    /*
           ____  ____  ____   ____ ____   ___  
          / / / / ___||  _ \ / ___|___ \ / _ \ 
         / / /  \___ \| |_) | |     __) | | | |
        / / /    ___) |  _ <| |___ / __/| |_| |
       /_/_/    |____/|_| \_\\____|_____|\___/                                         
    */
    #[storage(read)]
    fn total_assets() -> u64 {
        storage.total_assets.try_read().unwrap_or(0)
    }

    #[storage(read)]
    fn total_supply(asset_id: AssetId) -> Option<u64> {
        storage.total_supply.get(asset_id).try_read()
    }

    #[storage(read)]
    fn name(asset_id: AssetId) -> Option<String> {
        storage.name.get(asset_id).read_slice()
    }

    #[storage(read)]
    fn symbol(asset_id: AssetId) -> Option<String> {
        storage.symbol.get(asset_id).read_slice()
    }

    #[storage(read)]
    fn decimals(asset_id: AssetId) -> Option<u8> {
        storage.decimals.get(asset_id).try_read()
    }

    /*
           ____  ____  ____   ____ _____ 
          / / / / ___||  _ \ / ___|___ / 
         / / /  \___ \| |_) | |     |_ \ 
        / / /    ___) |  _ <| |___ ___) |
       /_/_/    |____/|_| \_\\____|____/   
    */
    #[storage(read, write)]
    fn mint(recipient: Identity, sub_id: SubId, amount: u64) {
        let asset_id = AssetId::new(contract_id(), sub_id);

        let supply = storage.total_supply.get(asset_id);

        // Only increment the number of assets minted by this contract if it hasn't been minted before.
        if supply.try_read().is_none() {
            storage.total_assets.write(storage.total_assets.read() + 1);
        }

        storage
            .total_supply
            .insert(asset_id, supply.try_read().unwrap_or(0) + amount);

        // The `asset_id` constructed within the `mint_to` method is a sha256 hash of
        // the `contract_id` and the `sub_id` (the same as the `asset_id` constructed here).
        mint_to(recipient, sub_id, amount);
    }

    #[storage(read, write)]
    fn burn(sub_id: SubId, amount: u64) {
        let asset_id = AssetId::new(contract_id(), sub_id);

        require(
            this_balance(asset_id) >= amount,
            Error::BurnInsufficientBalance,
        );

        // If we pass the check above, we can assume it is safe to unwrap.
        storage
            .total_supply
            .insert(asset_id, storage.total_supply.get(asset_id).read() - amount);

        burn(sub_id, amount);
    }

    /*
           ____  ____       _   _                
          / / / / ___|  ___| |_| |_ ___ _ __ ___ 
         / / /  \___ \ / _ \ __| __/ _ \ '__/ __|
        / / /    ___) |  __/ |_| ||  __/ |  \__ \
       /_/_/    |____/ \___|\__|\__\___|_|  |___/
    */
    #[storage(write)]
    fn set_name(asset_id: AssetId, name: String) {
        require(
            storage
                .name
                .get(asset_id)
                .read_slice()
                .is_none(),
            Error::NameAlreadySet,
        );
        storage.name.insert(asset_id, StorageString {});
        storage.name.get(asset_id).write_slice(name);
    }

    #[storage(write)]
    fn set_symbol(asset_id: AssetId, symbol: String) {
        require(
            storage
                .symbol
                .get(asset_id)
                .read_slice()
                .is_none(),
            Error::SymbolAlreadySet,
        );
        storage.symbol.insert(asset_id, StorageString {});
        storage.symbol.get(asset_id).write_slice(symbol);
    }

    #[storage(write)]
    fn set_decimals(asset_id: AssetId, decimals: u8) {
        require(
            storage
                .decimals
                .get(asset_id)
                .try_read()
                .is_none(),
            Error::DecimalsAlreadySet,
        );
        storage.decimals.insert(asset_id, decimals);
    }

    /*
           ____  ____        _                      
          / / / | __ )  __ _| | __ _ _ __   ___ ___ 
         / / /  |  _ \ / _` | |/ _` | '_ \ / __/ _ \
        / / /   | |_) | (_| | | (_| | | | | (_|  __/
       /_/_/    |____/ \__,_|_|\__,_|_| |_|\___\___|
    */
    fn this_balance(sub_id: SubId) -> u64 {
        let asset_id = AssetId::new(contract_id(), sub_id);
        balance_of(contract_id(), asset_id)
    }

    fn get_balance(target: ContractId, sub_id: SubId) -> u64 {
        let asset_id = AssetId::new(contract_id(), sub_id);
        balance_of(target, asset_id)
    }

    /*
           ____  _____                     __           
          / / / |_   _| __ __ _ _ __  ___ / _| ___ _ __ 
         / / /    | || '__/ _` | '_ \/ __| |_ / _ \ '__|
        / / /     | || | | (_| | | | \__ \  _|  __/ |   
       /_/_/      |_||_|  \__,_|_| |_|___/_|  \___|_|
    */
    fn transfer(to: Identity, sub_id: SubId, amount: u64) {
        let asset_id = AssetId::new(contract_id(), sub_id);

        transfer(to, asset_id, amount);
    }

    fn transfer_to_address(to: Address, sub_id: SubId, amount: u64) {
        let asset_id = AssetId::new(contract_id(), sub_id);

        transfer_to_address(to, asset_id, amount);
    }

    fn transfer_to_contract(to: ContractId, sub_id: SubId, amount: u64) {
        let asset_id = AssetId::new(contract_id(), sub_id);

        force_transfer_to_contract(to, asset_id, amount);
    }
}
