//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RugPull is ERC721, ERC721URIStorage, Ownable {
    constructor() ERC721("Rugpull NFT", "RUG") {}

    uint256 public nftsCreated;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_MINT_PER_PERSON = 3;
    uint256 public constant MINT_PRICE = .01 ether;
    uint256 public constant RUG_PRICE = .05 ether;

    event Rugged(address indexed loser, address indexed puller, uint256 tokenId);

    modifier noContracts() {
        require(msg.sender == tx.origin, "No smart contract callers, only wallets");
        _;
    }

    function mintRug(uint8 _amount) external payable noContracts {
        require(_amount + nftsCreated < MAX_SUPPLY + 1, "Exceeded max supply");
        require(_amount < MAX_MINT_PER_PERSON + 1, "Too many rugs");
        require(msg.value > MINT_PRICE * _amount - 1, "Not enough funds to mint");
        for (uint256 i; i < _amount; i++) {
            nftsCreated++;
            _safeMint(msg.sender, nftsCreated);
        }
    }

    function pullRug(uint256 tokenId) external payable noContracts {
        address owner = this.ownerOf(tokenId);
        require(msg.value > RUG_PRICE, "Not enough funds to pull");
        require(owner != address(0), "Nobody to pull from");
        _transfer(owner, msg.sender, tokenId);

        emit Rugged(owner, msg.sender, tokenId);

        // ideas:
        // mint an NFT to represent this rugpull
        // change metadata of NFT that has been rugged
        // mint a new rug
        // raise rug price
    }

    // other ideas:
    // withdraw function for contract owner to withdraw funds (mint and rug revenue)
    // time configurations for rugging - ex: an NFT can only be rugged once a day

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}
