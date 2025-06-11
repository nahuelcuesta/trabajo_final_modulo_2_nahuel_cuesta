# 🧾 Decentralized Auction Smart Contract

This smart contract implements a decentralized auction system with the following features:


- Minimum 5% bid increment requirement 
- Auction deadline extension for last-minute bids 
- Bid refunding with 2% commission fee 
- Owner can finalize and withdraw funds 
- Partial withdrawal of excess funds during auction 

---

## 🛠 Constructor

### `constructor(uint _durationSeconds, uint _startingPrice)`

Initializes the auction with a given duration and starting price.


- `_durationSeconds`: Time in seconds the auction will remain open.  
- `_startingPrice`: Minimum amount required to participate.  

---

## 💸 Bidding

### `function placeBid() external payable`

Allows participants to place bids. Enforces a minimum 5% increment over the current top bid.


- Extends auction by 10 minutes if the bid is placed close to the deadline.  

---

## 🏆 Auction Finalization

### `function finalizeAuction() external onlyContractOwner`

Finalizes the auction, sends the winning bid (minus 2% commission) to the owner, and refunds all other bidders minus the 2% fee.


- Can only be called after the auction has ended.  
- Emits `AuctionClosed` and `DepositReimbursed` events.  

---

## 💰 Excess Withdrawal

### `function withdrawExcess() external`

Allows non-top bidders to withdraw excess funds above the required amount to stay in the race.


- Only works during the auction.  

---

## 🚨 Emergency Function

### `function emergencyWithdraw() external onlyContractOwner`

Allows the contract owner to withdraw remaining contract funds after the auction ends.

---

## 👁 View Functions

### `function getTopBid() external view returns (address, uint)`

Returns the address and value of the highest bid.


---

### `function getAuctionDeadline() external view returns (uint)`

Returns the timestamp of when the auction ends.


---

### `function getAllBids() external view returns (Bid[] memory)`

Returns an array of all valid bids made.


---

### `function getUserBidHistory(address user) external view returns (uint[] memory)`

Returns the list of bid amounts submitted by a specific user.


---

### `function isAuctionFinalized() external view returns (bool)`

Returns whether the auction has been finalized.


---

### `function getUserTotalBid(address user) external view returns (uint)`

Returns the total amount of funds a user has committed to the auction.


---

### `function getOwner() external view returns (address)`

Returns the address of the contract owner.


---

## 📤 Events

- `BidPlaced(address bidder, uint amount)`  
  → Emitted when a user places a bid.  

- `ExcessRefundAvailable(address bidder, uint excessAmount)`  
  → Emitted if a bidder's total exceeds the minimum required and may withdraw excess.  

- `PartialExcessRefund(address bidder, uint amount)`  
  → Emitted when a bidder withdraws part of their excess during the auction.  

- `AuctionClosed(address winner, uint finalBid)`  
  → Emitted when the auction is finalized.  

- `DepositReimbursed(address bidder, uint refund, uint fee)`  
  → Emitted when refunds are issued to non-winning bidders.  

- `EmergencyFundWithdrawn(address receiver, uint amount)`  
  → Emitted if the owner withdraws funds after auction finalization.  

---

## 🧪 Example Deployment (Remix)

1. Compile with Solidity 0.8.30
2. Deploy using:
   - `_durationSeconds`: e.g. `600` (10 minutes)
   - `_startingPrice`: e.g. `100000000000000000` (0.1 ETH)

---

## 🛡 Security Notes

- Contract ensures only the owner can finalize or withdraw emergency funds.
- Prevents the top bidder from withdrawing excess to maintain fairness.
- Auction cannot be finalized twice.

---

## ✅ To-Do for Final Project Submission

- ✅ Publish to **Sepolia**
- ✅ Verify source code on **Sepolia Etherscan**
- ✅ Submit full repo including this README to **GitHub**

---

Made with 🛠 and ☕ by Nahuel Cuesta