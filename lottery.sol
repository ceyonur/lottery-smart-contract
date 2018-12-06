pragma solidity ^0.4.18;

contract Lottery {
  //----------Structs------------
  struct SenderHash {
    bytes32 hash;
    address sender;
  }

  //----------Variables------------
  address public owner;
  // Mapping of tickets and hashes issued to each address
  // Ticket to SenderHash
  mapping (uint => SenderHash) consumerHashes;
  //Ticket to Address
  mapping (uint => address) playerTickets;
  //Address to amount
  mapping (address => uint) winnersMap;
  //User to balance
  mapping (address => uint) userBalances;

  //Bought tickets
  uint[] consumedTickets;
  address[] players;
  address[] winners;
  uint[23] winnerTickets;


  uint collectedMoney;
  uint distributedMoney;

  // When the lottery started
  uint public lotteryStart;

  // Duration the lottery will be active for in days
  uint constant PURCHASE_DURATION = 5 days;
  uint constant REVEAL_DURATION = 2 days;

  uint constant TICKET_START = 0;
  uint constant TICKET_END = 99999;

  //Prize constants in ether
  uint[] PRIZES = [50000 ether, 10000 ether, 400 ether, 400 ether,
  200 ether , 200 ether, 200 ether, 200 ether, 200 ether,
  200 ether, 200 ether, 200 ether, 200 ether, 200 ether, 200 ether,
  100 ether, 100 ether, 100 ether, 100 ether, 100 ether];

  uint constant FOUR_DIGIT_WINNER_PRIZE = 40 ether;
  uint constant THREE_DIGIT_WINNER_PRIZE = 10 ether;
  uint constant TWO_DIGIT_WINNER_PRIZE = 4 ether;
  uint constant TICKET_COST = 2 ether;

  //Charity address
  address public charityAddress;

  //Random numbers from users
  int[] randomNumbers;

  //---------Modifiers---------------

  // Checks if still in lottery contribution period
  modifier purchaseOngoing() {
    require(now < lotteryStart + PURCHASE_DURATION);
    _;
  }

  modifier ownerOnly(){
    require(msg.sender == owner);
    _;
  }

  // Checks if lottery has finished
  modifier revealOngoing() {
    uint end = lotteryStart + PURCHASE_DURATION + REVEAL_DURATION;
    require(now < end && now > lotteryStart + PURCHASE_DURATION);
    _;
  }

  //---------Functions----------------

  //Create the lottery, each one lasts for 24 hours
  function Lottery(address _charityAddress) {
    owner = msg.sender;
    charityAddress = _charityAddress;
    resetLottery();
  }

  // Fallback function
  function () {
    revert();
  }

  // After winners have been declared and awarded, clear the arrays and reset the balances
  function resetLottery() private {
    lotteryStart = now;
    for(uint i = 0; i < players.length; i++){
      delete playerTickets[i];
    }
    for(uint k = 0; k < consumedTickets.length; k++){
      delete consumerHashes[k];
    }
    for(uint j = 0; j < winners.length; k++){
      delete winnersMap[k];
    }

    delete consumedTickets;
    consumedTickets.length = 0;
    delete randomNumbers;
    randomNumbers.length = 0;
    delete players;
    players.length = 0;
    delete winners;
    winners.length = 0;
    delete winnerTickets;
    collectedMoney=0;
    distributedMoney=0;
  }

  // Award users tickets for eth, 2 eth = 1 ticket
  // Expects playerHash == keccak256(randomNumber, ticketNumber, msg.sender)
  function buyTickets(bytes32 playerHash, uint ticketNumber) external payable purchaseOngoing returns (uint) {
    require(msg.value == TICKET_COST);
    require(ticketAvailable(ticketNumber));
    consumedTickets.push(ticketNumber);
    consumerHashes[ticketNumber] = SenderHash(playerHash, msg.sender);
    collectedMoney += TICKET_COST;
    return ticketNumber;
  }

  function enterLottery(int randomNumber, uint ticketNumber) public purchaseOngoing returns (bool) {
    SenderHash storage sh = consumerHashes[ticketNumber];
    require(sh.sender == msg.sender && keccak256(randomNumber, ticketNumber, msg.sender) == sh.hash);
    playerTickets[ticketNumber] = msg.sender;
    players.push(msg.sender);
    randomNumbers.push(randomNumber);
    return true;
  }

  function checkEnoughMoneyCollected() private view returns (bool) {
    return collectedMoney < distributedMoney;
  }

  function refundCollectedMoney() private {
    for(uint i = 0; i < consumedTickets.length; i++){
      uint ticket = consumedTickets[i];
      address consumerAddress = consumerHashes[ticket].sender;
      consumerAddress.transfer(TICKET_COST);
    }
    resetLottery();
  }

  //Generate the winners by random using tickets bought as weight
  function generateWinners() external ownerOnly revealOngoing returns (bool) {
    generateFiveDigitWinners();
    generateFourDigitWinners();
    generateThreeDigitWinners();
    generateTwoDigitWinners();
    if (checkEnoughMoneyCollected()){
      distributeAwards();
      sendRemainingToCharity();
      resetLottery();
      return true;
    }
    else {
      refundCollectedMoney();
      return false;
    }
  }

  function sendRemainingToCharity() private returns (bool){
    uint remaining = collectedMoney - distributedMoney;
    require(remaining > 0);
    charityAddress.transfer(remaining);
    return true;
  }

  function withdrawLotteryMoney() public returns (uint){
    uint prize = userBalances[msg.sender];
    require(prize > 0);
    userBalances[msg.sender] = 0;
    msg.sender.transfer(prize);
    return prize;
  }

  function generateFiveDigitWinners() private{
    for(uint i = 0; i < PRIZES.length; i++){
      uint winnerTicket = randomTicket(PRIZES[i]);
      winnerTickets[i] = winnerTicket;
      address winnerAddress = playerTickets[winnerTicket];
      if(winnerAddress != 0x0){
        awardWinner(winnerAddress, PRIZES[i]);
      }
    }
  }

  function generateFourDigitWinners() private{
    uint winnerTicket = randomTicket(FOUR_DIGIT_WINNER_PRIZE);
    uint fourDigitWinner = winnerTicket % 10000;
    winnerTickets[20] = fourDigitWinner;
    for(uint i = 0; i < consumedTickets.length; i++){
      uint currentTicket = consumedTickets[i];
      address winnerAddress = playerTickets[currentTicket];
      if(currentTicket % 10000  == fourDigitWinner && winnerAddress != 0){
        awardWinner(winnerAddress, FOUR_DIGIT_WINNER_PRIZE);
      }
    }
  }

  function generateThreeDigitWinners() private{
    uint winnerTicket = randomTicket(THREE_DIGIT_WINNER_PRIZE);
    uint threeDigitWinner = winnerTicket % 1000;
    winnerTickets[21] = threeDigitWinner;
    for(uint i = 0; i < consumedTickets.length; i++){
      uint currentTicket = consumedTickets[i];
      address winnerAddress = playerTickets[currentTicket];
      if(currentTicket % 1000  == threeDigitWinner && winnerAddress != 0){
        awardWinner(winnerAddress, THREE_DIGIT_WINNER_PRIZE);
      }
    }
  }

  function generateTwoDigitWinners() private{
    uint winnerTicket = randomTicket(TWO_DIGIT_WINNER_PRIZE);
    uint twoDigitWinner = winnerTicket % 100;
    winnerTickets[22] = twoDigitWinner;
    for(uint i = 0; i < consumedTickets.length; i++){
      uint currentTicket = consumedTickets[i];
      address winnerAddress = playerTickets[currentTicket];
      if(currentTicket % 100  == twoDigitWinner && winnerAddress != 0x0){
        awardWinner(winnerAddress, TWO_DIGIT_WINNER_PRIZE);
      }
    }
  }

  function getWinnerTickets() external view revealOngoing returns (uint[23]){
    return winnerTickets;
  }

  function awardWinner(address winnerAddress, uint amount) private {
    winnersMap[winnerAddress] += amount;
    winners.push(winnerAddress);
    distributedMoney += amount;
  }

  function distributeAwards() private {
    for(uint i = 0; i < winners.length; i++){
      address winnerAddress = winners[i];
      userBalances[winnerAddress] += winnersMap[winnerAddress];
    }
  }

  function randomTicket(uint seed) private view returns (uint){
    return (random(seed) % (TICKET_START - TICKET_END + 1)) + TICKET_END;
  }

  function random(uint seed) private view returns (uint) {
    return uint(keccak256(randomNumbers, seed));
  }

  function ticketAvailable(uint ticketNumber) public view returns (bool) {
    return ticketNumber >= TICKET_START && ticketNumber <= TICKET_END && consumerHashes[ticketNumber].hash == 0;
  }
}
