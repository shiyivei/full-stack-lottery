// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {

    address public owner;
    address payable[] public players;
    uint public lotteryId ;

    mapping(uint => address payable) public lotteryHistory;

    //random number part
    bytes32 internal keyHash;
    uint internal fee;
    uint public randomResult;

    constructor() 
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        
        //init info
        owner = msg.sender;
        lotteryId = 1;
    }
    
    function getRandomNumber() public returns (bytes32 requestId) {
        //调用这个函数就需要给合约地址打款了
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

   
    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        randomResult = randomness;
    }

    function getWinnerByLottery(uint lottery) public view returns(address payable) {
        return lotteryHistory[lottery];
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
            return players;
    }

    function enter() public payable {
        //entry game condition
        require(msg.value > .01 ether );
        players.push(payable(msg.sender));

    }

    // function getRandomNumber() public view returns(uint) {
    //     return uint(keccak256(abi.encodePacked(owner,block.timestamp)));
    // }

    function pickWinner() public onlyOwner {
        //pick winner means to get random number
        getRandomNumber();
        
    }

    function payWinner() public {
        require(randomResult>0, "Must have a source of randomness before choosing winner");
        //produce winner
        uint index = randomResult % players.length;
        players[index].transfer(address(this).balance);

        lotteryHistory[lotteryId] = players[index];
        lotteryId ++;
        
        //reset the state of contract
        players = new address payable[](0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}