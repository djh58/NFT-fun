//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RingNFT is ERC721, ERC721URIStorage, ERC721Burnable {
    constructor() ERC721("Ring NFT", "RING") {
        devWallet = msg.sender;
    }

    struct Proposal {
        address proposer;
        address proposee;
        string message;
        uint256 mintCost;
        uint256 deadline;
    }

    address devWallet;

    uint256 private revenue;

    mapping(bytes32 => Proposal) private proposals;

    event NewlyWed(address proposer, address proposee, string message, uint256 blockNum, uint256 time);

    function propose(
        address _proposee,
        string calldata _message,
        uint256 deadline
    ) external payable returns (bytes32) {
        Proposal memory proposal = Proposal(msg.sender, _proposee, _message, msg.value, deadline);
        bytes32 proposalId = keccak256(abi.encode(msg.sender, _proposee, _message, msg.value));
        proposals[proposalId] = proposal;
        // like a ring, don't lost it! not storing it in the contract
        return proposalId;
    }

    function reject(bytes32 _proposalId) external {
        Proposal memory proposal = proposals[_proposalId];
        require(proposal.proposee != msg.sender, "Wrong person!");
        require(block.timestamp <= proposal.deadline, "Too late");
        _cancelProposal(proposal.proposer, proposal.mintCost, _proposalId);
    }

    function accept(bytes32 _proposalId) external {
        Proposal memory proposal = proposals[_proposalId];
        require(proposal.proposee == msg.sender, "Wrong person!");
        require(block.timestamp <= proposal.deadline, "Too late");
        revenue += proposal.mintCost;
        _safeMint(msg.sender, uint256(_proposalId));
        emit NewlyWed(proposal.proposer, proposal.proposee, proposal.message, block.number, block.timestamp);
    }

    function renege(bytes32 _proposalId) external {
        Proposal memory proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.deadline, "Too soon");
        require(proposal.proposer == msg.sender, "Wrong person!");
        _cancelProposal(proposal.proposer, proposal.mintCost, _proposalId);
    }

    function _cancelProposal(
        address proposer,
        uint256 cost,
        bytes32 id
    ) internal {
        payable(proposer).transfer(cost);
        delete proposals[id];
    }

    function withdraw() external {
        require(msg.sender == devWallet, "Only the dev can withdraw");
        uint256 amountToSend = revenue;
        revenue = 0;
        payable(msg.sender).transfer(amountToSend);
    }

    function setURI(uint256 id, string memory uri) external {
        require(msg.sender == devWallet, "Only the dev can configure");
        _setTokenURI(id, uri);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
