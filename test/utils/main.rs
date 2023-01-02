use fuels::{
    prelude::*,
    programs::call_response::FuelCallResponse,
    tx::{Address, AssetId, ContractId}
};

// Load abi from json
abigen!(
    Contract(name = "TestFungible", abi = "src/fungible/out/debug/fungible-abi.json")
);

pub struct Wallets {
    pub wallet_owner: WalletUnlocked,
    pub wallet1: WalletUnlocked,
    pub wallet2: WalletUnlocked,
}

pub mod Calls {
    use super::*;

    pub async fn initialize(
        contract: &TestFungible,
        name: &str,
        symbol: &str,
        decimals: u8,
        amount: u64,
        deployer: Address
    ) -> Result<FuelCallResponse<()>> {
        let mut name = name.to_string();
        let mut symbol = symbol.to_string();
        name.push_str(" ".repeat(16 - name.len()).as_str());
        symbol.push_str(" ".repeat(8 - symbol.len()).as_str());

        contract
            .methods()
            .initialize(
                FungibleCoreConfig {
                    name: fuels::types::SizedAsciiString::<16>::new(name).unwrap(),
                    symbol: fuels::types::SizedAsciiString::<8>::new(symbol).unwrap(),
                    decimals
                },
                deployer
            )
            .call()
            .await
    }

    pub async fn get_config(contract: &TestFungible) -> Result<FuelCallResponse<FungibleCoreConfig>> {
        contract.methods().config().call().await
    }

    pub async fn get_owner(contract: &TestFungible) -> Result<FuelCallResponse<Address>> {
        contract.methods().owner().call().await
    }

    pub async fn get_total_supply(contract: &TestFungible) -> Result<FuelCallResponse<u64>> {
        contract.methods().total_supply().call().await
    }

    pub async fn get_balance(contract: &TestFungible, address: Address) -> Result<FuelCallResponse<u64>> {
        contract.methods().balance_of(address).call().await
    }

    pub async fn get_allowance(contract: &TestFungible, owner: Address, spender: Address) -> Result<FuelCallResponse<u64>> {
        contract.methods().allowance(owner, spender).call().await
    }

    pub async fn approve(contract: &TestFungible, spender: Address, amount: u64) -> Result<FuelCallResponse<bool>> {
        contract.methods().approve(spender, amount).call().await
    }

    pub async fn mint(contract: &TestFungible, spender: Address, amount: u64) -> Result<FuelCallResponse<bool>> {
        contract.methods().mint(spender, amount).call().await
    }

    pub async fn burn(contract: &TestFungible, spender: Address, amount: u64) -> Result<FuelCallResponse<bool>> {
        contract.methods().burn(spender, amount).call().await
    }

    pub async fn transfer(contract: &TestFungible, spender: Address, amount: u64) -> Result<FuelCallResponse<bool>> {
        contract.methods().transfer(spender, amount).call().await
    }

    pub async fn transfer_from(contract: &TestFungible, from: Address, to: Address, amount: u64) -> Result<FuelCallResponse<bool>> {
        contract.methods().transfer_from(from, to, amount).call().await
    }
}


pub mod Setup {
    use super::*;

    pub async fn setup_wallets() -> Wallets {
        let initial_amount = 1000000000;
        let num_wallets = 3;
        let num_coins = 1;

        let config = WalletsConfig::new(Some(num_wallets), Some(num_coins), Some(initial_amount));
        let wallets = launch_custom_provider_and_get_wallets(config, None, None).await;
        let wallet_owner = wallets.get(0).unwrap().clone();
        let wallet1 = wallets.get(1).unwrap().clone();
        let wallet2 = wallets.get(2).unwrap().clone();

        return Wallets {
            wallet_owner,
            wallet1,
            wallet2,
        };
    }

    pub async fn setup_fungible(wallet_owner: &WalletUnlocked) -> TestFungible {
        let fungible_id = Contract::deploy(
            "src/fungible/out/debug/fungible.bin",
            wallet_owner,
            TxParameters::default(),
            StorageConfiguration::with_storage_path(Some(
                "src/fungible/out/debug/fungible-storage_slots.json".to_string(),
            )),
        )
        .await
        .unwrap();

        return get_token_instance(&fungible_id, wallet_owner);
    }

    pub async fn setup() -> (TestFungible, Wallets) {
        let wallets = setup_wallets().await;
        let token = setup_fungible(&wallets.wallet_owner).await;
        return (token, wallets);
    }

    pub fn get_token_instance(
        fungible_id: &Bech32ContractId,
        wallet: &WalletUnlocked,
    ) -> TestFungible {
        return TestFungible::new(fungible_id.clone(), wallet.clone());
    }
}