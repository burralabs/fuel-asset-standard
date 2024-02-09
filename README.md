# The Fuel Asset Standard

This represents an implementation (with additions) to the [SRC20 Native Assets](https://github.com/FuelLabs/sway-standards/blob/master/standards/src20-native-asset) and [SRC3 Mint and Burn](https://github.com/FuelLabs/sway-standards/blob/master/standards/src3-mint-burn) standards on the Fuel Network.

This includes the methods as defined in the SRC20 and SRC3 specs with some convenience methods to query balances and transfer assets for the contract.


## Single & Multi Native Assets

The FuelVM introduces the concept of "native assets" which unlock some really interesting stuff, but can also be a bit of a transition compared to ERC20-style architectures. Essentially, a contract can have *more than one* native asset without you having to worry about state management.

Roughly, the id of any `Asset` on Fuel is a sha256 hash of the contract's id and a sub-identifier value. In Sway, you'd write it as:
```sway
let asset_id = AssetId::new(contract_id(), sub_id);

// internally, asset_id is (roughly) constructed as:
// sha256((contract_id(), sub_id))
```

- For users that intend to deploy a single asset within their contract, the value for `sub_id` is `DEFAULT_SUB_ID/0x0000000000000000000000000000000000000000000000000000000000000000` (can be any value, but the idea is the `sub_id` is fixed)

- For users that intend to deploy multiple native assets within their contract, the value for `sub_id` would change (like `0x00`, `0x01`, `0x02`, and so on)

as mentioned before, the `asset_id` that would be identifiable on the explorer would be the sha256 hash of the contract's id and the sub-identifier value.

Further reading (code): [single native assets](https://github.com/FuelLabs/sway-standards/blob/master/examples/src20-native-asset/single_asset/src/single_asset.sw) and [multiple native assets](https://github.com/FuelLabs/sway-standards/blob/master/examples/src20-native-asset/multi_asset/src/multi_asset.sw).


## Querying Balances & Transferring Assets
For the same reasons, being able to query balances and transfer assets on-chain requires some knowledge overhead using the fact that the `asset_id` is in fact a hash of a two values. 

### Querying Balances

Because externally-owned accounts (EOAs) follow the UTXO model on Fuel and contracts do not, there is currently *no way* of querying an EOA's holding of a particular asset on-chain (one can do this off-chain via the TypeScript/Rust SDK). Since contract accounts follow an Accounts-based model, querying its balance is easy:

```sway
// Querying the balance of ANY asset owned by a particular contract
let asset_id = AssetId::new(asset_factory_contract_id, sub_id);

// target_contract: particular balance you want to query the asset_id for
// asset_id: the, well, asset identifier
let balance = balance_of(target_contract, asset_id);
```

### Transferring assets

By the same token, you need to construct the `asset_id` first, and then be able to effectively transfer assets

```sway
let asset_id = AssetId::new(asset_factory_contract_id, sub_id);

transfer(to_identity, asset_id, 420_000);
```

## Resources
- [Sway Standards](https://github.com/fuelLabs/sway-standards/)
- [Minimal Native Assets Implementation](https://github.com/FuelLabs/sway-applications/blob/master/native-assets/native-asset)