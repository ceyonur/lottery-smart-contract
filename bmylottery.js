(function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
//CONSTANTS RELATED TO CONTRACT
var lotteryAbi = [{"constant":true,"inputs":[],"name":"getWinnerTickets","outputs":[{"name":"","type":"uint256[23]"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"randomNumber","type":"uint256"},{"name":"ticketNumber","type":"uint256"}],"name":"enterLottery","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"PURCHASE_DURATION","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"charityWithdraw","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"ticketNumber","type":"uint256"}],"name":"ticketAvailable","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"withdrawLotteryMoney","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"charityAddress","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"REVEAL_DURATION","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"lotteryStart","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"playerHash","type":"bytes32"},{"name":"ticketNumber","type":"uint256"}],"name":"buyTicket","outputs":[{"name":"","type":"uint256"}],"payable":true,"stateMutability":"payable","type":"function"},{"inputs":[{"name":"_charityAddress","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"payable":false,"stateMutability":"nonpayable","type":"fallback"}]
var contractaddress = "0xee40f32227571cf2a32387aa9f0c8d7a66529645" ;
var lotteryContract;
//-----------------

window.addEventListener('load', function() {
  var web3 = window.web3 ;
  if (typeof web3 !== 'undefined') {
    // Use Mist/MetaMask's provider
    web3 = new Web3(web3.currentProvider);
  }
  else {
    console.log('No web3? You should consider trying MetaMask!')
    web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
  }
  lotteryContract = web3.eth.contract(lotteryAbi).at(contractaddress);
});

window.buyTicket = function(){
  var ticketNumber = document.getElementById("buyticketnumber").value ;
  var randomNumber = document.getElementById("buyrandomnumber").value ;
  var playerHash = keccak256(parseInt(randomNumber), parseInt(ticketNumber), web3.eth.coinbase)
  lotteryContract.buyTicket(playerHash, ticketNumber, {from: web3.eth.coinbase, value: web3.toWei(2, "ether")}, function(error, result){
    if(!error) {
      var stat = JSON.stringify(result);
      document.getElementById("buyticketstatus").innerHTML = "TX ID: " + stat;
    }
    else {
      console.error("error" + error);
    }
  });
}

window.enterLottery = function(randomNumber,ticketNumber){
  var ticketNumber = document.getElementById("enterticketnumber").value ;
  var randomNumber = document.getElementById("enterrandomnumber").value ;
  lotteryContract.enterLottery(randomNumber, ticketNumber, function(error, result){
    if(!error) {
      console.log(result);
      var stat = JSON.stringify(result);
      var statText = "";
      if(stat){
        var statText = "Registered lottery with ticket: " + ticketNumber;
      }
      else {
        var statText = "Something went wrong, could not enter lottery.";
      }
      document.getElementById("enterlotterystatus").innerHTML = statText;
    }
    else {
      console.error("error" + error);
    }
  });
}

window.charityAddress = function(){
  lotteryContract.charityAddress(function(error, result){
    if(!error) {
      var stat = JSON.stringify(result);
      document.getElementById("lotterycharitystatus").innerHTML = "Charity Address is: " + stat;
    }
    else {
      console.error("error" + error);
    }
  });
}

window.lastWinners = function(){
  lotteryContract.getWinnerTickets(function(error, result){
    if(!error) {
      var stat = JSON.parse(JSON.stringify(result));
      var emptyArray = stat.every(function(i) { return i == "0"; });
      if(emptyArray){
        var statText = "There are not any finished lottery yet (or last one refunded)."
      }
      else{
        var statText = "Last winning ticket numbers are: " + stat.join(',')
      }
      document.getElementById("lastwinnersstatus").innerHTML = statText;
    }
    else {
      console.error("error" + error);
    }
  });
}

window.lotteryStartedAt = function(){
  lotteryContract.lotteryStart(function(error, result){
    if(!error) {
      var stat = JSON.parse(result);
      var myDate = new Date(stat * 1000);
      document.getElementById("lotterystartedstatus").innerHTML = "Lottery Started at: " + myDate.toLocaleString();
    }
    else {
      console.error("error" + error);
    }
  });
}

window.estimateLotteryStage = function(){
  var startP = promisify(cb => lotteryContract.lotteryStart(cb))
  var purDurP = promisify(cb => lotteryContract.PURCHASE_DURATION(cb))
  var revDurP = promisify(cb => lotteryContract.REVEAL_DURATION(cb))
  Promise.all([startP, purDurP, revDurP]).then(function ([startDateS, purchaseDurationS, revealDurationS]) {
    var stage = 'Not Available'
    var now = Math.floor(new Date().getTime()/1000.0);
    var startDate = JSON.parse(startDateS);
    var purchaseDuration = JSON.parse(purchaseDurationS);
    var revealDuration = JSON.parse(revealDurationS);
    console.log(now - startDate);
    var end = startDate + purchaseDuration + revealDuration;
    if(startDate){
      if (now < startDate + purchaseDuration){
        var stage = 'Purchase Stage';
      }
      else if (now < end && now > startDate + purchaseDuration) {
        var stage = 'Reveal Duration';
      }
      else {
        var stage = 'Waiting lottery to be completed.'
      }
    }
    document.getElementById("lotterystagestatus").innerHTML = 'Lottery Stage: ' + stage;
  });
}

window.ticketAvailable = function(){
  var ticketNumber = document.getElementById("ticketavailable").value ;
  lotteryContract.ticketAvailable(ticketNumber, function(error, result){
    if(!error) {
      var stat = JSON.parse(result);
      statText = stat ? ' is available.' : ' is not available.';
      document.getElementById("ticketavailablestatus").innerHTML = "Ticket " + ticketNumber + statText;
    }
    else {
      console.error(error);
    }
  });
}
window.charityWithdraw = function(){
  lotteryContract.charityWithdraw(function(error, result){
    if(!error) {
      var stat = JSON.stringify(result);
      document.getElementById("charitywithdrawstatus").innerHTML = "Withdraw TX: " + stat;
    }
    else {
      console.error("error" + error);
    }
  });
}

window.withdrawLotteryMoney = function(){
  lotteryContract.withdrawLotteryMoney(function(error, result){
    if(!error) {
      var stat = JSON.stringify(result);
      document.getElementById("withdrawstatus").innerHTML = "Withdraw TX: " + stat;
    }
    else {
      console.error("error" + error);
    }
  });
}

},{}]},{},[1]);
