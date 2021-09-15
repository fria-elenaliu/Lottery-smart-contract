// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/*Lottery rules:

  1. Players send their ETHs to a lottery contract address, and their wallet address will be registered. 
  2. Each entry to play is 1 ETH;
  3. Players can send multiple entries for a higer chance to win;
  4. Minimum players for winner drawing is 3 players;
  5. There is a lottery manager who controls the lottery contract address, with ability to see the balance and pick a winner;
  6. The lottery manager is automatically added to the lottery pool, no eth entry is required.
  7. Once a winner is randomly picked, the lottery contract will transfer the entire remaining balace to the winner's address, net of a mgmt fee;
  8. Once funds is dispersed, the lottery is reset. 
  9. The lottery manager receives 10% of the lottery pool balance as a fee.
  
*/

contract Lottery {
    /*
    1. state variables needed: 
        1. an array to host all the player's addresses; needs a "payable" address here as one of the players will be the owner that receives payout;
        2. Lottery manager = msg.sender
        3. The winner payable address;
    
    */

    address payable[] public lotteryPool;
    address public manager;
    address payable winner;

    /*
    2. 
        1. decalring constructor; 
        2. automatically adding the lottery manager to the pool
    */

    constructor() {
        manager = msg.sender;
        lotteryPool.push(payable(msg.sender));
    }

    /*
    3. Entering in the lottery: 
        1. register players when they send 1 Eth to the lottery contract;
        2. Eths received will be added to the contract balance;
        3. Lottery manager can view the balance
    */

    receive() external payable {
        require(msg.value == 1 ether, "To play, each entry is 1 ether.");
        lotteryPool.push(payable(msg.sender));
    }

    function getLotteryBalance() public view returns (uint256) {
        require(
            msg.sender == manager,
            "Only the lottery manager can view the balance."
        );
        return address(this).balance;
    }

    /*
    4. Pick a winner 
        1. Needs a random generator function to draw the lottery
        2. Problem: should use ChainLink VRF(verifiable random function) in real world
    */
    function getRandom() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        lotteryPool.length,
                        block.difficulty,
                        block.timestamp
                    )
                )
            );
    }

    function pickWinner() public {
        //Winner picking
        require(
            lotteryPool.length >= 3,
            "Needs a minimum of three players to draw a winner."
        );
        require(
            msg.sender == manager,
            "Only the lottery manager can draw the winner."
        );
        uint256 r = getRandom();
        uint256 winnerNum = r % lotteryPool.length;
        winner = lotteryPool[winnerNum];
    }

    function showWinner() public view returns (address) {
        return winner;
    }

    /*
    5. Dispurse payout and reset the lottery
        1. lottery manager gets 10% as fee;
        2. The remaining is sent to the lottery winner.
        3. Lottery balance should be zero and lottery pool is reset to an empty array.
    */

    function sendMoney() private {
        //Manager fee is 10% of the pool balance; Winner gets the rest;
        uint256 mgrFee = (getLotteryBalance() * 10) / 100;
        uint256 winnerPrize = (getLotteryBalance() * 90) / 100;

        //Dispurse funds
        require(
            msg.sender == manager,
            "Only the lottery manager can dispurse funds."
        );
        payable(manager).transfer(mgrFee);
        winner.transfer(winnerPrize);

        //Resetting the lottery pool to an empty array
        lotteryPool = new address payable[](0);
        lotteryPool.push(payable(msg.sender));
    }
}
