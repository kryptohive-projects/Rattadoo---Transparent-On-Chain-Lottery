# RattaDoo Room Raffle Contract

## Overview

The RattaDoo Room Raffle Contract is a decentralized application (DApp) implemented on the Ethereum blockchain. It enables players to participate in raffle-style games where they can win a percentage of the total pool by joining rooms with an entry fee. The contract supports both default rooms with predefined settings and custom rooms with flexible configurations.

### Features

1. **Default Room**
   - Players join a default room with a fixed entry fee, player count, and prize percentage.
   - When the room reaches the required number of players, a winner is selected randomly, and the prize is distributed.
   - The remaining funds are split between the admin and the room creator.

2. **Custom Rooms**
   - Admins can create custom rooms with adjustable parameters such as entry fee, player count, and prize percentage.
   - Players can join these custom rooms, and winners are selected and rewarded similarly to default rooms.

3. **Player Interaction**
   - Players can join rooms by sending the exact entry fee in Ether.
   - They receive event notifications upon successfully joining a room and when a winner is selected.

4. **Withdrawal Mechanism**
   - Players can withdraw their winnings using a simple claim function, which transfers their pending balance to their Ethereum address.

5. **Security Measures**
   - The contract includes safeguards against reentrancy attacks to ensure fair gameplay and secure fund handling.
   - Direct payments to the contract are rejected to prevent accidental Ether transfers.

### Usage

To use the RattaDoo Room Raffle Contract:

1. **Deploy the Contract**
   - Deploy the contract on the Ethereum blockchain using tools like Remix, Hardhat, or Truffle.

2. **Interaction**
   - **Join Default Room:** Call the `play()` function with the exact entry fee to participate in the default room.
   - **Create Custom Room:** Use the `createRoom()` function (accessible to the admin) to define a new room configuration.
   - **Join Custom Room:** Players can join custom rooms by calling `playInCustomRoom(roomNumber)` with the correct entry fee.

3. **Winning and Withdrawal**
   - Winners are automatically selected when enough players join a room, and prizes are distributed.
   - Players can withdraw their winnings using the `claim()` function.

### Development Environment

- **Solidity Version:** 0.8.x
- **Development Framework:** Hardhat, Truffle, or Remix (for deployment and testing)
- **Testing:** Use tools like Hardhat's testing framework to write and execute unit tests for smart contracts.

### License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0). You are free to use, modify, and distribute this software, subject to the terms of the license.

### Disclaimer

- This contract is provided as-is without any warranties or guarantees of any kind.
- Use caution when interacting with smart contracts, as incorrect usage could result in loss of funds.

For detailed usage instructions, refer to the contract's functions and events defined in the source code.


```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts
```
