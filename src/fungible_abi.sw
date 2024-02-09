// SPDX-License-Identifier: Apache-2.0
library;

use std::{
    auth::{
        AuthError,
        msg_sender,
    },
    hash::{
        keccak256,
        sha256,
    },
    revert::require,
    storage::storage_string::*,
    string::String,
};

pub const ZERO = 0x0000000000000000000000000000000000000000000000000000000000000000;
pub const ZERO_ADDRESS = Address::from(ZERO);

abi FungibleAsset {
    /*
           ____  ____  ____   ____ ____   ___  
          / / / / ___||  _ \ / ___|___ \ / _ \ 
         / / /  \___ \| |_) | |     __) | | | |
        / / /    ___) |  _ <| |___ / __/| |_| |
       /_/_/    |____/|_| \_\\____|_____|\___/                                         
       from: https://github.com/FuelLabs/sway-standards/tree/master/standards/src20-native-asset  
    */
    /// Returns the total number of individual assets for a contract.
    ///
    /// # Returns
    ///
    /// * [u64] - The number of assets that this contract has minted.
    ///
    /// # Examples
    ///
    /// ```sway
    /// use src20::SRC20;
    ///
    /// fn foo(contract: ContractId) {
    ///     let contract_abi = abi(SRC20, contract);
    ///     let total_assets = contract_abi.total_assets();
    ///     assert(total_assets != 0);
    /// }
    /// ```
    #[storage(read)]
    fn total_assets() -> u64;

    /// Returns the total supply of coins for an asset.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset of which to query the total supply.
    ///
    /// # Returns
    ///
    /// * [Option<u64>] - The total supply of coins for `asset`.
    ///
    /// # Examples
    ///
    /// ```sway
    /// use src20::SRC20;
    ///
    /// fn foo(contract: ContractId, asset: AssetId) {
    ///     let contract_abi = abi(SRC20, contract);
    ///     let total_supply = contract_abi.total_supply(asset);
    ///     assert(total_supply.unwrap() != 0);
    /// }
    /// ```
    #[storage(read)]
    fn total_supply(asset_id: AssetId) -> Option<u64>;

    /// Returns the name of the asset, such as “Ether”.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset of which to query the name.
    ///
    /// # Returns
    ///
    /// * [Option<String>] - The name of `asset`.
    ///
    /// # Examples
    ///
    /// ```sway
    /// use src20::SRC20;
    /// use std::string::String;
    ///
    /// fn foo(contract: ContractId, asset: AssetId) {
    ///     let contract_abi = abi(SRC20, contract);
    ///     let name = contract_abi.name(asset);
    ///     assert(name.is_some());
    /// }
    /// ```
    #[storage(read)]
    fn name(asset_id: AssetId) -> Option<String>;

    /// Returns the symbol of the asset, such as “ETH”.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset of which to query the symbol.
    ///
    /// # Returns
    ///
    /// * [Option<String>] - The symbol of `asset`.
    ///
    /// # Examples
    ///
    /// ```sway
    /// use src20::SRC20;
    /// use std::string::String;
    ///
    /// fn foo(contract: ContractId, asset: AssetId) {
    ///     let contract_abi = abi(SRC20, contract);
    ///     let symbol = contract_abi.symbol(asset);
    ///     assert(symbol.is_some());
    /// }
    /// ```
    #[storage(read)]
    fn symbol(asset_id: AssetId) -> Option<String>;
    
    /// Returns the number of decimals the asset uses.
    ///
    /// # Additional Information
    ///
    /// e.g. 8, means to divide the coin amount by 100000000 to get its user representation.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset of which to query the decimals.
    ///
    /// # Returns
    ///
    /// * [Option<u8>] - The decimal precision used by `asset`.
    ///
    /// # Examples
    ///
    /// ```sway
    /// use src20::SRC20;
    ///
    /// fn foo(contract: ContractId, asset: AssedId) {
    ///     let contract_abi = abi(SRC20, contract);
    ///     let decimals = contract_abi.decimals(asset);
    ///     assert(decimals.unwrap() == 8u8);
    /// }
    /// ```
    #[storage(read)]
    fn decimals(asset_id: AssetId) -> Option<u8>;

    /*
           ____  ____  ____   ____ _____ 
          / / / / ___||  _ \ / ___|___ / 
         / / /  \___ \| |_) | |     |_ \ 
        / / /    ___) |  _ <| |___ ___) |
       /_/_/    |____/|_| \_\\____|____/   
       from: https://github.com/FuelLabs/sway-standards/blob/master/standards/src3-mint-burn 
    */
    /// Mints new assets using the `vault_sub_id` sub-identifier.
    ///
    /// # Arguments
    ///
    /// * `recipient`: [Identity] - The user to which the newly minted asset is transferred to.
    /// * `vault_sub_id`: [SubId] - The sub-identifier of the newly minted asset.
    /// * `amount`: [u64] - The quantity of coins to mint.
    ///
    /// # Examples
    ///
    /// ```sway
    /// use src3::SRC3;
    ///
    /// fn foo(contract_id: ContractId) {
    ///     let contract_abi = abi(SR3, contract);
    ///     contract_abi.mint(Identity::ContractId(contract_id), ZERO_B256, 100);
    /// }
    /// ```
    #[storage(read, write)]
    fn mint(recipient: Identity, vault_sub_id: SubId, amount: u64);

    /// Burns assets sent with the given `vault_sub_id`.
    ///
    /// # Additional Information
    ///
    /// NOTE: The sha-256 hash of `(ContractId, SubId)` must match the `AssetId` where `ContractId` is the id of
    /// the implementing contract and `SubId` is the given `vault_sub_id` argument.
    ///
    /// # Arguments
    ///
    /// * `vault_sub_id`: [SubId] - The sub-identifier of the asset to burn.
    /// * `amount`: [u64] - The quantity of coins to burn.
    ///
    /// # Examples
    ///
    /// ```sway
    /// use src3::SRC3;
    ///
    /// fn foo(contract_id: ContractId, asset_id: AssetId) {
    ///     let contract_abi = abi(SR3, contract_id);
    ///     contract_abi {
    ///         gas: 10000,
    ///         coins: 100,
    ///         asset_id: asset_id,
    ///     }.burn(ZERO_B256, 100);
    /// }
    /// ```
    #[storage(read, write)]
    fn burn(vault_sub_id: SubId, amount: u64);

    /*
           ____  ____       _   _                
          / / / / ___|  ___| |_| |_ ___ _ __ ___ 
         / / /  \___ \ / _ \ __| __/ _ \ '__/ __|
        / / /    ___) |  __/ |_| ||  __/ |  \__ \
       /_/_/    |____/ \___|\__|\__\___|_|  |___/
    */
    /// Sets the name of an asset.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset of which to set the name.
    /// * `name`: [String] - The name of the asset.
    ///
    /// # Reverts
    ///
    /// * When the name has already been set for an asset.
    ///
    /// # Number of Storage Accesses
    ///
    /// * Reads: `1`
    /// * Writes: `2`
    ///
    /// # Examples
    ///
    /// ```sway
    /// use asset::SetAssetAttributes;
    /// use src20::SRC20;
    /// use std::string::String;
    ///
    /// fn foo(asset_id: AssetId) {
    ///     let set_abi = abi(SetAssetAttributes, contract_id);
    ///     let src_20_abi = abi(SRC20, contract_id);
    ///     let name = String::from_ascii_str("Ether");
    ///     set_abi.set_name(storage.name, asset, name);
    ///     assert(src_20_abi.name(asset) == name);
    /// }
    /// ```
    #[storage(write)]
    fn set_name(asset_id: AssetId, name: String);

    /// Sets the symbol of an asset.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset of which to set the symbol.
    /// * `symbol`: [String] - The symbol of the asset.
    ///
    /// # Reverts
    ///
    /// * When the symbol has already been set for an asset.
    ///
    /// # Number of Storage Accesses
    ///
    /// * Reads: `1`
    /// * Writes: `2`
    ///
    /// # Examples
    ///
    /// ```sway
    /// use asset::SetAssetAttributes;
    /// use src20::SRC20;
    /// use std::string::String;
    ///
    /// fn foo(asset_id: AssetId) {
    ///     let set_abi = abi(SetAssetAttributes, contract_id);
    ///     let src_20_abi = abi(SRC20, contract_id);
    ///     let symbol = String::from_ascii_str("ETH");
    ///     set_abi.set_symbol(storage.name, asset, symbol);
    ///     assert(src_20_abi.symbol(asset) == symbol);
    /// }
    /// ```
    #[storage(write)]
    fn set_symbol(asset_id: AssetId, symbol: String);

    /// Sets the decimals of an asset.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset of which to set the decimals.
    /// * `decimal`: [u8] - The decimals of the asset.
    ///
    /// # Reverts
    ///
    /// * When the decimals has already been set for an asset.
    ///
    /// # Number of Storage Accesses
    ///
    /// * Reads: `1`
    /// * Writes: `1`
    ///
    /// # Examples
    ///
    /// ```sway
    /// use asset::SetAssetAttributes;
    /// use src20::SRC20;
    ///
    /// fn foo(asset_id: AssetId) {
    ///     let decimals = 8u8;
    ///     let set_abi = abi(SetAssetAttributes, contract_id);
    ///     let src_20_abi = abi(SRC20, contract_id);
    ///     set_abi.set_decimals(asset_id, decimals);
    ///     assert(src_20_abi.decimals(asset_id) == decimals);
    /// }
    /// ```
    #[storage(write)]
    fn set_decimals(asset_id: AssetId, decimals: u8);

    /*
           ____  __  __ _          
          / / / |  \/  (_)___  ___ 
         / / /  | |\/| | / __|/ __|
        / / /   | |  | | \__ \ (__ 
       /_/_/    |_|  |_|_|___/\___|
    */
    /// Get the balance of sub-identifier `sub_id` for the current contract.
    ///
    /// # Arguments
    ///
    /// * `sub_id`: [SubId] - The sub-identifier of the balance to be queried
    ///
    /// # Returns
    ///
    /// * [u64] - The amount of the asset which the contract holds.
    ///
    /// # Examples
    ///
    /// ```sway
    /// use std::{context::this_balance, constants::ZERO_B256, hash::sha256, asset::mint, call_frames::contract_id};
    ///
    /// fn foo() {
    ///     mint(ZERO_B256, 50);
    ///     assert(this_balance(sha256((ZERO_B256, contract_id()))) == 50);
    /// }
    /// ```
    fn this_balance(sub_id: SubId) -> u64;

    /// Get the balance of sub-identifier `sub_id` for the contract at 'target'.
    ///
    /// # Arguments
    ///
    /// * `target`: [ContractId] - The contract that contains the `asset_id`.
    /// * `asset_id`: [AssetId] - The asset of which the balance should be returned.
    ///
    /// # Returns
    ///
    /// * [u64] - The amount of the asset which the `target` holds.
    ///
    /// # Examples
    ///
    /// ```sway
    /// use std::{context::balance_of, constants::ZERO_B256, hash::sha256, asset::mint, call_frames::contract_id};
    ///
    /// fn foo() {
    ///     mint(ZERO_B256, 50);
    ///     assert(balance_of(contract_id(), sha256((ZERO_B256, contract_id()))) == 50);
    /// }
    /// ```
    fn get_balance(target: ContractId, sub_id: SubId) -> u64;
}
