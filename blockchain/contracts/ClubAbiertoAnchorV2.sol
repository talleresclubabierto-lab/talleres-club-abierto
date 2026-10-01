// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ClubAbiertoAnchorV2
/// @notice Registro mínimo e inmutable de raíces Merkle con separación entre gobierno y operación.
contract ClubAbiertoAnchorV2 {
    address public owner;
    address public pendingOwner;
    address public anchorer;

    struct Anchor {
        bytes32 merkleRoot;
        uint64 leafCount;
        uint64 anchoredAt;
    }

    mapping(bytes32 => Anchor) public anchors;

    event OwnershipTransferStarted(address indexed currentOwner, address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AnchorerChanged(address indexed previousAnchorer, address indexed newAnchorer);
    event BatchAnchored(bytes32 indexed referenceHash, bytes32 indexed merkleRoot, uint64 leafCount, uint64 anchoredAt);

    error Unauthorized();
    error InvalidValue();
    error AlreadyAnchored();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyAnchorer() {
        if (msg.sender != anchorer) revert Unauthorized();
        _;
    }

    constructor(address initialOwner, address initialAnchorer) {
        if (initialOwner == address(0) || initialAnchorer == address(0)) revert InvalidValue();
        owner = initialOwner;
        anchorer = initialAnchorer;
        emit OwnershipTransferred(address(0), initialOwner);
        emit AnchorerChanged(address(0), initialAnchorer);
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

    function setAnchorer(address newAnchorer) external onlyOwner {
        if (newAnchorer == address(0)) revert InvalidValue();
        address previous = anchorer;
        anchorer = newAnchorer;
        emit AnchorerChanged(previous, newAnchorer);
    }

    function anchor(bytes32 referenceHash, bytes32 merkleRoot, uint64 leafCount) external onlyAnchorer {
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
