// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ClubAbiertoAnchor
/// @notice Registro mínimo e inmutable de raíces Merkle. No almacena socios ni votos.
contract ClubAbiertoAnchor {
    address public owner;
    address public pendingOwner;

    struct Anchor {
        bytes32 merkleRoot;
        uint64 leafCount;
        uint64 anchoredAt;
    }

    mapping(bytes32 => Anchor) public anchors;

    event OwnershipTransferStarted(address indexed currentOwner, address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BatchAnchored(bytes32 indexed referenceHash, bytes32 indexed merkleRoot, uint64 leafCount, uint64 anchoredAt);

    error Unauthorized();
    error InvalidValue();
    error AlreadyAnchored();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address initialOwner) {
        if (initialOwner == address(0)) revert InvalidValue();
        owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidValue();
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner, newOwner);
    }

    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert Unauthorized();
        address previous = owner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnershipTransferred(previous, owner);
    }

    function anchor(bytes32 referenceHash, bytes32 merkleRoot, uint64 leafCount) external onlyOwner {
        if (referenceHash == bytes32(0) || merkleRoot == bytes32(0) || leafCount == 0) revert InvalidValue();
        if (anchors[referenceHash].anchoredAt != 0) revert AlreadyAnchored();
        uint64 timestamp = uint64(block.timestamp);
        anchors[referenceHash] = Anchor(merkleRoot, leafCount, timestamp);
        emit BatchAnchored(referenceHash, merkleRoot, leafCount, timestamp);
    }

    function verifyAnchor(bytes32 referenceHash, bytes32 merkleRoot, uint64 leafCount) external view returns (bool) {
        Anchor memory saved = anchors[referenceHash];
        return saved.anchoredAt != 0 && saved.merkleRoot == merkleRoot && saved.leafCount == leafCount;
    }
}
