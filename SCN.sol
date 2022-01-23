// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "hardhat/console.sol";
import "@openzeppelin/contracts@4.4.2/token/ERC1155/ERC1155.sol";

contract Company is ERC1155{

    uint tokenID = 0;
    struct Tranx {
        address owner;
        bool executed;
        uint numConfirmations;
        string tranxName;
        address target;
    }

    string name;
    string date;
    uint shares;
    address[] public founders;
    uint public numConfirmationsRequired;

    Tranx[] public tranxs;

    mapping(address => bool) public isFounder;
    mapping(string => bool) public isValidTranx;
    mapping(uint => mapping(address => bool)) public isConfirmed;

    event ConfirmTranx(address indexed founder, uint indexed txIndex);
    event SubmitTranx(address indexed owner, uint indexed txIndex);

    modifier onlyFounder(address _founder){
        require(isFounder[_founder], "Not founder");
        _;
    }

    modifier onlyValidTranx(string memory _tranx){
        require(isValidTranx[_tranx], "Tranx is invalid");
        _;
    }

    modifier notExecuted(uint _txIndex){
        require(!tranxs[_txIndex].executed, "Tranx already exectued");
        _;
    }
    
    modifier notConfirmed(address _founder, uint _txIndex){
        require(!isConfirmed[_txIndex][_founder], "Tranx already confirmed");
        _;
    }

    constructor(string memory _name, string memory _date, uint _shares, address[] memory _founders, uint _numConfirmationsRequired) ERC1155("https://abcoathup.github.io/SampleERC1155/api/token/{id}.json"){
        require(_founders.length > 0, "owners required");
        require(_numConfirmationsRequired > 0 && 
                _numConfirmationsRequired <= _founders.length,
                "invalid number of required confirmations"
        );
        require(_shares > 0);

        for (uint i = 0; i < _founders.length; i++) {
            address founder = _founders[i];

            require(founder != address(0), "invalid owner");
            require(!isFounder[founder], "founder not unique");

            isFounder[founder] = true;
            founders.push(founder);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        name = _name;
        date = _date;
        shares = _shares;

        // mint the genesis SCN
        _mint(msg.sender, tokenID, shares, "");

        isValidTranx["issuing"] = true;
        isValidTranx["transfer"] = true;
        isValidTranx["redemption"] = true;
    }

    function compareString(string memory a, string memory b) public pure returns (bool){
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function submitTranx(address _owner, string memory _tranxName, address _target) public onlyFounder(_owner) onlyValidTranx(_tranxName){

        if (compareString(_tranxName, "transfer") || compareString(_tranxName, "redemption") ) {
            require(_target != address(0));
        }

        uint txIndex = tranxs.length;
        tranxs.push(
            Tranx({
                owner: _owner,
                executed: false,
                numConfirmations: 0,
                tranxName: _tranxName,
                target: _target
            })
        );

        emit SubmitTranx(_owner, txIndex);
    }
    
    function confirmTranx(address _founder, uint _txIndex) public onlyFounder(_founder) notExecuted(_txIndex) notConfirmed(_founder, _txIndex){
        Tranx storage tranx = tranxs[_txIndex];
        tranx.numConfirmations += 1;
        isConfirmed[_txIndex][_founder] = true;

        if (tranx.numConfirmations >= numConfirmationsRequired) {
            executeTranx(_txIndex);
        }

        emit ConfirmTranx(_founder, _txIndex);
    }

    function executeTranx(uint _txIndex) private{
        Tranx storage tranx = tranxs[_txIndex];

        tranx.executed = true;

        if (compareString(tranx.tranxName, "issuing")) {
            issuing();
        }else if (compareString(tranx.tranxName, "transfer")) {
            transfer(tranx.target);
        }else if (compareString(tranx.tranxName,"redemption")) {
            redemption(tranx.target);
        }
    }

    function issuing() private{
        _mint(msg.sender, tokenID, 1, "");
        console.log("issuing a token");
    }

    function transfer(address target) private{
        _burn(msg.sender, tokenID, 1);
        safeTransferFrom(msg.sender, target, tokenID, 1, "");
        console.log("transfered");
    }

    function redemption(address target) private{
        safeTransferFrom(target, msg.sender, tokenID, 1, "");
        _burn(target, tokenID, 1);
        console.log("redemed");
    }
}