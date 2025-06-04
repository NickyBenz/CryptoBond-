// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721URIStorage} from "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Base64} from "lib/openzeppelin-contracts/contracts/utils/Base64.sol";

contract BondNFT is ERC721URIStorage, Ownable{
        uint256 tokenIDs;
        constructor(address initialOwner) ERC721("MyNFT", "NFT") Ownable(initialOwner) {
                tokenIDs = 0;
        }

        function mintNFT( 
        address recipient,
        string memory recipientName,
        uint256 bondValue,
        string memory cryptocurrency,
        uint256 maturityDate,
        string memory customMessage
        ) public onlyOwner returns(uint256 tokenID){
           tokenIDs++;
            uint256 newTokenId = tokenIDs;
        
          string memory svg = generateBondSVG(
              recipientName,
              bondValue,
              cryptocurrency,
              maturityDate,
              customMessage
          );
        
          string memory tokenURI = generateTokenURI(svg);
        
         _mint(recipient, newTokenId);
         _setTokenURI(newTokenId, tokenURI);
        
         return newTokenId;
        }


  function generateBondSVG(
        string memory recipientName,
        uint256 bondValue,
        string memory cryptocurrency,
        uint256 maturityDate,
        string memory customMessage
    ) internal pure returns (string memory) {
        // Convert maturity date from timestamp to readable format
        string memory maturityDateStr = formatDate(maturityDate);
        
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="500" viewBox="0 0 400 500">',
            '<rect width="400" height="500" fill="#f5f5f5"/>',
            '<text x="200" y="50" font-family="Arial" font-size="24" text-anchor="middle" fill="#333">CRYPTO LEGACY BOND</text>',
            '<text x="30" y="100" font-family="Arial" font-size="14" fill="#333">RECIPIENT:</text>',
            '<text x="30" y="120" font-family="Arial" font-size="16" font-weight="bold" fill="#333">', recipientName, '</text>',
            '<text x="30" y="160" font-family="Arial" font-size="14" fill="#333">BOND VALUE:</text>',
            '<text x="30" y="180" font-family="Arial" font-size="16" font-weight="bold" fill="#333">', toString(bondValue), ' ', cryptocurrency, '</text>',
            '<text x="30" y="220" font-family="Arial" font-size="14" fill="#333">MATURITY DATE:</text>',
            '<text x="30" y="240" font-family="Arial" font-size="16" font-weight="bold" fill="#333">', maturityDateStr, '</text>',
            '<text x="30" y="280" font-family="Arial" font-size="14" fill="#333">CRYPTOCURRENCY:</text>',
            '<text x="30" y="300" font-family="Arial" font-size="16" font-weight="bold" fill="#333">', cryptocurrency, '</text>',
            '<text x="30" y="340" font-family="Arial" font-size="14" fill="#333">MESSAGE:</text>',
            '<text x="30" y="360" font-family="Arial" font-size="16" font-weight="bold" fill="#333">', customMessage, '</text>',
            '<text x="200" y="480" font-family="Arial" font-size="12" text-anchor="middle" fill="#333">CryptoLegacyBond.com</text>',
            '</svg>'
        ));
    }


      function generateTokenURI(string memory svg) internal pure returns (string memory) {
        string memory baseURL = "data:application/json;base64,";
        string memory json = string(abi.encodePacked(
            '{"name": "Crypto Legacy Bond", ',
            '"description": "A bond representing a cryptocurrency deposit with maturity date", ',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
        ));
        return string(abi.encodePacked(baseURL, Base64.encode(bytes(json))));
    }

        function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);




    }
        
    function formatDate(uint256 timestamp) internal pure returns (string memory) {
        // This is a simplified version - consider using a library for proper date formatting
        return string(abi.encodePacked(
            toString((timestamp / 86400 + 4) % 7), "/",  // Day
            toString((timestamp / 2629743) % 12 + 1), "/",  // Month
            toString(timestamp / 31556926 + 1970)  // Year
        ));
    }


        



}