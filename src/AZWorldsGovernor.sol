// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Governor, IGovernor } from "@openzeppelin/governance/Governor.sol";
import { GovernorSettings } from "@openzeppelin/governance/extensions/GovernorSettings.sol";
import { GovernorCountingSimple } from "@openzeppelin/governance/extensions/GovernorCountingSimple.sol";
import { GovernorVotes, IVotes } from "@openzeppelin/governance/extensions/GovernorVotes.sol";
import { GovernorTimelockControl } from "@openzeppelin/governance/extensions/GovernorTimelockControl.sol";
import { TimelockController } from "@openzeppelin/governance/TimelockController.sol";

contract AZWorldsGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorTimelockControl
{
    constructor(IVotes _token, TimelockController _timelock)
        Governor("AZWorldsGovernor")
        GovernorSettings(1, /* 1 block */ 63, 2)
        GovernorVotes(_token)
        GovernorTimelockControl(_timelock)
    { }

    function quorum(uint256) public pure override returns (uint256) {
        return 3;
    }

    // The following functions are overrides required by Solidity.

    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, IGovernor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
