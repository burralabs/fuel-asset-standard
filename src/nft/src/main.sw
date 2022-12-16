contract;

abi NFTCore {
    fn hello() -> bool;
}

impl NFTCore for Contract {
    fn hello() -> bool {
        true
    }
}