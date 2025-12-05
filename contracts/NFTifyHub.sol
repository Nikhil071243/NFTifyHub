// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTifyHub is ERC721, Ownable {
    uint256 private _currentTokenId;
    string private _baseTokenURI;

    constructor(string memory _name, string memory _symbol, string memory baseURI) ERC721(_name, _symbol) {
        _baseTokenURI = baseURI;
        _currentTokenId = 0;
    }

    function mintTo(address recipient) public onlyOwner returns (uint256) {
        _currentTokenId++;
        _safeMint(recipient, _currentTokenId);
        return _currentTokenId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI
