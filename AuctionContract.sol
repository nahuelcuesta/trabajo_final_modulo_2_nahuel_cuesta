// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title Decentralized Auction Contract
 * @dev This contract enables a decentralized auction with features such as:
 * - Minimum 5% bid increments
 * - Time extension for last-minute bids
 * - Refunds for non-winning bidders
 * - Commission deduction for the owner
 * - Withdrawal of excess bid funds during the auction
 */
contract Auction {
    address private owner;
    uint private auctionEndTime;
    uint private constant commissionRate = 2;
    uint private constant extensionPeriod = 10 minutes;
    uint public startingPrice;
    bool private isAuctionEnded;

    struct Bid {
        address bidder;
        uint amount;
    }

    Bid[] private allBids;
    Bid private topBid;

    mapping(address => uint) private totalBids;
    mapping(address => uint[]) private bidderHistory;
    mapping(address => uint) public withdrawableAmount;

    event BidPlaced(address indexed bidder, uint amount);
    event ExcessRefundAvailable(address indexed bidder, uint excessAmount);
    event AuctionClosed(address winner, uint finalBid);
    event PartialExcessRefund(address indexed bidder, uint amount);
    event DepositReimbursed(address indexed bidder, uint refund, uint fee);
    event EmergencyFundWithdrawn(address indexed receiver, uint amount);

    modifier onlyBeforeAuctionEnds() {
        require(block.timestamp < auctionEndTime, "Auction already ended");
        _;
    }

    modifier onlyContractOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    /**
     * @notice Constructor sets auction duration and initial price
     * @param _durationSeconds Duration of the auction in seconds
     * @param _startingPrice Minimum initial bid to participate
     */
    constructor(uint _durationSeconds, uint _startingPrice) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + _durationSeconds;
        startingPrice = _startingPrice;
    }

    /**
     * @notice Function to place a bid
     * @dev Requires a bid amount at least 5% higher than the current top bid
     *      Adds time extension if bid is placed in the last 10 minutes
     */
    function placeBid() external payable onlyBeforeAuctionEnds {
        require(msg.value > 0, "Bid must be greater than zero");

        if (topBid.amount == 0) {
            require(msg.value >= startingPrice, "Bid below starting price");
        } else {
            require(msg.sender != topBid.bidder, "Already the top bidder");
            uint minBid = topBid.amount + (topBid.amount * 5) / 100;
            uint newBidTotal = totalBids[msg.sender] + msg.value;
            require(newBidTotal > minBid, "Bid too low");
        }

        totalBids[msg.sender] += msg.value;
        bidderHistory[msg.sender].push(msg.value);

        uint refundExcess = 0;
        if (topBid.amount > 0) {
            uint requiredAmount = topBid.amount + (topBid.amount * 5) / 100;
            if (totalBids[msg.sender] > requiredAmount) {
                refundExcess = totalBids[msg.sender] - requiredAmount;
                emit ExcessRefundAvailable(msg.sender, refundExcess);
            }
        }

        if (totalBids[msg.sender] > topBid.amount) {
            topBid = Bid(msg.sender, totalBids[msg.sender]);
            allBids.push(topBid);

            if (auctionEndTime - block.timestamp <= extensionPeriod) {
                auctionEndTime += extensionPeriod;
            }
        }

        emit BidPlaced(msg.sender, totalBids[msg.sender]);
    }

    /**
     * @notice Function to finalize the auction
     * @dev Only callable by the contract owner once auction ends
     *      Transfers winning funds and refunds others with 2% fee
     */
    function finalizeAuction() external onlyContractOwner {
        require(block.timestamp >= auctionEndTime, "Auction still active");
        require(!isAuctionEnded, "Auction already finalized");
        require(topBid.amount > 0, "No valid bids");

        isAuctionEnded = true;
        uint fee = (topBid.amount * commissionRate) / 100;
        payable(owner).transfer(topBid.amount - fee);

        emit AuctionClosed(topBid.bidder, topBid.amount);

        for (uint i = 0; i < allBids.length; i++) {
            address bidder = allBids[i].bidder;
            if (bidder != topBid.bidder && totalBids[bidder] > 0) {
                uint fullAmount = totalBids[bidder];
                uint refund = fullAmount - (fullAmount * commissionRate) / 100;
                totalBids[bidder] = 0;
                payable(bidder).transfer(refund);
                emit DepositReimbursed(bidder, refund, (fullAmount * commissionRate) / 100);
            }
        }
    }

    /**
     * @notice Allows refunding excess bid funds during the auction
     * @dev Caller must not be current top bidder
     */
    function withdrawExcess() external onlyBeforeAuctionEnds {
        require(msg.sender != topBid.bidder, "Top bidder can't withdraw");
        uint minimumRequired = topBid.amount + (topBid.amount * 5) / 100;
        uint excess = totalBids[msg.sender] > minimumRequired
            ? totalBids[msg.sender] - minimumRequired
            : 0;
        require(excess > 0, "No excess funds to withdraw");

        totalBids[msg.sender] = minimumRequired;
        payable(msg.sender).transfer(excess);

        emit PartialExcessRefund(msg.sender, excess);
    }

    /**
     * @notice Emergency withdrawal by the owner
     * @dev Only allowed after auction has ended
     */
    function emergencyWithdraw() external onlyContractOwner {
        require(isAuctionEnded, "Auction not finalized");
        uint balance = address(this).balance;
        payable(owner).transfer(balance);
        emit EmergencyFundWithdrawn(owner, balance);
    }

    // ================= VIEW FUNCTIONS =================

    function getTopBid() external view returns (address, uint) {
        return (topBid.bidder, topBid.amount);
    }

    function getAuctionDeadline() external view returns (uint) {
        return auctionEndTime;
    }

    function getAllBids() external view returns (Bid[] memory) {
        return allBids;
    }

    function getUserBidHistory(address user) external view returns (uint[] memory) {
        return bidderHistory[user];
    }

    function isAuctionFinalized() external view returns (bool) {
        return isAuctionEnded;
    }

    function getUserTotalBid(address user) external view returns (uint) {
        return totalBids[user];
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

