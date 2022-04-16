pragma solidity ^0.4.24;


import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "hardhat/console.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool public operational = true;                                    // Blocks all state changes throughout the contract if false

    struct Airline {
        string airlineName;
        bool isRegistered;
        bool isFunded;
        uint256 airlineBalance;
    }
    mapping(address => Airline) public airlines;
    uint256 constant AIRLINE_REGISTRATION_FEE = 10 ether;

    uint256 public numberOfAirlines;
    uint256 public contractBalance = 0 ether;
    mapping(address => bool) public authorizedCallers;

    struct Passenger {
        string passengerName;
        bool isInsured;
        address airlineInsured;
        uint256 insuredAmount;
        uint256 passengerCreditBalance;
        bool isCreated;
    }
    mapping(address => Passenger) public passengers;
    address[] public Insurees = new address[](0);

    uint256 public reentrancyGuardCounter = 1;

    struct Flight {
        address airline;
        string flight;
        string flight_no;
        uint256 updatedTimestamp;
        uint8 statusCode;
        bool isRegistered;
    }
    mapping(bytes32 => Flight) public flights;


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event AirlineAdded(string name, address indexed account);
    event AirlineFunded(string airlineName, address indexed airlineAddress, uint256 fundAmount);

    //    event AirlineFunded(string name, address addr);
    //    event FlightRegistered(bytes32 flightKey, address airline, string flight, string from, string to, uint256 timestamp);
    //    event InsuranceBought(address airline, string flight, uint256 timestamp, address passenger, uint256 amount, uint256 multiplier);
    //    event FlightStatusUpdated(address airline, string flight, uint256 timestamp, uint8 statusCode);
    //    event InsureeCredited(address passenger, uint256 amount);
    //    event AccountWithdrawn(address passenger, uint256 amount);



    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    //    constructor
    //                                (
    //                                string memory airlineName,
    //                                address airlineAddress
    //                                )
    //                                public
    //    {
    //        contractOwner = msg.sender;
    //        numberOfAirlines = 0;
    //        airlines[airlineAddress] = Airline(airlineName, true, false, 0);
    //        numberOfAirlines = numberOfAirlines.add(1);
    //        emit AirlineAdded(airlineName, airlineAddress);
    //
    //    }


    constructor() public
    {
        contractOwner = msg.sender;
        numberOfAirlines = 0;
        // register first airline
        airlines[msg.sender] = Airline("Emirates", true, false, 0);
        numberOfAirlines = numberOfAirlines.add(1);

        // **********************************         REMIX TESTING ACCOUNTS        **********************************
        ////      ================== airlines ==================
        //        airlines[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = Airline("SAA", true, false, 0);
        //        numberOfAirlines = numberOfAirlines.add(1);
        //
        //        airlines[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = Airline("Emirates", true, false, 0);
        //        numberOfAirlines = numberOfAirlines.add(1);
        //
        //        airlines[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = Airline("Qantas", true, false, 0);
        //        numberOfAirlines = numberOfAirlines.add(1);
        //
        ////      ================== passengers ==================
        //        passengers[0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678] = Passenger("Cain", false, address(0x0), 0, 0, true);
        //
        //        passengers[0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7] = Passenger("Lee", false, address(0x0), 0, 0, true);


        // **********************************         TRUFFLE TESTING ACCOUNTS        **********************************

        //      ================== airlines ==================
//        airlines[0xa88B5e9aC3ff85440d2F98ce2c0894233B6D2ecf] = Airline("SAA", true, false, 0);
//        numberOfAirlines = numberOfAirlines.add(1);
//
//        airlines[0x0ca1B804126D91F76a31d3B20c78149Cb956C9E6] = Airline("Emirates", true, false, 0);
//        numberOfAirlines = numberOfAirlines.add(1);
//
//        airlines[0xD779884ed0A6F2CC78b272F7730377294FCf539e] = Airline("Qantas", true, false, 0);
//        numberOfAirlines = numberOfAirlines.add(1);
//
//        //      ================== passengers ==================
//        passengers[0x863DAe3e8b3710fe0ee95F4187301C479b70335a] = Passenger("Cain", false, address(0x0), 0, 0, true);
//
//        passengers[0x481DcB058a319e02dca783DeB6DC375BBfD55e4d] = Passenger("Lee", false, address(0x0), 0, 0, true);
    }



    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational()
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier isCallerAuthorised() {
        require(authorizedCallers[msg.sender] , "Caller is not authorised");
        _;
    }

    modifier entrancyGuard() {
        reentrancyGuardCounter = reentrancyGuardCounter.add(1);
        uint256 guard = reentrancyGuardCounter;
        _;
        require(guard == reentrancyGuardCounter, "Re-entrancy is not allowed");
    }


    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational()
    public
    view
    returns(bool)
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus
    (
        bool mode
    )
    external
    requireContractOwner
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline(string airlineName, bool isRegistered, bool isFunded, address airlineAddress) external
        //    requireIsOperational isCallerAuthorised
    {
        airlines[airlineAddress] = Airline(airlineName, isRegistered, isFunded, 0);
        numberOfAirlines = numberOfAirlines.add(1);
        emit AirlineAdded(airlineName, airlineAddress);
    }

    function registerPassenger(string passengerName, address passengerAddress) external
        //    requireIsOperational isCallerAuthorised
    {
        passengers[passengerAddress] = Passenger(passengerName, false, address(0x0), 0, 0, true);
    }

    function deRegisterAirline(address airlineAddress) external
        //    requireIsOperational requireContractOwner
    {
        airlines[airlineAddress].isRegistered = false;
        numberOfAirlines = numberOfAirlines.sub(1);
    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fundAirline(address airlineAddress, uint256 fundAmount) external
        //    requireIsOperational isCallerAuthorised
    {
        contractBalance = contractBalance.add(fundAmount);
        airlines[airlineAddress].airlineBalance = airlines[airlineAddress].airlineBalance.add(fundAmount);

        if (airlines[airlineAddress].airlineBalance >= AIRLINE_REGISTRATION_FEE){
            airlines[airlineAddress].isFunded = true;
            emit AirlineFunded(airlines[airlineAddress].airlineName, airlineAddress, fundAmount);
        }
    }

    function registerFlight(bytes32 key, address airline, string flight, string flight_no, uint256 timestamp, uint8 statusCode, bool isRegistered) external
        //    requireIsOperational isCallerAuthorised
    {
        flights[key] = Flight(airline, flight, flight_no, timestamp, statusCode, isRegistered);
    }

    function updateFlightStatus(bytes32 key, uint256 timestamp, uint8 statusCode) public
        //    requireIsOperational
    {
        flights[key].updatedTimestamp = timestamp;
        flights[key].statusCode = statusCode;
    }


    function getFlightData(bytes32 key) external view
        //    requireIsOperational isCallerAuthorised
    returns(address, string, string, uint256, uint8, bool)
    {
        return (flights[key].airline, flights[key].flight, flights[key].flight_no, flights[key].updatedTimestamp, flights[key].statusCode, flights[key].isRegistered);
    }

    function getAirlineData(address givenAddress) external view
        //    requireIsOperational isCallerAuthorised
    returns(string, bool, bool, uint256)
    {
        return (airlines[givenAddress].airlineName, airlines[givenAddress].isRegistered, airlines[givenAddress].isFunded, airlines[givenAddress].airlineBalance);
    }

    function getFlightSuretyDataVariables() external view
        //    requireIsOperational isCallerAuthorised
    returns(uint256) {
        return (numberOfAirlines);
    }

    function getFlightSuretyDataBalance() public view returns(uint256) {
        return (address(this).balance);
    }

    function getPassengerData(address givenPassenger) external view
        //    requireIsOperational isCallerAuthorised
    returns(string, bool, uint256, uint256, bool)
    {
        return (passengers[givenPassenger].passengerName, passengers[givenPassenger].isInsured, passengers[givenPassenger].insuredAmount, passengers[givenPassenger].passengerCreditBalance, passengers[givenPassenger].isCreated);
    }

    function authorizeCaller(address callerAddress) external
    requireContractOwner
    {
        authorizedCallers[callerAddress] = true;
    }

    function deauthorizeCaller(address callerAddress) external
    requireContractOwner
    {
        delete authorizedCallers[callerAddress];
    }

    /**
     * @dev Buy insurance for a flight
    *
    */
    function buy(address givenPassenger, address givenAirline, uint256 insuredAmount) external payable
        //    requireIsOperational isCallerAuthorised
    {
        airlines[givenAirline].airlineBalance = airlines[givenAirline].airlineBalance.add(insuredAmount);
        passengers[givenPassenger].isInsured = true;
        passengers[givenPassenger].airlineInsured = givenAirline;
        passengers[givenPassenger].insuredAmount = passengers[givenPassenger].insuredAmount.add(insuredAmount);
        Insurees.push(givenPassenger);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(bytes32 key, uint256 creditNumerator, uint256 creditDenominator) external
        //    requireIsOperational isCallerAuthorised
    {
       address currentInsureeAddress;
        for(uint i=0; i < Insurees.length; i++) {
            currentInsureeAddress = Insurees[i];
            if (passengers[currentInsureeAddress].isInsured && (passengers[currentInsureeAddress].airlineInsured == flights[key].airline)) {
                passengers[currentInsureeAddress].isInsured = false;
                passengers[currentInsureeAddress].airlineInsured = address(0x0);
                passengers[currentInsureeAddress].passengerCreditBalance = passengers[currentInsureeAddress].insuredAmount.mul(creditNumerator).div(creditDenominator);
                passengers[currentInsureeAddress].insuredAmount = 0;
                delete Insurees[i];
            }
        }
    }


    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay(address givenInsuree) external payable
    {
        uint256 amount = passengers[givenInsuree].passengerCreditBalance;
        passengers[givenInsuree].passengerCreditBalance = 0;
        contractBalance = contractBalance.sub(amount);
//        address(this).transfer(amount); ** NB: the transfer of funds has been implemented via MetaMask
    }

    //    function fund
    //                            (
    //                            )
    //                            public
    //                            payable
    //    {
    //
    //        contractBalance = contractBalance.add(msg.value);
    //
    //    }

    function getFlightKey
    (
        address airline,
        string flight,
        uint256 timestamp
    )
    pure
    internal
    returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable
    {
        require(msg.data.length == 0);
    }


}

