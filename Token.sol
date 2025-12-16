// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenReceiver.sol";


contract BaseERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TransferWithCallback(
    address indexed from,
    address indexed to,
    uint256 value,
    bytes data
);

    constructor() {
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100_000_000 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }
     /**
     * @dev 带回调的转账：若_to为合约地址，则调用 tokensReceived()
     */
        function transferWithCallback(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool success) {
        _transfer(msg.sender, _to, _value);

        // 如果_to是合约地址，则触发hook
        if (_isContract(_to)) {
            ITokenReceiver(_to).tokensReceived(msg.sender, msg.sender, _value, _data);
        }

        emit TransferWithCallback(msg.sender, _to, _value, _data);
        return true;
        
        }

    // ---------------- internal helpers ----------------

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "ERC20: transfer to zero address");
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");

        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);
    }

    function _isContract(address account) internal view returns (bool) {
        // extcodesize/account.code.length 在构造函数期间为0；这是EVM特性
        return account.code.length > 0;
    }
    
}
