// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC1363
 * @notice A minimal ERC20 token with ERC1363-like transferAndCall support.
 *
 * Goals:
 * 1) Keep it simple and compile cleanly with OZ 5.x
 * 2) Work with common receiver patterns:
 *    - ERC1363 receiver: onTransferReceived(operator, from, value, data) -> bytes4
 *    - "tokensReceived" receiver (ERC777-style, often used in assignments):
 *        tokensReceived(operator, from, to, value, userData, operatorData)
 */
contract MockERC1363 is ERC20 {
    // ===== Errors =====
    error CallFailed(address to);
    error InvalidERC1363Receiver(address to);

    // ===== Selectors (avoid importing extra interfaces to reduce compile issues) =====
    // ERC1363 receiver
    bytes4 private constant ON_TRANSFER_RECEIVED_SELECTOR =
        bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"));

    // ERC777-style recipient (many homework "tokensReceived" implementations follow this)
    bytes4 private constant TOKENS_RECEIVED_SELECTOR =
        bytes4(keccak256("tokensReceived(address,address,address,uint256,bytes,bytes)"));

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /// @notice Mint tokens for local testing
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @notice ERC1363-style: transferAndCall(to, value)
    function transferAndCall(address to, uint256 value) external returns (bool) {
        return transferAndCall(to, value, "");
    }

    /// @notice ERC1363-style: transferAndCall(to, value, data)
    function transferAndCall(address to, uint256 value, bytes memory data) public returns (bool) {
        address from = _msgSender();
        _transfer(from, to, value);

        // If receiver is a contract, try callback(s)
        if (_isContract(to)) {
            _callReceiver(to, from, value, data);
        }
        return true;
    }

    /// @notice Optional: transferFromAndCall(from, to, value, data)
    /// (If you don't need it, you can delete this to keep surface area minimal)
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool) {
        _spendAllowance(from, _msgSender(), value);
        _transfer(from, to, value);

        if (_isContract(to)) {
            _callReceiver(to, from, value, data);
        }
        return true;
    }

    // ===== Internal =====

    function _callReceiver(address to, address from, uint256 value, bytes memory data) internal {
        // 1) Try ERC1363 onTransferReceived (expects bytes4 return)
        {
            (bool ok, bytes memory ret) = to.call(
                abi.encodeWithSelector(
                    ON_TRANSFER_RECEIVED_SELECTOR,
                    _msgSender(), // operator
                    from,
                    value,
                    data
                )
            );

            if (ok) {
                // If the receiver implemented it, it must return selector
                // Some contracts may return empty bytes; treat as invalid to avoid silent acceptance mismatch
                if (ret.length == 32) {
                    bytes4 retval = abi.decode(ret, (bytes4));
                    if (retval == ON_TRANSFER_RECEIVED_SELECTOR) {
                        return; // success via ERC1363 callback
                    }
                    revert InvalidERC1363Receiver(to);
                } else if (ret.length == 4) {
                    // Some contracts return raw bytes4
                    bytes4 retval;
                    assembly {
                        retval := mload(add(ret, 32))
                    }
                    if (retval == ON_TRANSFER_RECEIVED_SELECTOR) {
                        return;
                    }
                    revert InvalidERC1363Receiver(to);
                }
                // If ret length is unexpected, fall through to try tokensReceived (some homeworks ignore return)
            }
        }

        // 2) Fallback: try tokensReceived (ERC777-style, no return)
        {
            (bool ok2, ) = to.call(
                abi.encodeWithSelector(
                    TOKENS_RECEIVED_SELECTOR,
                    _msgSender(), // operator
                    from,
                    to,
                    value,
                    data,   // userData
                    bytes("") // operatorData
                )
            );

            if (ok2) return;
        }

        // 3) If neither worked, revert to make failure obvious
        revert CallFailed(to);
    }

    function _isContract(address a) internal view returns (bool) {
        return a.code.length > 0;
    }
}
