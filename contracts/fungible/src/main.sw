// SPDX-License-Identifier: Apache-2.0
contract;

mod errors;

use std::{
    asset::*,
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


/*
    From: https://github.com/FuelLabs/sway-applications/blob/master/native-assets/native-asset/
*/
#[test]
fn test_mint() {
    use std::constants::ZERO_B256;
    let fungible_abi = abi(FungibleAsset, CONTRACT_ID);
    let recipient = Identity::ContractId(ContractId::from(CONTRACT_ID));
    let sub_id = ZERO_B256;
    let asset_id = AssetId::new(ContractId::from(CONTRACT_ID), sub_id);

    assert(balance_of(ContractId::from(CONTRACT_ID), asset_id) == 0);
    fungible_abi.mint(recipient, sub_id, 100);
    assert(balance_of(ContractId::from(CONTRACT_ID), asset_id) == 100);
}

#[test]
fn test_burn() {
    use std::constants::ZERO_B256;
    let fungible_abi = abi(FungibleAsset, CONTRACT_ID);
    let recipient = Identity::ContractId(ContractId::from(CONTRACT_ID));
    let sub_id = ZERO_B256;
    let asset_id = AssetId::new(ContractId::from(CONTRACT_ID), sub_id);
    fungible_abi.mint(recipient, sub_id, 100);
    assert(balance_of(ContractId::from(CONTRACT_ID), asset_id) == 100);
    fungible_abi.burn(sub_id, 100);
    assert(balance_of(ContractId::from(CONTRACT_ID), asset_id) == 0);
}

#[test]
fn test_total_assets() {
    let fungible_abi = abi(FungibleAsset, CONTRACT_ID);
    let recipient = Identity::ContractId(ContractId::from(CONTRACT_ID));
    let sub_id1 = 0x0000000000000000000000000000000000000000000000000000000000000001;
    let sub_id2 = 0x0000000000000000000000000000000000000000000000000000000000000002;

    assert(fungible_abi.total_assets() == 0);
    fungible_abi.mint(recipient, sub_id1, 100);
    assert(fungible_abi.total_assets() == 1);
    fungible_abi.mint(recipient, sub_id2, 100);
    assert(fungible_abi.total_assets() == 2);
}

#[test]
fn test_total_supply() {
    use std::constants::ZERO_B256;
    let fungible_abi = abi(FungibleAsset, CONTRACT_ID);
    let recipient = Identity::ContractId(ContractId::from(CONTRACT_ID));
    let sub_id = ZERO_B256;
    let asset_id = AssetId::new(ContractId::from(CONTRACT_ID), sub_id);

    assert(fungible_abi.total_supply(asset_id).is_none());
    fungible_abi.mint(recipient, sub_id, 100);
    assert(fungible_abi.total_supply(asset_id).unwrap() == 100);
}

#[test]
fn test_name() {
    use std::constants::ZERO_B256;
    let fungible_abi = abi(FungibleAsset, CONTRACT_ID);
    let sub_id = ZERO_B256;
    let asset_id = AssetId::new(ContractId::from(CONTRACT_ID), sub_id);
    let name = String::from_ascii_str("Burra Labs Asset");

    assert(fungible_abi.name(asset_id).is_none());
    fungible_abi.set_name(asset_id, name);
    assert(fungible_abi.name(asset_id).unwrap().as_bytes() == name.as_bytes());
}

#[test(should_revert)]
fn test_revert_set_name_twice() {
    use std::constants::ZERO_B256;
    let fungible_abi = abi(FungibleAsset, CONTRACT_ID);
    let sub_id = ZERO_B256;
    let asset_id = AssetId::new(ContractId::from(CONTRACT_ID), sub_id);
    let name = String::from_ascii_str("Burra Labs Asset");

    fungible_abi.set_name(asset_id, name);
    fungible_abi.set_name(asset_id, name);
}

#[test]
fn test_symbol() {
    use std::constants::ZERO_B256;
    let fungible_abi = abi(FungibleAsset, CONTRACT_ID);
    let sub_id = ZERO_B256;
    let asset_id = AssetId::new(ContractId::from(CONTRACT_ID), sub_id);
    let symbol = String::from_ascii_str("BURRA");

    assert(fungible_abi.symbol(asset_id).is_none());
    fungible_abi.set_symbol(asset_id, symbol);
    assert(fungible_abi.symbol(asset_id).unwrap().as_bytes() == symbol.as_bytes());
}

#[test(should_revert)]
fn test_revert_set_symbol_twice() {
    use std::constants::ZERO_B256;
    let fungible_abi = abi(FungibleAsset, CONTRACT_ID);
    let sub_id = ZERO_B256;
    let asset_id = AssetId::new(ContractId::from(CONTRACT_ID), sub_id);
    let symbol = String::from_ascii_str("BURRA");

    fungible_abi.set_symbol(asset_id, symbol);
    fungible_abi.set_symbol(asset_id, symbol);
}

#[test]
fn test_decimals() {
    use std::constants::ZERO_B256;
    let fungible_abi = abi(FungibleAsset, CONTRACT_ID);
    let sub_id = ZERO_B256;
    let asset_id = AssetId::new(ContractId::from(CONTRACT_ID), sub_id);
    let decimals = 8u8;

    assert(fungible_abi.decimals(asset_id).is_none());
    fungible_abi.set_decimals(asset_id, decimals);
    assert(fungible_abi.decimals(asset_id).unwrap() == decimals);
}

#[test(should_revert)]
fn test_revert_set_decimals_twice() {
    use std::constants::ZERO_B256;
    let fungible_abi = abi(FungibleAsset, CONTRACT_ID);
    let sub_id = ZERO_B256;
    let asset_id = AssetId::new(ContractId::from(CONTRACT_ID), sub_id);
    let decimals = 8u8;

    fungible_abi.set_decimals(asset_id, decimals);
    fungible_abi.set_decimals(asset_id, decimals);
}