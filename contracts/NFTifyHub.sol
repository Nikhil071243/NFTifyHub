5% royalty for creators

    struct NFTListing {
        uint256 tokenId;
        address payable seller;
        address payable creator;
        uint256 price;
        bool isListed;
    }

    mapping(uint256 => NFTListing) private _listings;
    mapping(uint256 => address) private _creators;

    event NFTMinted(uint256 indexed tokenId, address indexed creator, string tokenURI);
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event NFTDelisted(uint256 indexed tokenId, address indexed seller);
    event ListingFeeUpdated(uint256 newFee);
    event RoyaltyUpdated(uint256 newPercentage);

    constructor() ERC721("NFTify Hub", "NFTH") Ownable(msg.sender) {}

    /**
     * @dev Mint a new NFT
     * @param tokenURI Metadata URI for the NFT
     * @return tokenId The ID of the newly minted token
     */
    function mintNFT(string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        _creators[newTokenId] = msg.sender;

        emit NFTMinted(newTokenId, msg.sender, tokenURI);
        return newTokenId;
    }

    /**
     * @dev List an NFT for sale
     * @param tokenId The ID of the token to list
     * @param price The sale price in wei
     */
    function listNFT(uint256 tokenId, uint256 price) public payable nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        require(price > 0, "Price must be greater than zero");
        require(msg.value == listingFee, "Must pay listing fee");

        _transfer(msg.sender, address(this), tokenId);

        _listings[tokenId] = NFTListing({
            tokenId: tokenId,
            seller: payable(msg.sender),
            creator: payable(_creators[tokenId]),
            price: price,
            isListed: true
        });

        emit NFTListed(tokenId, msg.sender, price);
    }

    /**
     * @dev Purchase a listed NFT
     * @param tokenId The ID of the token to purchase
     */
    function purchaseNFT(uint256 tokenId) public payable nonReentrant {
        NFTListing memory listing = _listings[tokenId];
        require(listing.isListed, "NFT is not listed for sale");
        require(msg.value >= listing.price, "Insufficient payment");

        uint256 royaltyAmount = 0;
        if (listing.seller != listing.creator) {
            royaltyAmount = (listing.price * royaltyPercentage) / 100;
            listing.creator.transfer(royaltyAmount);
        }

        uint256 sellerAmount = listing.price - royaltyAmount;
        listing.seller.transfer(sellerAmount);

        _transfer(address(this), msg.sender, tokenId);
        _listings[tokenId].isListed = false;
        _itemsSold.increment();

        emit NFTSold(tokenId, listing.seller, msg.sender, listing.price);
    }

    /**
     * @dev Delist an NFT from sale
     * @param tokenId The ID of the token to delist
     */
    function delistNFT(uint256 tokenId) public nonReentrant {
        NFTListing memory listing = _listings[tokenId];
        require(listing.isListed, "NFT is not listed");
        require(listing.seller == msg.sender, "Only seller can delist");

        _transfer(address(this), msg.sender, tokenId);
        _listings[tokenId].isListed = false;

        emit NFTDelisted(tokenId, msg.sender);
    }

    /**
     * @dev Get listing details for a token
     * @param tokenId The ID of the token
     * @return NFTListing struct with listing information
     */
    function getListing(uint256 tokenId) public view returns (NFTListing memory) {
        return _listings[tokenId];
    }

    /**
     * @dev Get all listed NFTs
     * @return Array of all currently listed NFTs
     */
    function getAllListedNFTs() public view returns (NFTListing[] memory) {
        uint256 totalTokens = _tokenIds.current();
        uint256 listedCount = 0;

        for (uint256 i = 1; i <= totalTokens; i++) {
            if (_listings[i].isListed) {
                listedCount++;
            }
        }

        NFTListing[] memory listedNFTs = new NFTListing[](listedCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= totalTokens; i++) {
            if (_listings[i].isListed) {
                listedNFTs[currentIndex] = _listings[i];
                currentIndex++;
            }
        }

        return listedNFTs;
    }

    /**
     * @dev Get NFTs owned by a specific address
     * @param owner The address to query
     * @return Array of token IDs owned by the address
     */
    function getMyNFTs(address owner) public view returns (uint256[] memory) {
        uint256 totalTokens = _tokenIds.current();
        uint256 ownedCount = 0;

        for (uint256 i = 1; i <= totalTokens; i++) {
            if (_exists(i) && ownerOf(i) == owner) {
                ownedCount++;
            }
        }

        uint256[] memory ownedTokens = new uint256[](ownedCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= totalTokens; i++) {
            if (_exists(i) && ownerOf(i) == owner) {
                ownedTokens[currentIndex] = i;
                currentIndex++;
            }
        }

        return ownedTokens;
    }

    /**
     * @dev Update the listing fee (only owner)
     * @param newFee The new listing fee in wei
     */
    function updateListingFee(uint256 newFee) public onlyOwner {
        listingFee = newFee;
        emit ListingFeeUpdated(newFee);
    }

    /**
     * @dev Update the royalty percentage (only owner)
     * @param newPercentage The new royalty percentage (0-100)
     */
    function updateRoyaltyPercentage(uint256 newPercentage) public onlyOwner {
        require(newPercentage <= 100, "Percentage must be between 0 and 100");
        royaltyPercentage = newPercentage;
        emit RoyaltyUpdated(newPercentage);
    }

    /**
     * @dev Withdraw accumulated listing fees (only owner)
     */
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Get total number of NFTs minted
     * @return Total token count
     */
    function getTotalNFTs() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Get total number of NFTs sold
     * @return Total sold count
     */
    function getTotalSold() public view returns (uint256) {
        return _itemsSold.current();
    }

    /**
     * @dev Get creator address for a token
     * @param tokenId The ID of the token
     * @return Creator address
     */
    function getCreator(uint256 tokenId) public view returns (address) {
        return _creators[tokenId];
    }

    /**
     * @dev Check if a token exists
     * @param tokenId The ID of the token to check
     * @return Boolean indicating if token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}
// 
Contract End
// 
