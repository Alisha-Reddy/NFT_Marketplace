// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

//IMPORT STATEMENTS
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol"; //To use console.log in smart contracts

contract NFTMarketplace is ERC721URIStorage {
    // STATE VARIABLES
    uint256 private _counter;
    uint256 private tokenIdCounter;
    uint256 private itemsSoldCounter;

    uint256 listingPrice = 0.0025 ether;
    address payable owner;

    mapping(uint256 => MarketItem) private idMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    // EVENTS
    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    // MODIFIER
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner of the marketplace can change the listing price");
        _;
    }

    constructor() ERC721("NFT Metaverse Token", "MYNFT") {
        //name, symbol
        owner = payable(msg.sender);
    }

    function updateListingPrice(uint256 _listingPrice) public payable onlyOwner {
        //This function is to update the price of the NFT
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    //CREATE NFT TOKEN FUNCTION
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint256) { //tokenURI???
        tokenIdCounter++;
        uint256 newTokenId = tokenIdCounter;

        _mint(msg.sender, newTokenId); //from ERC721.sol The address we pass should be a user addres, not any contract address. (Hence to != address(0))
        _setTokenURI(newTokenId, tokenURI); //from ERC721URIStorage.sol

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    // CREATING MARKET ITEMS
    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be atleast 1");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)), //address of this smart contract
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);

        emit idMarketItemCreated(tokenId, msg.sender, address(this), price, false);
    }

    // FUNCION FOR RESALE TOKEN
    function reSellToken(uint256 tokenId, uint256 price) public payable {
        require(
            idMarketItem[tokenId].owner == msg.sender,
            "Only item owner can pass this operation"
        );

        require(msg.value == listingPrice, "Price must be equal to listing price");

        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this)); //Whenever someone resell the nft, NFT will go to the contract and contract becoming the owner

        itemsSoldCounter--;

        _transfer(msg.sender, address(this), tokenId);
    }

    // Creates the sale of a marketplace item
    // Transfers ownership of the item, as well as funds between parties
    function createaMarketSale(uint256 tokenId) public payable {
        uint256 price = idMarketItem[tokenId].price;

        require(
            msg.value == price,
            "Please submit the require amount of price to complete the purchase "
        );

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].seller = payable(address(0)); //address(0) is the address of the contract

        itemsSoldCounter++;

        _transfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice); //the lisingPrice is going to the deployer of the contract
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }

    // GETTING UNSOLD NFT DATA
    function fetchMarketItem() public view returns (MarketItem[] memory) {
        uint256 itemCount = tokenIdCounter;
        uint256 unSoldItemCount = tokenIdCounter - itemsSoldCounter;
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;

                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    // FUNCTION TO DISPLAY THE NFTs A USER OWN IN THEIR PROFILE
    function fetchMyNFT() public view returns (MarketItem[] memory) {
        uint256 totalCount = tokenIdCounter;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return items;
    }

    // DETAILS OF THE ONLY NFTs THE USER HAS LISTED
    function fetchItemListed() public view returns (MarketItem[] memory) {
        uint256 totalCount = tokenIdCounter;
        uint256 itemsCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                itemsCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemsCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;

                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return items;
    }
}
