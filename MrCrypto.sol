// SPDX-License-Identifier: MIT


/*
                                                                                                       .         .                                                                              
8 888888888o.            .8.           ,o888888o.    8 8888     ,88'   d888888o.                      ,8.       ,8.                   .8.          8 8888888888    8 8888          .8.          
8 8888    `88.          .888.         8888     `88.  8 8888    ,88'  .`8888:' `88.                   ,888.     ,888.                 .888.         8 8888          8 8888         .888.         
8 8888     `88         :88888.     ,8 8888       `8. 8 8888   ,88'   8.`8888.   Y8                  .`8888.   .`8888.               :88888.        8 8888          8 8888        :88888.        
8 8888     ,88        . `88888.    88 8888           8 8888  ,88'    `8.`8888.                     ,8.`8888. ,8.`8888.             . `88888.       8 8888          8 8888       . `88888.       
8 8888.   ,88'       .8. `88888.   88 8888           8 8888 ,88'      `8.`8888.                   ,8'8.`8888,8^8.`8888.           .8. `88888.      8 888888888888  8 8888      .8. `88888.      
8 888888888P'       .8`8. `88888.  88 8888           8 8888 88'        `8.`8888.                 ,8' `8.`8888' `8.`8888.         .8`8. `88888.     8 8888          8 8888     .8`8. `88888.     
8 8888`8b          .8' `8. `88888. 88 8888           8 888888<          `8.`8888.               ,8'   `8.`88'   `8.`8888.       .8' `8. `88888.    8 8888          8 8888    .8' `8. `88888.    
8 8888 `8b.       .8'   `8. `88888.`8 8888       .8' 8 8888 `Y8.    8b   `8.`8888.             ,8'     `8.`'     `8.`8888.     .8'   `8. `88888.   8 8888          8 8888   .8'   `8. `88888.   
8 8888   `8b.    .888888888. `88888.  8888     ,88'  8 8888   `Y8.  `8b.  ;8.`8888            ,8'       `8        `8.`8888.   .888888888. `88888.  8 8888          8 8888  .888888888. `88888.  
8 8888     `88. .8'       `8. `88888.  `8888888P'    8 8888     `Y8. `Y8888P ,88P'           ,8'         `         `8.`8888. .8'       `8. `88888. 8 8888          8 8888 .8'       `8. `88888. 
*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MRCRYPTO is ERC721Enumerable, Ownable {
	using Strings for uint256;

	string baseURI;
	string public baseExtension = ".json";
	string public notRevealedUri;
	uint256 public cost = 0.0025 ether; //hacer como si ether fuera matic
	uint256 public currentMaxSupply; //inicialmente 1k y luego se modifica a 3 y 4k (en principio)
	uint256 public totalMaxSupply; //en principio a 10k
	uint256[] tokensAssigned;
	uint256 public whitelistCost = 0.001 ether;
	uint256 previousMaxSupply = 0;
	//uint256 public maxMintAmount = 20; //para testear no se pone
	bool public paused = false;
	bool public revealed = false;
	bool public whitelistOn = false;
	mapping(address => bool) public isWhitelisted;

	constructor (
		string memory _name,
		string memory _symbol,
		string memory _initBaseURI,
		string memory _initNotRevealedUri,
		uint256 _initialSupply,
		uint256 _totalMaxSupply
	) ERC721(_name, _symbol) {
		totalMaxSupply = _totalMaxSupply;
		currentMaxSupply = _initialSupply;
		setBaseURI(_initBaseURI);
		setNotRevealedURI(_initNotRevealedUri);
	}

	// internal
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function random(uint256 range) internal view returns (uint256) {
		return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, totalSupply()))) % range;
	}

	/*
	**	Genera un numero aleatorio e itera sobre el si esta repetido. Si llega hasta el final de la lista significa que no lo esta.
	*/
	function setValidRandom() public view returns (uint256){//TODO: comprobar que no gasta nada de gas ni del balance del contrato
		uint256 rnd_num = random(currentMaxSupply);
		uint256 r;
		uint256 i;

		r = rnd_num + 1;
		while (r != rnd_num){
			for (i = 0; i < tokensAssigned.length; i++){
				if (tokensAssigned[i] == r)
					break;
			}
			if (i == tokensAssigned.length){
				return r;
			}
			r++;
			if (r == totalSupply())
				r = 0;
		}
		return r;
	}

	// public
	function mint(uint256 _mintAmount) public payable {
		uint256 supply = totalSupply();
		uint256 rnd_num;

		require(!paused);
		require(_mintAmount > 0);
		//require(_mintAmount <= maxMintAmount);
		require(supply + _mintAmount <= currentMaxSupply);

		if (msg.sender != owner())
			require(msg.value >= cost * _mintAmount);

		for (uint256 i = 1; i <= _mintAmount; i++) {
			rnd_num = setValidRandom();

			tokensAssigned.push(rnd_num);
			_safeMint(msg.sender, supply + i);
		}
	}

	function whitelistMint ( uint256 _mintAmount) public payable {
		uint256 supply = totalSupply();
		require(whitelistOn);
		require(isWhitelisted[msg.sender] || msg.sender == owner());
		require(supply + _mintAmount <= totalMaxSupply);

		if(msg.sender != owner()) {
			require(_mintAmount > 0 && balanceOf(msg.sender) + _mintAmount <=  5);
			require(msg.value >= whitelistCost * _mintAmount);
		}

		for (uint256 i = 1; i <= _mintAmount; i++) {
		_safeMint(msg.sender, supply + i);
		}
	}

	function getTokenAssigned(uint256 _num) public view returns (uint256){
		require(_num < tokensAssigned.length);
		return tokensAssigned[_num];
	}

	function walletOfOwner(address _owner)
		public
		view
		returns (uint256[] memory)
	{
		uint256 ownerTokenCount = balanceOf(_owner);
		uint256[] memory tokenIds = new uint256[](ownerTokenCount);
		for (uint256 i; i < ownerTokenCount; i++) {
			tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
		}
		return tokenIds;
	}

	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(
			_exists(tokenId) && tokenId <= totalSupply() ,
			"ERC721Metadata: URI query for nonexistent token"
		);
		

		if(revealed == false && tokenId > previousMaxSupply)  {
				return notRevealedUri;
		}

		string memory currentBaseURI = _baseURI();

		return bytes(currentBaseURI).length > 0
				? string(abi.encodePacked(currentBaseURI, (tokensAssigned[tokenId - 1]).toString(), baseExtension))
				: "";
	}

	//only owner
	function increaseSupply(uint256 n) public onlyOwner{
		require(n > 0);
		require(n + currentMaxSupply <= totalMaxSupply, "No somos bolivarianos!");
		previousMaxSupply = currentMaxSupply;
		currentMaxSupply += n;
		revealed = false;
	}

	function reveal() public onlyOwner {
			revealed = true;
	}

	function setCost(uint256 _newCost) public onlyOwner {
		cost = _newCost;
	}

	/*function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
		maxMintAmount = _newmaxMintAmount;
	}*/

	function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
		notRevealedUri = _notRevealedURI;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {		
		require (totalSupply() < totalMaxSupply);
		baseURI = _newBaseURI;
	}

	function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
		require (totalSupply() < totalMaxSupply);
		baseExtension = _newBaseExtension;
	}

	function pause(bool _state) public onlyOwner {
		paused = _state;
	}

	function withdraw() public payable onlyOwner { //TODO: añadir carteras de los fundadores del contrato

		// =============================================================================
		(bool os, ) = payable(owner()).call{value: address(this).balance}("");
		require(os);
		// =============================================================================
	}

	function setWhitelistPhase () public onlyOwner {
		whitelistOn = !whitelistOn;
	}

	function addToWhitelist  (address _add) public onlyOwner {
		isWhitelisted[_add] = true;
	}

}
