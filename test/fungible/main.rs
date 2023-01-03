
use fuels::prelude::*;
use crate::utils::{main::*, numbers::*};


#[tokio::test]
async fn main() {
    // Setup contracts
    let (deployed, wallets) = setup::setup().await;

    let name = "Test Token";
    let symbol = "TT";
    let decimals = 8u8;
    let mint_amount = numbers::to_decimals(1000, decimals);
    let transfer_amount = numbers::to_decimals(100, decimals);

    // Initialize contract
    calls::initialize(
        &deployed,
        name,
        symbol,
        decimals,
        Address::from(wallets.owner.address().clone())
    ).await.unwrap();
    println!("✅ Initialized contract");

    let result = calls::get_config(&deployed).await.unwrap();
    assert_eq!(result.value.name, "Test Token      ");
    assert_eq!(result.value.symbol, "TT      ");
    assert_eq!(result.value.decimals, decimals);

    let owner_result = calls::get_owner(&deployed).await.unwrap();
    assert_eq!(owner_result.value, Address::from(wallets.owner.address().clone()));


    ///
    /// Mint tokens
    ///
    calls::mint(
        &deployed,
        Address::from(wallets.owner.address().clone()),
        mint_amount
    ).await.unwrap();
    println!("✅ Tokens minted");

    let balance_result = calls::get_balance(
        &deployed, 
        Address::from(wallets.owner.address().clone())
    ).await.unwrap();
    assert_eq!(balance_result.value, mint_amount);


    ///
    /// Transfer tokens
    ///
    let balance_before = calls::get_balance(
        &deployed, 
        Address::from(wallets.wallet1.address().clone())
    ).await.unwrap();
    assert_eq!(balance_before.value, 0);

    calls::transfer(
        &deployed,
        Address::from(wallets.wallet1.address().clone()),
        transfer_amount
    ).await.unwrap();
    println!("✅ Tokens transferred");

    let balance_after = calls::get_balance(
        &deployed, 
        Address::from(wallets.wallet1.address().clone())
    ).await.unwrap();
    assert_eq!(balance_after.value, transfer_amount);
}