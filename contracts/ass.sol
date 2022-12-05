contract DataStore{
uint256[50] _____gap_____;
struct Data{
uint256[] numbers;
bool in__;
bytes32 key;
}

constructor() public{
returnDataSlot().key=keccak256('YEP FOUND IT');
}

function returnDataSlot() internal view returns(Data storage d){
    assembly{
        d.slot:=13
    }
}

 }