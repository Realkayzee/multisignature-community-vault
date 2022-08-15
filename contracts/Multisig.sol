// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

/// @title A Multi signature contract
/// @author Kayzee
//* The multisig contract is based on community account
//* only the excos have the access to withdraw
//* Any exco that places withdrawal needs the approval of other excos
//* Anybody can check landlord addresses that deposited to the contract
/// @notice excos have the ability to revert their approval
contract Multisig {
    address[] excoAddresses;
    uint256 excoNumber;
    error _onlyExco(string);
    error _alreadyConfirmed(string);
    error _alreadyExecuted(string);
    error _notApprovedYet(string);

    struct Transaction {
        address exco;
        uint256 amount;
        uint256 noOfConfirmation;
        bool executed;
    }

    Transaction[] transactions;

    mapping(address => uint256) landLordBalances;
    mapping(uint256 => mapping(address => bool)) confirmed;

    constructor(address[] memory _excoAddresses, uint256 _exconumber ){
        require(_excoAddresses.length == _exconumber, "the number of exco specified is not filled");
        excoAddresses = _excoAddresses;
        excoNumber = _exconumber;
    }

    modifier onlyExco {
        for(uint256 i = 0; i < excoAddresses.length; i++){
            if(msg.sender != excoAddresses[i]){
                revert _onlyExco("You are not an exco");   
            }
        }
        _;

    }
    modifier alreadyConfirmed(uint256 _txIndex) {
        if(confirmed[_txIndex][msg.sender] == true){
            revert _alreadyConfirmed("you already approve once");
        }
        _;
    }
    modifier notApprovedYet(uint _txIndex){
        if(confirmed[_txIndex][msg.sender] == false){
            revert _notApprovedYet("You have'nt approved yet");
        }
        _;
    }
    modifier alreadyExecuted(uint _txIndex) {
        if(transactions[_txIndex].executed == true){
            revert _alreadyExecuted("The transactions has been executed already");
        }
        _;
    }
    
    function deposit() public payable {
        require(msg.value > 0, "You must deposit more than 0");
        landLordBalances[msg.sender] += msg.value;
    }

/// @dev function for initiating transaction for withdrawal
    function initWithdrawal(uint256 _amount) public onlyExco {
        require(_amount > 0, "Amount must be greate than zero");
        require(_amount < address(this).balance, "Insuficient Fund in the community Vault");
        address _exco = msg.sender;
        transactions.push(
            Transaction({
                exco: _exco,
                amount: _amount,
                noOfConfirmation: 0,
                executed: false
            })
        );
    }
/// @dev function for approving withdrawal
    function approveWithdrawal(uint256 _txIndex) public onlyExco alreadyExecuted(_txIndex) alreadyConfirmed(_txIndex) {
        confirmed[_txIndex][msg.sender] = true;
        Transaction storage trans = transactions[_txIndex];
        trans.noOfConfirmation += 1;
    }
    function withdrawal(uint256 _txIndex) public onlyExco alreadyExecuted(_txIndex) {
        uint256 contractBalance = address(this).balance;
        Transaction storage trans = transactions[_txIndex];
        if(trans.noOfConfirmation == excoNumber){
            trans.executed = true;
            contractBalance -= trans.amount; 
            (bool success, ) = trans.exco.call{ value: trans.amount}("");
            require(success, "Transaction failed");
        }
    }
    function revertApproval(uint256 _txIndex) public onlyExco alreadyExecuted(_txIndex) notApprovedYet(_txIndex) {
        confirmed[_txIndex][msg.sender] = false;
        Transaction storage trans = transactions[_txIndex];
        trans.noOfConfirmation -= 1;
    }


    function checkAmountRequest(uint256 _txIndex) public view returns(uint256){
        return transactions[_txIndex].amount;
    }

    function AmountInCommunityVault() public view returns(uint256 ){
        return address(this).balance;
    }
    function checkTransactionCount() public view returns(uint256) {
        return transactions.length;
    }
    function checkNumApproval(uint256 _txIndex) public onlyExco view returns (uint256) {
        return transactions[_txIndex].noOfConfirmation;
    }
}