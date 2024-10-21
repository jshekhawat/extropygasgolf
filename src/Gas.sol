// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract GasContract is Ownable {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public whiteListStruct;
    mapping(uint => address) public administrators;
    error onlyAdminOrOwnerErr();
    error InsufficientBalance();
    error InvalidTier();
    error LowBalance();
    error LowAmount();
    address public contractOwner;

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    modifier onlyAdminOrOwner() {
        if (msg.sender != contractOwner || !checkForAdmin(msg.sender)) {
            revert onlyAdminOrOwnerErr();
        }
        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;

        for (uint256 ii = 0; ii < _admins.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == contractOwner) {
                    balances[contractOwner] = _totalSupply;
                    emit supplyChanged(contractOwner, _totalSupply);
                } else {
                    balances[_admins[ii]] = 0;
                    emit supplyChanged(_admins[ii], 0);
                }
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool) {
        for (uint ii = 0; ii < 5; ii++) {
            if (administrators[ii] == _user) {
                return true;
            }
        }
        return false;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return balances[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata
    ) public returns (bool) {
        if (balances[msg.sender] < _amount) {
            revert InsufficientBalance();
        }
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);

        return true;
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyAdminOrOwner {
        if (_tier > 255) {
            revert InvalidTier();
        }
        whitelist[_userAddrs] = _tier > 3 ? 3 : _tier;

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        if (whitelist[msg.sender] == 0 || whitelist[msg.sender] > 3) {
            revert InvalidTier();
        }
        if (balances[msg.sender] < _amount) {
            revert LowBalance();
        }
        if (_amount <= 3) {
            revert LowAmount();
        }

        whiteListStruct[msg.sender] = _amount;
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        balances[msg.sender] += whitelist[msg.sender];
        balances[_recipient] -= whitelist[msg.sender];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (
            whiteListStruct[sender] > 0 ? true : false,
            whiteListStruct[sender]
        );
    }
}
