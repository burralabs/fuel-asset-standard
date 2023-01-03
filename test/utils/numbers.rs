pub mod numbers {
    pub fn to_decimals(num: u64, decimals: u8) -> u64 {
        num * 10u64.pow(decimals as u32)
    }

    pub fn from_decimals(num: u64, decimals: u8) -> u64 {
        num / 10u64.pow(decimals as u32)
    }
}