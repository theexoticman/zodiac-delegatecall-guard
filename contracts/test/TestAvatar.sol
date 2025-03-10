// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import "@gnosis.pm/safe-contracts/contracts/common/StorageAccessible.sol";
import "@gnosis.pm/safe-contracts/contracts/base/GuardManager.sol";

contract TestAvatar is StorageAccessible, GuardManager {
    mapping(address => bool) internal modules;

    receive() external payable {}

    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @param module Module to be whitelisted.
    function enableModule(address module) public {
        modules[module] = true;
    }

    function isModuleEnabled(address _module) external view returns (bool) {
        return (modules[_module]);
    }

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) public payable returns (bool) {
        address guard = getGuard();
        if (guard != address(0)) {
            Guard(guard).checkTransaction(
                to,
                value,
                data,
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                signatures,
                msg.sender
            );
        }
        bool success;
        bytes memory response;

        (success, response) = to.call{value: value}(data);
        require(success, "Safe Tx reverted");
        return success;
    }

    function execTransactionFromModule(
        address payable to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external returns (bool success) {
        require(modules[msg.sender], "Not authorized");
        if (operation == 1) (success, ) = to.delegatecall(data);
        else (success, ) = to.call{value: value}(data);
    }

    function getGuardAddress() external view returns (address) {
        return getGuard();
    }
}
