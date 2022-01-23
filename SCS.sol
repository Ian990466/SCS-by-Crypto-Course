// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts@4.4.2/token/ERC1155/utils/ERC1155Holder.sol";
import "./SCN.sol";

contract SCS is ERC1155Holder{
    mapping(string => Company) public companies;
    mapping(string => bool) public registered;

    string[] public companyNames;
    
    modifier isRegistered(string memory name) {
        require(registered[name], "company does not exist");
        _;
    }

    function addCompany(string memory _name, string memory _date, uint _shares, address[] memory _founders, uint _numConfirmationsRequired) public {
        require(registered[_name] == false, "company existed");
        Company c = new Company(_name,  _date, _shares, _founders, _numConfirmationsRequired);

        companies[_name] = c;
        registered[_name] = true;
        companyNames.push(_name);
    }

    function showCompany() public view{
        for(uint i = 0; i < companyNames.length; ++i) {
            console.log("%s: %s", companyNames[i], address(companies[companyNames[i]]));
        }
    }

    function issuing(string memory _name) public isRegistered(_name){
        Company c = companies[_name];
        c.submitTranx(msg.sender, "issuing", address(0));
    }

    function transfer(string memory _name, address target) public isRegistered(_name){
        Company c = companies[_name];
        c.submitTranx(msg.sender, "transfer", target);
    }

    function redemption(string memory _name, address target) public isRegistered(_name){
        Company c = companies[_name];
        c.submitTranx(msg.sender, "redemption", target);
    }

    function confirmTranx(string memory _name, uint _acIndex) public isRegistered(_name){
        Company c = companies[_name];
        c.confirmTranx(msg.sender, _acIndex);
    }
}