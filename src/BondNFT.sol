// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721URIStorage} from "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Base64} from "lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract BondNFT is ERC721URIStorage, Ownable{
         
        uint256 tokenIDs;
        constructor(address initialOwner) ERC721("MyNFT", "NFT") Ownable(initialOwner) {
                tokenIDs = 0;
        }

        function mintNFT( 
        address recipient,
        string memory recipientName,
        uint256 bondValue,
        uint256 maturityDate,
        string memory cryptocurrency,
        string memory customMessage
        ) public onlyOwner returns(uint256 tokenID){
           tokenIDs++;
            uint256 newTokenId = tokenIDs;
        
          string memory svg = generateBondSVG(
              recipientName,
              bondValue,
              maturityDate,
              cryptocurrency, 
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
        uint256 maturityDate,
        string memory cryptocurrency,
        string memory customMessage
    ) internal pure returns (string memory) {
        // Convert maturity date from timestamp to readable format
        string memory bondValueStr  = Strings.toString(bondValue);
         string memory maturityDateStr = Strings.toString(maturityDate);
           return string(abi.encodePacked(
       '<svg width="400" height="600" xmlns="http://www.w3.org/2000/svg">',
        '<rect width="100%" height="100%" fill="#1A1A2E"/>',
        '<rect x="20" y="20" width="360" height="560" rx="10" fill="#0F0F1C" stroke="#BA55D3" stroke-width="4"/>',
        
        '<text x="200" y="60" font-family="Arial" font-size="30" text-anchor="middle" fill="#BA55D3" font-weight="bold">CRYPTO LEGACY BOND</text>',
        '<line x1="50" y1="100" x2="350" y2="100" stroke="#BA55D3" stroke-dasharray="5"/>',
        
        '<text x="50" y="150" font-family="Arial" font-size="18" fill="#BA55D3">RECIPIENT:</text>',
        '<text x="50" y="180" font-family="Arial" font-size="16" fill="#FFFFFF">', recipientName, '</text>',
        
        '<text x="50" y="220" font-family="Arial" font-size="18" fill="#BA55D3">BOND VALUE:</text>',
        '<text x="50" y="250" font-family="Arial" font-size="16" fill="#FFFFFF">', bondValueStr, ' ', cryptocurrency, '</text>',
        
        '<text x="50" y="290" font-family="Arial" font-size="18" fill="#BA55D3">MATURITY TIMESTAMP:</text>',
        '<text x="50" y="320" font-family="Arial" font-size="16" fill="#FFFFFF">', maturityDateStr, '</text>',
        
        '<text x="50" y="360" font-family="Arial" font-size="18" fill="#BA55D3">MESSAGE:</text>',
        '<text x="50" y="390" font-family="Arial" font-size="16" fill="#FFFFFF">', customMessage, '</text>',
        
        '<line x1="50" y1="460" y2="460" stroke="#BA55D3" stroke-dasharray="5"/>',
        '<text x="200" y="490" font-family="Arial" font-size="12" text-anchor="middle" fill="#BA55D3">CryptoLegacyBond.com</text>',
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

  
        
   

        



}