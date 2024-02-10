// SPDX-License-Identifier: Apache-2.0
library;

pub enum Error {
    AlreadyInitialized: (),
    NameAlreadySet: (),
    SymbolAlreadySet: (),
    DecimalsAlreadySet: (),
    BurnInsufficientBalance: (),
}
