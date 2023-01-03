use fuels::prelude::*;
use crate::utils::{main::*, numbers::*};


#[tokio::test]
async fn main() {
    // Setup contracts
    let (deployed, wallets) = setup::setup().await;

    let owner = Address::from(wallets.owner.address().clone());
    let wallet1 = Address::from(wallets.wallet1.address().clone());
    let wallet2 = Address::from(wallets.wallet2.address().clone());

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
        owner
    ).await.unwrap();
    println!("✅ Initialized contract");

    let result = calls::get_config(&deployed).await.unwrap();
    assert_eq!(result.value.name, "Test Token      ");
    assert_eq!(result.value.symbol, "TT      ");
    assert_eq!(result.value.decimals, decimals);

    let owner_result = calls::get_owner(&deployed).await.unwrap();
    assert_eq!(owner_result.value, owner);


    ///
    /// Mint tokens
    ///
    calls::mint(
        &deployed,
        owner,
        mint_amount
    ).await.unwrap();
    println!("✅ Tokens minted");

    let balance_result = calls::get_balance(&deployed, owner).await.unwrap();
    assert_eq!(balance_result.value, mint_amount);


    ///
    /// Transfer tokens
    ///
    let balance_before = calls::get_balance(&deployed, wallet1).await.unwrap();
    assert_eq!(balance_before.value, 0);

    calls::transfer(
        &deployed,
        wallet1,
        transfer_amount
    ).await.unwrap();
    println!("✅ Tokens transferred");

    let balance_after = calls::get_balance(&deployed, wallet1).await.unwrap();
    assert_eq!(balance_after.value, transfer_amount);
}