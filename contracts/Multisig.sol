// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;


/// @title A Multi signature contract
/// @author Kayzee
//* The multisig contract is based on community account
//* only the excos have the access to withdraw
//* Any exco that places withdrawal needs the approval of other excos
//* Anybody can check landlord addresses that deposited to the contract
/// @notice excos have the ability to revert their approval
contract Multisig {
    event Deposit(address, uint256);
    event Initwithdrawal(uint256, uint256);

//***State variables */
    address[] public excoAddresses;
    uint256 excoNumber;
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
    modifier checkExco{
        require(onlyExco(), "You are not an exco");

        _;
    }

    function onlyExco() public view returns(bool check){
        for(uint256 i = 0; i < excoAddresses.length; i++){
            if(msg.sender == excoAddresses[i]){
                check = true;
            }
        }
    }

/// @dev function responsible for users(Landlord) deposit
    function deposit() public payable {
        require(msg.value > 0, "You must deposit more than 0");
        landLordBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

/// @dev function for initiating transaction for withdrawal
/// @param _amount as the param name
    function initWithdrawal(uint256 _amount) public checkExco{
        require(_amount > 0, "Amount must be greate than zero");
        require(_amount <= address(this).balance, "Insuficient Fund in the community Vault");
        address _exco = msg.sender;
        uint256 _txIndex = transactions.length;
        transactions.push(
            Transaction({
                exco: _exco,
                amount: _amount,
                noOfConfirmation: 0,
                executed: false
            })
        );
        emit Initwithdrawal(_txIndex, _amount);

    }
/// @dev function for approving withdrawal
/// @param _txIndex as the index for each transaction to be approved
    function approveWithdrawal(uint256 _txIndex) public checkExco alreadyExecuted(_txIndex) alreadyConfirmed(_txIndex) {
        confirmed[_txIndex][msg.sender] = true;
        Transaction storage trans = transactions[_txIndex];
        trans.noOfConfirmation += 1;
    }

/// @dev A function responsible for withdrawal after approval has been confirmed
/// @param _txIndex is the location of transaction to be withdrawn
    function withdrawal(uint256 _txIndex) public checkExco alreadyExecuted(_txIndex) {
        uint256 contractBalance = address(this).balance;
        Transaction storage trans = transactions[_txIndex];
        if(trans.noOfConfirmation == excoNumber){
            trans.executed = true;
            contractBalance -= trans.amount;
            (bool success, ) = trans.exco.call{ value: trans.amount}("");
            require(success, "Transaction failed");
        }
    }


/// @dev Function that handles revertion of approval by excos
/// @param _txIndex takes in the location of the transaction to be reverted
    function revertApproval(uint256 _txIndex) public checkExco alreadyExecuted(_txIndex) notApprovedYet(_txIndex) {
        confirmed[_txIndex][msg.sender] = false;
        Transaction storage trans = transactions[_txIndex];
        trans.noOfConfirmation -= 1;
    }

/// @dev A function for checking amount to be withdrawn by an exco
/// @param _txIndex tracks in the transaction index of the transaction data
    function checkAmountRequest(uint256 _txIndex) public view returns(uint256){
        return transactions[_txIndex].amount;
    }
/// @dev The total amount in the contract
    function AmountInCommunityVault() public view returns(uint256 ){
        return address(this).balance;
    }
/// @dev The total number of confirmation a particular transaction has reached
    function checkNumApproval(uint256 _txIndex) public view returns (uint256) {
        // onlyExco(msg.sender);
        return transactions[_txIndex].noOfConfirmation;
    }
/// @dev The function that checks landlord deposit
    function checkLandLordDeposit(address _addr) public view returns(uint256) {
        return landLordBalances[_addr];
    }
/// @dev The function that checks the transaction count in the contract.
    function checkTransactionCount() public view returns(uint256) {
        return transactions.length;
    }

}// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"] 