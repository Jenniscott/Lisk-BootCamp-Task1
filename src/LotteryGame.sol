// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title LotteryGame
 * @dev A simple number guessing game where players can win ETH prizes
 */
contract LotteryGame {
    struct Player {
        uint256 attempts;
        bool active;
    }

    // State variables
    mapping(address => Player) public players;
    address[] public playerAddresses;
    uint256 public totalPrize;
    address[] public winners;
    address[] public prevWinners;
    uint256 public constant REGISTRATION_FEE = 0.02 ether;
    uint256 public constant MAX_ATTEMPTS = 3;

    // Events
    event PlayerRegistered(address indexed player, uint256 stake);
    event GuessResult(address indexed player, uint256 guess, uint256 randomNumber, bool isCorrect);
    event PrizesDistributed(address[] winners, uint256 prizePerWinner);

    /**
     * @dev Register to play the game
     * Players must stake exactly 0.02 ETH to participate
     */
    function register() public payable {
        // Verify correct payment amount
        require(msg.value == REGISTRATION_FEE, "Registration fee is 0.02 ETH");
        
        // Check player isn't already registered
        require(!players[msg.sender].active, "Player already registered");
        
        // Add player to mapping
        players[msg.sender] = Player({
            attempts: MAX_ATTEMPTS,
            active: true
        });
        
        // Add player address to array
        playerAddresses.push(msg.sender);
        
        // Update total prize
        totalPrize += msg.value;
        
        // Emit registration event
        emit PlayerRegistered(msg.sender, msg.value);
    }

    /**
     * @dev Make a guess between 1 and 9
     * @param guess The player's guess
     */
    function guessNumber(uint256 guess) public {
        // Validate guess is between 1 and 9
        require(guess >= 1 && guess <= 9, "Guess must be between 1 and 9");
        
        // Check player is registered and has attempts left
        require(players[msg.sender].active, "Player not registered");
        require(players[msg.sender].attempts > 0, "No attempts left");
        
        // Generate "random" number
        uint256 randomNumber = _generateRandomNumber();
        
        // Compare guess with random number
        bool isCorrect = (guess == randomNumber);
        
        // Update player attempts
        players[msg.sender].attempts--;
        
        // Handle correct guesses
        if (isCorrect) {
            winners.push(msg.sender);
        }
        
        // Emit appropriate event
        emit GuessResult(msg.sender, guess, randomNumber, isCorrect);
    }

    /**
     * @dev Distribute prizes to winners
     */
    function distributePrizes() public {
        // Ensure there are winners and prize to distribute
        require(winners.length > 0, "No winners");
        require(totalPrize > 0, "No prize to distribute");
        
        // Calculate prize amount per winner
        uint256 prizePerWinner = totalPrize / winners.length;
        
        // Transfer prizes to winners
        for (uint256 i = 0; i < winners.length; i++) {
            payable(winners[i]).transfer(prizePerWinner);
        }
        
        // Update previous winners list
        delete prevWinners;
        prevWinners = winners;
        
        // Reset game state
        delete winners;
        totalPrize = 0;
        
        // Reset player data
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            delete players[playerAddresses[i]];
        }
        delete playerAddresses;
        
        // Emit event
        emit PrizesDistributed(prevWinners, prizePerWinner);
    }

    /**
     * @dev View function to get previous winners
     * @return Array of previous winner addresses
     */
    function getPrevWinners() public view returns (address[] memory) {
        return prevWinners;
    }

    /**
     * @dev Helper function to generate a "random" number
     * @return A uint between 1 and 9
     * NOTE: This is not secure for production use!
     */
    function _generateRandomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 9 + 1;
    }
}