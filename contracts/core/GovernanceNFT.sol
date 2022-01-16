//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../libraries/GovernanceUtils.sol";
import "./Timelock.sol";

contract GovernanceNFT is ERC721, ERC721URIStorage, ERC721Burnable, Timelock {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor(address token) Timelock(token) ERC721("Governance NFT", "GNFT") {
        // 1 index NFTs so we can use _nftOwned default value of zero to check if someone owns an NFT
        _tokenIdCounter.increment();
    }

    mapping(address => uint256) public _nftOwned;

    function _beforeLockup(
        address staker,
        uint256 amount,
        uint256 releaseTime
    ) internal virtual override {
        uint256 lockupPeriod = releaseTime - block.timestamp;
        uint256 votes = GovernanceUtils.calculateVotes(amount, lockupPeriod);
        string memory uri = GovernanceUtils.stringify(amount, votes);
        if (_nftOwned[staker] == 0) {
            safeMint(staker, uri);
        } else {
            _setTokenURI(_nftOwned[staker], uri);
        }
    }

    function _beforeRelease(address staker, LockupDetails memory info) internal virtual override {
        _burn(_nftOwned[staker]);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        _nftOwned[from] = 0;
        if (from != address(0) && to != address(0)) {
            string memory newUri = GovernanceUtils.resetVotes(tokenURI(tokenId));
            _setTokenURI(tokenId, newUri);
            _nftOwned[to] = tokenId;
            for (uint256 i; i < _lockups[from].length; i++) {
                _lockups[to].push(_lockups[from][i]);
            }
        }
    }

    function safeMint(address to, string memory uri) internal {
        require(_nftOwned[to] == 0, "Cannot mint NFT to address that already owns an NFT");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _nftOwned[to] = tokenId;
        _setTokenURI(tokenId, uri);
    }

    function getVotes(address staker) public view returns (uint256) {
        require(_nftOwned[staker] > 0, "Cannot get votes for address that does not own an NFT");
        (, uint256 votes) = GovernanceUtils.getDetails(tokenURI(_nftOwned[staker]));
        return votes;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        _nftOwned[msg.sender] = 0;
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
