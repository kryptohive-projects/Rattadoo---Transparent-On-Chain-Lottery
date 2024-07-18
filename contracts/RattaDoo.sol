// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "hardhat/console.sol";

/// @title Room Raffle Contract
/// @notice This contract allows players to enter rooms with a fee and win a percentage of the total pool if enough players enter the room.
contract RattaDoo {
    // Address of the admin
    address public admin;

    // Struct to store room details
    struct Room {
        address creator;
        uint256 gameEntryFee;
        uint256 playersPerRoom;
        uint256 prizePercentage;
        string roomName;
        address[] players;
    }

    // Mapping of room numbers to Room details
    mapping (uint256 => Room) public customRooms;
    // Mapping of room numbers to the list of player addresses in the default room
    mapping (uint256 => address[]) public defaultRooms;
    // Counter for the number of default rooms
    uint256 public defaultRoomCount;
    // Counter for the number of custom rooms
    uint256 public customRoomCount;
    // Amount of ether required to join the default game
    uint256 public gameEntryFee;
    // Number of players required to trigger the raffle in the default room
    uint256 public playersPerRoom;
    // Percentage of the total pool to be sent to the winner in the default room
    uint256 public prizePercentage;
    // Pending withdrawals
    mapping(address => uint256) public pendingWithdrawals;

    // Event emitted when a player enters a room
    event PlayerEntered(address indexed player, uint256 indexed roomNumber);
    
    // Event emitted when a winner is selected
    event WinnerSelected(address indexed winner, uint256 indexed roomNumber, uint256 prizeAmount);

    // Event emitted when a custom room is created
    event RoomCreated(address indexed creator, uint256 indexed roomNumber, uint256 gameEntryFee, uint256 playersPerRoom, uint256 prizePercentage, string roomName);

    // Constructor to initialize the contract state
    constructor(uint256 _gameEntryFee, uint256 _playersPerRoom, uint256 _prizePercentage) {
        admin = msg.sender; // Set the contract deployer as the admin
        gameEntryFee = _gameEntryFee;
        playersPerRoom = _playersPerRoom;
        prizePercentage = _prizePercentage;
    }

    /*
     * Modifier to restrict access to admin-only functions
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    /*
     * Modifier to prevent reentrancy attacks
     */
    modifier nonReentrant() {
        require(!entered, "Reentrant call");
        entered = true;
        _;
        entered = false;
    }

    // Reentrancy guard variable
    bool private entered;

    /*
     * Function to convert bytes to uint256
     * @param b The bytes data to be converted
     * @return result The resulting uint256 value
     */
    function bytesToUint256(bytes memory b) public pure returns (uint256) {
        uint256 result;
        assembly {
            result := mload(add(b, 32))
        }
        return result;
    }


    /*
     * Function to handle the prize distribution and room reset
     * @param players The list of players in the room
     * @param gameEntryFee The entry fee for the room
     * @param prizePercentage The percentage of the total pool to be sent to the winner
     * @param roomCreator The address of the room creator (can be admin for default rooms)
     * @param roomNumber The room number
     */
    function distributePrize(address[] storage _players, uint256 _gameEntryFee, uint256 _prizePercentage, address _roomCreator, uint256 _roomNumber) internal {
        // Concatenate player addresses for randomness seed
        bytes memory concatAddresses = "";
        for (uint256 i = 0; i < _players.length; i++) {
            concatAddresses = abi.encodePacked(concatAddresses, _players[i]);
        }
        // Improve randomness by adding more seeds
        bytes memory improvedRandomBytes = abi.encodePacked(concatAddresses, block.timestamp, block.prevrandao, block.number);
        // Generate a random index for the winner
        uint256 winnerIndex = bytesToUint256(abi.encodePacked(keccak256(improvedRandomBytes))) % _players.length;
        // Calculate the prize amount
        uint256 prizeAmount = (_players.length * _gameEntryFee * _prizePercentage) / 100;

        // Calculate the remaining amount to be shared between admin and creator
        uint256 remainingAmount = (_players.length * _gameEntryFee * (100 - _prizePercentage)) / 100;
        uint256 adminShare = remainingAmount / 2;
        uint256 creatorShare = remainingAmount - adminShare;

        // Update pending withdrawals
        pendingWithdrawals[admin] += adminShare;
        pendingWithdrawals[_roomCreator] += creatorShare;
        // Transfer the prize to the winner
        (bool success, ) = _players[winnerIndex].call{value: prizeAmount}("");
        require(success, "Transfer to winner failed");
        emit WinnerSelected(_players[winnerIndex], _roomNumber, prizeAmount);
    }

    /*
     * Function to allow a player to enter the default room
     */
    function play() public payable nonReentrant {
        // Ensure the player sends the exact entry fee
        require(msg.value == gameEntryFee, "Incorrect game entry fee");

        // Add the player to the current room
        defaultRooms[defaultRoomCount].push(msg.sender);
        emit PlayerEntered(msg.sender, defaultRoomCount);

        // If the room is full, select a winner
        if (defaultRooms[defaultRoomCount].length >= playersPerRoom) {
            distributePrize(defaultRooms[defaultRoomCount], gameEntryFee, prizePercentage, admin, defaultRoomCount);
            delete defaultRooms[defaultRoomCount];
            defaultRoomCount++;
        }
    }

    /*
     * Function to create a new room with custom settings
     * @param _gameEntryFee Amount of ether required to join the game
     * @param _playersPerRoom Number of players required to trigger the raffle
     * @param _prizePercentage Percentage of the total pool to be sent to the winner
     */
    function createRoom(uint256 _gameEntryFee, uint256 _playersPerRoom, uint256 _prizePercentage, address _creator, string memory _roomName) public onlyAdmin {
        require(_prizePercentage <= 100, "Prize percentage must be between 0 and 100");
        
        Room storage newRoom = customRooms[customRoomCount];
        newRoom.creator = _creator;
        newRoom.gameEntryFee = _gameEntryFee;
        newRoom.playersPerRoom = _playersPerRoom;
        newRoom.prizePercentage = _prizePercentage;
        newRoom.roomName = _roomName;

        emit RoomCreated(msg.sender, customRoomCount, _gameEntryFee, _playersPerRoom, _prizePercentage, _roomName);

        customRoomCount++;
    }

    /*
     * Function to allow a player to enter a custom room
     * @param roomNumber The room number to enter
     */
    function playInCustomRoom(uint256 roomNumber) public payable nonReentrant {
        Room storage room = customRooms[roomNumber];
        require(msg.value == room.gameEntryFee, "Incorrect game entry fee");
        
        room.players.push(msg.sender);
        emit PlayerEntered(msg.sender, roomNumber);

        // If the room is full, select a winner
        if (room.players.length >= room.playersPerRoom) {
            distributePrize(room.players, room.gameEntryFee, room.prizePercentage, room.creator, roomNumber);
            delete customRooms[roomNumber];
        }
    }

    /*
     * Function to allow users to withdraw their pending balance
     */
    function claim() public nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No funds to withdraw");

        pendingWithdrawals[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    /*
     * Fallback function to prevent accidental ether transfers
     */
    receive() external payable {
        revert("Direct payments not allowed");
    }
}
