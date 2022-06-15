// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {
    // Computes the URI for each token, which is a concatenation of baseURI and tokenId
    string _baseTokenURI;

    uint256 public _price = 0.01 ether;
    bool public _paused;
    uint256 public maxTokenIds = 20;
    uint256 public tokenIds;
    IWhitelist whitelist;
    bool public presaleStarted;
    uint256 public presaleEnded;

    modifier onlyWhenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    constructor(string memory baseURI, address whitelistContract)
        ERC721("Crypto Devs", "CD")
    {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    /**
     *@dev startPresale begins the presale for whitelisted addresses
     */
    function startPresale() public onlyOwner {
        presaleStarted = true;
        //Presale ends five minutes after it begins
        presaleEnded = block.timestamp + 5 minutes;
    }

    /**
     *@dev presaleMint allows whitelisted users to mint during the presale
     */
    function presaleMint() public payable onlyWhenNotPaused {
        require(
            presaleStarted && block.timestamp < presaleEnded,
            "Presale has not started"
        );
        require(
            whitelist.whitelistedAddresses(msg.sender),
            "Address is not whitelisted"
        );
        require(tokenIds < maxTokenIds, "Supply limit reached");
        require(msg.value >= _price, "Incorrect amount of ETH received");

        tokenIds = tokenIds + 1;
        _safeMint(msg.sender, tokenIds);
    }

    /**
     *@dev mint allows the user to mint a NFT after the presale
     */
    function mint() public payable onlyWhenNotPaused {
        require(
            presaleStarted && block.timestamp >= presaleEnded,
            "Presale not completed"
        );
        require(tokenIds < maxTokenIds, "Max supply is reached");
        require(msg.value >= _price, "Incorrect amount of ETH received");

        tokenIds = tokenIds + 1;
        _safeMint(msg.sender, tokenIds);
    }

    /**
     *@dev _baseURI overrides the openzeppelin ERC721
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     *@dev setPaused pauses the contract
     */
    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    /**
     *@dev withdraw withdraws ETH to the contract owner
     */
    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send ether");
    }

    receive() external payable {}

    fallback() external payable {}
}
