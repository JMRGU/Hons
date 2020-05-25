pragma solidity ^0.5.0;
import "github.com/JMRGU/solidity-stringutils/src/strings.sol"; // originally this points to ""...utils/strings.sol" but for some reason that redirects to the original fork or whatever that requires vers 0.4.14 (even though that file simply calls "./src/strings.sol"..?)
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";


/** Sports Betting App in solidity
 * @author Joe Murray
 */
 
/** SUBMISSION STATEMENT
 * This is my software solution submission as part of the requirements for my Honours Project
 */

/** Acknowledgements and Attribution
 * Third-party libraries/utilities employed: solidity-stringutils; oraclize/provable API
 * Some code not original may be found in placeBet() and distributePrizes(); used under Fair Use (Academic reasons); attributed to Stéphane Guichard of Medium.com
 */
 
contract Sports_Betting_App is usingOraclize(){
    
    // enable strings.sol
    using strings for *;
    
    // globals
    address payable public owner;
    address queryAddress; // assigned to when querying API for new contest // payable public
    
    //constants
    uint256 MIN;
    uint256 MAX; // min and max betting amounts to use when creating a new Event
    
    // store Events
    Contest[] public contests;
    
    // Event struct
    struct Contest {
        uint256 minBet; 
        uint256 maxBet;
        string contestant1;
        string contestant2; // the two contesting parties in the event
        uint256 total1;
        uint256 total2; // the total bets placed on each contestant
        address payable[] bettors; // list of all bettors
        
        mapping (address => Bettor) bettorInfo; // each Contest has a map of addresses to Bettors(wager + outcome) so we can stop people from betting multiple times on the same Contest
        
    }
    
    // Bettor struct
    struct Bettor{
        uint256 wager;
        uint256 outcome;
    }
    

    
    function() external payable {} // think this is required as a fallback or transaction enabler of some kind
    
    
    /** constructor
     * assigns owner and min/max bet amounts
    */
    constructor() public {
        owner = msg.sender;
        MIN = 100000000000000; // this is in wei = 0.0001 ether // set manually as a global, may be better to set individually for each contest at creation time so that some could have differeing min/max amounts
        MAX = 10000000000000000000000000000;
        
    }
    
    
    /** kill
     * destroys contract
    */
    function kill() public {
        if(msg.sender == owner) selfdestruct(owner);
    }
    
    /** newContest()
     * creates a new Contest from contestants supplied and stores
    */
    function newContest(string memory _con1, string memory _con2) public {
        require(msg.sender == owner || msg.sender == queryAddress); // must be called by owner, or during API call -> otherwise cancel execution and refund remaining gas
        
        address payable[] memory newBettors; // create new empty array of bettor addresses to put into object
        
        Contest memory newContest = Contest(MIN, MAX, _con1, _con2, 0, 0, newBettors);
        
        contests.push(newContest); 
        
        emit ContestCreated("new contest: ", _con1, _con2);
        
    }
    
    
    /** showContests()
     * emits event displaying all currently active Contests
    */
    function showContests() public {
        require(contests.length > 0); // don't bother if no active contests
        
        for(uint256 i = 0; i < contests.length; i++)
            emit ContestDetails("active event: ", contests[i].minBet, contests[i].maxBet, contests[i].contestant1, contests[i].contestant2, contests[i].total1, contests[i].total2, contests[i].bettors.length); // emit event with all relevant info from this Contest
    }
    
    
    /** searchContests()
     * search through Contests[] for contest matching given contestants
    */
    function searchContests(string memory _con1, string memory _con2) public view returns (uint256) {
        require(contests.length > 0);
        
        // loop through array of contests
        // for each, check if contests[i].con1 == _con1, and same for con2
        // if so, return index (break first?)
        
        for (uint256 i = 0; i < contests.length; i++){
            if ( keccak256(bytes(contests[i].contestant1)) == (keccak256(bytes(_con1))) && keccak256(bytes(contests[i].contestant2)) == (keccak256(bytes(_con2))) ) { // simplest way to compare strings in solidity: convert into ints using keccak256() hash function and compare the values of those
                return i;
            }
        }

        return contests.length; // intentionally give an oob index which deleteContest() will pick up (typical convention in this case would probably be to return -1, but I'm using unsigned ints)

    }
    
    /** deleteContest()
     * delete a given contest
     * contest specified by index parameter given
     * overloaded
    */
    function deleteContest(uint256 _i) public {
        require(msg.sender == owner);
        require(contests.length > 0);
        require(_i < contests.length); // aka not found: see searchContests()
        
        // delete value at [_i] by replacing with the value at [_i+1]
        // repeat until copied all values to end of array
        // then cut off final value (now duplicate)
        
        for (uint i = _i; i < contests.length-1; i++){
            contests[i] = contests[i+1];
        }
        
        contests.length--;
        // return array;
        
        emit ContestDeleted("Contest deleted at index: ", _i);
    }
    
    
    /** deleteContest()
     * delete a given contest
     * contest specified by contestant parameters given
     * overloaded
    */
    function deleteContest(string memory _con1, string memory _con2) public {
        require(msg.sender == owner);
        // call something like:
        deleteContest(searchContests(_con1, _con2)); // get the index for the right contest from searchContests() then call the other deleteContest() method with that index
        emit ContestDeleted("Contest deleted, competitors: ", _con1, _con2);
    }
    
    /** CheckBettorExists()
     * used to confirm a bettor has not already placed a bet on a given Contest
     * _bettor: wallet address of better to check 
     * _index: index of the contest to check the bettors of (perhaps Contests should each have a unique ID assigned upon creation?)
     */
     function checkBettorExists(address payable _bettor, uint256 _index) public returns(bool){ // could be "view" if choose not to emit BettorFound event
         
        for(uint256 i = 0; i < contests[_index].bettors.length; i++){ // search through the bettors of the given contest
            if(contests[_index].bettors[i] == _bettor){
                emit BettorFound("ERROR: you have already bet on this contest: ", _bettor);
                return true;
            }
        }
        return false;
    }
    
    
    /** placeBet()
     * places bet on an outcome of a contest
     */
     function placeBet(uint256 _index, uint8 _outcome) public payable {
        // preliminary checks
        require(!checkBettorExists(msg.sender, _index)); //make sure user has not already placed a bet on the given contest
        require(msg.value >= contests[_index].minBet); //make sure bet is sufficient
        
        
        contests[_index].bettorInfo[msg.sender].wager = msg.value;
        contests[_index].bettorInfo[msg.sender].outcome = _outcome;
        
        contests[_index].bettors.push(msg.sender); // push new bettor address to the list thereof
        
        //assign bet
        _outcome == 1 ? contests[_index].total1 += msg.value : contests[_index].total2 += msg.value;
        
        emit BetPlaced(msg.sender, msg.value, _outcome); // give out confirmation
    }
    
    /** distributePrizes()
     * takes a contest id, and the winning outcome
     * finds the contest, separates the winning bettors from the losers, and pays the winners
     */
    function distributePrizes(uint256 _index, uint16 _winner) public {
        require(msg.sender == owner);
        address payable[1000] memory winners; //temporary memory array with fixed size e.g. 1000
        uint256 count = 0; // number of winners found
        uint256 loserBet = 0;
        uint256 winnerBet = 0;
        address addr;
        uint256 bet;
        uint256 prize;
        address payable bettorAddress;
        
        // loop through all bettors and add winners to count
        for(uint256 i = 0; i < contests[_index].bettors.length; i++){
            bettorAddress = contests[_index].bettors[i];
            
            if (contests[_index].bettorInfo[bettorAddress].outcome == _winner){ // this bettor won
                winners[count] = bettorAddress;
                count++;
            }
        }
        
        emit CountDebug(count);
        
        if (_winner == 1){ // assign win/lose wager amounts
            loserBet = contests[_index].total2;
            winnerBet = contests[_index].total1;
        } else {
            loserBet = contests[_index].total1;
            winnerBet = contests[_index].total2;
        }
        
        // finally, reward winners
        for(uint256 j = 0; j < count; j++){
            if (winners[j] != address(0)){ // ensure address is not empty
                addr = winners[j];
                bet = contests[_index].bettorInfo[addr].wager;
                // determine winnings and pay out
                prize = (bet*(10000 + (loserBet * 10000/winnerBet)))/10000;
                winners[j].transfer(prize); // TODO: try out various reward systems
                emit PayOut(addr, bet, prize);
            }
            
            // emit ScanningForWinners("scanning...");
        }
        
        emit ContestComplete("contest complete!", _index, _winner, winnerBet, loserBet); // emit confirmation alert
        
        // and delete contest
        deleteContest(_index);
    }
    
    
    /** callApi()
     * sends query via Oraclize/Provable Oracle, with given bout ID
     */
     function callApi(string memory _id) public payable {
         require(msg.sender == owner);
        // emit NewQuery("Oraclize query sent, awaiting response...");
        
        
        strings.slice memory baseQuery = "json(https://www.thesportsdb.com/api/v1/json/1/lookupevent.php?id=".toSlice();
        string memory appendedQuery = baseQuery.concat(_id.toSlice());
        string memory finalQuery = appendedQuery.toSlice().concat(").events.0.strEvent".toSlice()); // .toString(); toString() not required?  Think it reconverts to string automatically on concat
        
        emit NewQuery(finalQuery);
        
        oraclize_query("URL", finalQuery);
        // "json(https://www.thesportsdb.com/api/v1/json/1/lookupevent.php?id=675185).events.0.strEvent" // confirmed working query
        
        /** some sample queries
         * 675185 (wilder fury)
         * 677222 (garcia vargas)
         */
     }
     
     
    /** __callback()
     * method called by Oraclize on response to query
     */
    function __callback(bytes32 queryId, string memory _result) public {
        require(msg.sender == oraclize_cbAddress()); // aka comes from correct ID, oraclize_cbAddress() is an Oraclize/Provable inbuilt method
        
        
        queryAddress = msg.sender; // assign to global var
        
        emit NewFight("result is: ", _result);
        
        // now call parseFighters() with the result
        parseFighters(_result);
    }
    
    
    /** parseFighters()
     * method to take the query response and convert it into two contestant strings
     */
     function parseFighters(string memory _result) public {
        // generate temporary slice vars
        
        // what is the address of the sender here?
        // is it oraclize_cbAddress(), if so can I modify newContest() to check for that instead of "msg.sender == owner"?
        // or save the owner's address privately and use it here..?  Is that possible/advisable/secure?
        // unknownAdd = msg.sender; // it is oraclize_cbAddress(), added check for this address when calling newContest()
        
        strings.slice memory con2Slice = _result.toSlice();
        strings.slice memory con1Slice = strings.split(con2Slice, " vs ".toSlice()); // must convert the delimiter to a slice
        // teststr = (testslice2.concat(testslice1)); // automatically reconverts to string, no need for .toString()
        newContest(con1Slice.toString(), con2Slice.toString());
     }
     
    
    /** EVENTS
     * serve as confirmation messages and such
    */
    event ContestDetails(string msg, uint256 minimum_bet_amount, uint256 maximum_bet_amount, string contestant_1, string contestant_2, uint256 amount_wagered_on_contestant_1, uint256 amount_wagered_on_contestant_2, uint256 number_of_bettors); // NOTE: probably wouldn't want to print out all the betting addresses, just the length of the array (i.e. number of bettors)
    event ContestCreated(string msg, string contestant_1, string contestant_2);
    event ContestDeleted(string msg, uint256 index_of_contest_deleted);
    event ContestDeleted(string msg, string contestant_1, string contestant_2);
    event BettorFound(string msg, address bettor);
    event BetPlaced(address bettor, uint wager, uint8 outcome);
    event CountDebug(uint count);
    event PayOut(address bettor, uint initial_wager, uint winnings);
    event ScanningForWinners(string msg);
    event ContestComplete(string msg, uint256 contest, uint outcome, uint win_amount, uint lose_amount);
    event NewQuery(string msg);
    event NewFight(string msg, string title);
}
