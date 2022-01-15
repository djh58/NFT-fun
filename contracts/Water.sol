//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @dev This contract is an ERC1155 implementation of combining and separating NFTs. This is achieved via minting and burning.
/// Specifically, we have two elements Hydrogen and Oxygen that can be minted and then combined to make water
/// In the spirit of convservation of matter, there is a finite amount of H and O, which also caps H2O's supply
/// In the spirit of conservation of energy, the contract keeps a little bit of ether everytime someone separates water back into its elements

contract Water is ERC1155, Ownable {
    enum Elements {
        Hydrogen, // 0
        Oxygen, // 1
        Water //2
    }

    uint8 public constant HYDROGEN_MAX_SUPPLY = 100;
    uint256 public constant HYDROGEN_MINT_PRICE = .05 ether;
    uint8 public hydrogenSupply;

    uint8 public constant OXYGEN_MAX_SUPPLY = 50;
    uint256 public constant OXYGEN_MINT_PRICE = .1 ether;
    uint8 public oxygenSupply;

    uint256 public ENERGY_LOST = .01 ether;

    modifier noContracts() {
        require(msg.sender == tx.origin, "No smart contract callers, only wallets");
        _;
    }

    function mintHydrogen(uint8 _amount) external payable noContracts {
        require(_amount < HYDROGEN_MAX_SUPPLY - hydrogenSupply + 1, "Not enough hydrogen supply");
        require(msg.value == HYDROGEN_MINT_PRICE * _amount, "Wrong mint price");
        hydrogenSupply += _amount;
        _mint(msg.sender, uint256(Elements.Hydrogen), _amount, "");
    }

    function mintOxygen(uint8 _amount) external payable noContracts {
        require(_amount < OXYGEN_MAX_SUPPLY - oxygenSupply + 1, "Not enough hydrogen supply");
        require(msg.value == OXYGEN_MINT_PRICE * _amount, "Wrong mint price");
        oxygenSupply += _amount;
        _mint(msg.sender, uint256(Elements.Oxygen), _amount, "");
    }

    function makeWater(uint256 _amount) external noContracts {
        uint256[] memory ids = new uint256[](2);
        ids[0] = uint256(Elements.Hydrogen);
        ids[1] = uint256(Elements.Oxygen);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _amount * 2;
        amounts[1] = _amount;
        _burnBatch(msg.sender, ids, amounts);
        _mint(msg.sender, uint256(Elements.Water), _amount, "");
    }

    function breakWater(uint256 _amount) external noContracts {
        _burn(msg.sender, uint256(Elements.Water), _amount);
        uint256[] memory ids = new uint256[](2);
        ids[0] = uint256(Elements.Hydrogen);
        ids[1] = uint256(Elements.Oxygen);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _amount * 2;
        amounts[1] = _amount;
        _mintBatch(msg.sender, ids, amounts, "");
        // transfer eth to msg.sender
        payable(msg.sender).transfer((2 * HYDROGEN_MINT_PRICE + OXYGEN_MINT_PRICE) * _amount - ENERGY_LOST);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    constructor() ERC1155("") {}
}
