pragma solidity ^0.5.0;
import "github.com/JMRGU/solidity-stringutils/src/strings.sol"; // originally this points to ""...utils/strings.sol" but for some reason that redirects to the original fork or whatever that requires vers 0.4.14 (even though that file simply calls "./src/strings.sol"..?)
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";


/**
 * Sports Betting App in solidity
 * 
 * @author Joe Murray
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
    uint256 MAXBETTORS; // max number of bets on a contest
    
    // store Events
    Contest[] public contests;
    
    // Event struct
    struct Contest {
        uint256 minBet; // this may differ between events or depending on amounts placed
        uint256 maxBet;
        string contestant1;
        string contestant2; // the two contesting parties in the event
        uint256 total1;
        uint256 total2; // the total bets placed on each contestant
        address payable[] bettors; // list of all bettors
        
        mapping (address => Bettor) bettorInfo; // each Contest has a map of addresses to Bettors(wager + outcome) so we can stop people from betting multiple times on the same Contest // should be public?
        
        
    }
    
    // Bettor struct
    struct Bettor{
        uint256 wager;
        uint256 outcome;
    }
    
    // string public teststr = "test222 x test111"; // string slicing test thing, see constructor()
    
    function() external payable {} // think this is required as a fallback or transaction enabler of some kind
    
    
    /** constructor
     * assigns owner and min/max bet amounts
    */
    constructor() public {
        owner = msg.sender;
        MIN = 10; // this is in wei // set manually as a global, may be better to set individually for each contest at creation time so that some could have differeing min/max amounts
        MAX = 10000000000000000000; // 1000000000000000000 wei = 10 ETH
        MAXBETTORS = 100;
        
    }
    
    
    /** kill
     * destroys contract, refunds contract's ETH to owner
    */
    function kill() public {
        if(msg.sender == owner){
            
            selfdestruct(owner);
        }
    }
    
    /** newContest()
     * creates a new Contest from contestants supplied and stores
    */
    function newContest(string memory _con1, string memory _con2) public {
        require(msg.sender == owner || msg.sender == queryAddress); // otherwise cancel execution and refund remaining gas // added check for oraclize_cbAddress
        
        address payable[] memory newBettors; // create new empty array of bettor addresses to put into object
        
        Contest memory newContest = Contest(MIN, MAX, _con1, _con2, 0, 0, newBettors);
        
        contests.push(newContest); // not sure if mapping goes here, but there should be a new mapping for every Event so yes..?
        
        emit ContestCreated("new contest: ", _con1, _con2);
        
    }
    
    
    /** showContests()
     * emits event displaying all currently active Contests
    */
    function showContests() public {
        require(contests.length > 0); // don't bother if no active contests
        
        for(uint256 i = 0; i < contests.length; i++){
        
            emit ContestDetails("active event!", contests[i].minBet, contests[i].maxBet, contests[i].contestant1, contests[i].contestant2, contests[i].total1, contests[i].total2, contests[i].bettors.length); // emit event with all relevant info from this Contest
        }
    }
    
    
    /** searchContests()
     * search through Contests[] for contest matching given contestants
    */
    function searchContests(string memory _con1, string memory _con2) public view returns (uint256) {
        require(contests.length > 0);
        
        // loop through array of contests
        // for each, check if contests[i].con1 == _con1, and same for con2
        // if so, return index
        
        for (uint256 i = 0; i < contests.length; i++){
            
            // hash the byte conversions of the contestant namestrings and compare for truth // account for user inserting names in wrong order
            if ( (keccak256(abi.encode(contests[i].contestant1)) == (keccak256(abi.encode(_con1))) && keccak256(abi.encode(contests[i].contestant2)) == (keccak256(abi.encode(_con2)))) || (keccak256(abi.encode(contests[i].contestant1)) == (keccak256(abi.encode(_con2))) && keccak256(abi.encode(contests[i].contestant2)) == (keccak256(abi.encode(_con1)))) ) { // using built-in abi.encode rather than explicit conversion to bytes32 (more efficient)
                
                return i;
            }
        }

        return contests.length; // intentionally give an oob index which deleteContest() will pick up (would have returned -1 but that's not possible for some reason)

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
        
        
        // check to see if the contest has bets placed on it: if so, refund them prior to deleting
        if(contests[_i].bettors.length > 0){
            
            refundWagers(_i);
        }
        
        
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
        
        // call the other deleteContest() with the result of searchContests() i.e. the index 
        deleteContest(searchContests(_con1, _con2));
        
        emit ContestDeleted("Contest deleted, competitors: ", _con1, _con2);
    }
    
    /** CheckBettorExists()
     * used to confirm a bettor has not already placed a bet on a given Contest
     * _bettor: wallet address of better to check 
     * _index: index of the contest to check the bettors of (perhaps Contests should each have a unique ID assigned upon creation?)
     */
     function checkBettorExists(address payable _bettor, uint256 _index) public returns(bool){ // could be "view" without emitting BettorFound event
         
        for(uint256 i = 0; i < contests[_index].bettors.length; i++){ // search through the bettors of the given contest
        
            if(contests[_index].bettors[i] == _bettor){
                
                emit BettorFound("ERROR: you have already bet on this contest: ", _bettor); // pointless since I can't see it anyway..?
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
        require(msg.value >= contests[_index].minBet); //make sure bet is sufficient // change these to Modifiers?  Doesn't seem to be an advantage to either
        require(contests[_index].bettors.length < MAXBETTORS); //ensure bets can only be placed up to maximum
        
        
        contests[_index].bettorInfo[msg.sender].wager = msg.value;
        contests[_index].bettorInfo[msg.sender].outcome = _outcome;
        
        contests[_index].bettors.push(msg.sender); // push new bettor address to the list thereof
        
        //assign bet
        _outcome == 1 ? contests[_index].total1 += msg.value : contests[_index].total2 += msg.value;
        
        emit BetPlaced(msg.sender, msg.value, _outcome); // give out confirmation
    }
    
    
    /** refundWagers()
     * given a particular index of contest, loop through that contest's bettors and pay each one their wager
     */
     function refundWagers(uint256 _index) internal {
         
         address payable bettorAddress;
         
         // loop through all bettors in a contest and send transaction with amount of their wager?
         for(uint256 i = 0; i < contests[_index].bettors.length; i++){
             
             // get bettor's address
             bettorAddress = contests[_index].bettors[i];
             
             // transfer their wager back to them 
             bettorAddress.transfer(contests[_index].bettorInfo[bettorAddress].wager);
         }
     }
    
    
    /** contestComplete()
     * takes a contest id, and the final outcome
     * finds the contest
     * if the outcome was something other than a win for either contestant, calls refundWagers() to refund the bettors
     * if the outcome was a win either way, separates the winning bettors from the losers, and pays the winners
     * finally deletes the contest
     */
    function contestComplete(uint256 _index, uint16 _winner) public {
        require(msg.sender == owner);
        address payable[100] memory winners; //temporary memory array with fixed size e.g. 100 i.e. the max number of bettors on a contest (NOTE: same value as MAXBETTORS, but due to Solidity memory high jinks I can't use that value to create a memory array - have simply hardcoded it instead)
        uint256 count = 0; // number of winners found
        uint256 loserBet = 0;
        uint256 winnerBet = 0;
        address addr;
        uint256 bet;
        uint256 prize;
        address payable bettorAddress;
        
        
        // account for draws
        if(_winner > 2 || _winner < 1){ //i.e. anything other than contestant 1 or 2 aka a draw or unexpected outcome
        
            refundWagers(_index);
        } else { // pay out to winners
        
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
                    winners[j].transfer(prize); 
                    emit PayOut(addr, bet, prize);
                }
                emit ScanningForWinners("scanning...");
            }
        }
        
        emit ContestComplete("contest complete!", _index, _winner, winnerBet, loserBet); // emit alert
        
        /** reinitialise values
        
        delete contests[_index].bettorInfo[bettorAddress]; // delete all bettors
        contests[_index].bettors.length = 0; // delete bettors array
        loserBet = 0;
        winnerBet = 0;
        contests[_index].total1 = 0;
        contests[_index].total2 = 0;
        */
        
        //no need to reinitialise values above, just delete instead
        deleteContest(_index);
    }
    
    
    /** callApi()
     * sends query via Oraclize/Provable Oracle, with given bout ID
     */
     function callApi(string memory _id) public payable {
         require(msg.sender == owner);
        // emit NewQuery("Oraclize query sent, awaiting response...");
        
        // create a query string using string utility, concatenating ID to lookup 
        strings.slice memory baseQuery = "json(https://www.thesportsdb.com/api/v1/json/1/lookupevent.php?id=".toSlice();
        string memory appendedQuery = baseQuery.concat(_id.toSlice());
        string memory finalQuery = appendedQuery.toSlice().concat(").events.0.strEvent".toSlice()); // .toString(); toString() not required?  Think it reconverts to string automatically on concat
        
        emit NewQuery(finalQuery);
        
        oraclize_query("URL", finalQuery);
        // "json(https://www.thesportsdb.com/api/v1/json/1/lookupevent.php?id=675185).events.0.strEvent" // confirmed working query
        
        /** some sample queries
         * 675185 (wilder fury)
         * 677222 (garcia vargas)
         * 674071 (brook deluca)
         */
     }
     
     
     /** callApiOutcome()
      * pulls contest ID from the contest at the given index, and sends query to retrieve the results
      * DOES NOT FUNCTION, DO NOT USE, LEFT FOR POSTERITY (also missing various enabling functionality elsewhere in the solution)
      * the plan was to provide for query control, to only permit one active query at a time, and determine the type of query (either creating a new contest, or pulling the results of an existing contest)
      * once pulling the results, call a different parse() from __callback() to get the desired field and results from the response
      * see parseOutcome() for more
      * 
     function callApiOutcome(uint256 _index) private {
         
         require(msg.sender == owner);
         require(!activeQuery);
         
         // set query control globals
         activeQuery = true;
         newContestOrOutcome = true;
         contestID = contests[_index].id;
         
         // contruct query
         strings.slice memory baseQuery = "json(https://www.thesportsdb.com/api/v1/json/1/lookupevent.php?id=".toSlice();
         string memory appendedQuery = baseQuery.concat(contestID.toSlice()); // pull the id field from the contest at the given index
         string memory finalQuery = appendedQuery.toSlice().concat(").events.0.strResult".toSlice()); // will pull the strResult field from the bout stored at this ID
         
         emit NewQuery(finalQuery);
         
         oraclize_query("URL", finalQuery, msg.value); // oraclize_query("URL", finalQuery); // TODO: revert me (the new number on the end is a specific amount of gas to supply to pay for the cost of processing the response)
         
     }
     */
     
     
     
    /** __callback()
     * method called by Oraclize on response to query
     */
    function __callback(bytes32 queryId, string memory _result) public {
        require(msg.sender == oraclize_cbAddress()); // could be provable_cbAddress(), think they rebranded at some point
        // if(msg.sender != oraclize_cbAddress()) revert(); // aka comes from wrong ID, oraclize_cbAddress() is an Oraclize/Provable inbuilt method
        
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
     
     
     /** parseOutcome()
     * takes the response from a query, finds the winner from the result and calls contestComplete() with the outcome either 1 or 2
     * note: will not work with draws, not sure how the DB formats draw results (every drawn main event was missing any info in the field completely)
     * draws must be accomodated by calling contstComplete() manually with an outcome other than 1 or 2 (and simply refunds all bettors)
     * DOES NOT WORK, DO NOT USE
     * was intended to (and does, I think) parse the API response, and determine the winner from the strResult field
     * strResult is a very long paragraph detailing the results, not at all ideal for this purpose (also is often missing from the database entries entirely)
     * Somewhere between this method and contestComplete() the application always fails, leaving no clue as to how or why
     * suspicions: too expensive no matter the gas limit / oracle has its own gas limit that this violates, passing manually or passing ETH doesn't seem to work 
     * who knows?  Debugging in Solidity/Remix is not straightforward
     *
     function parseOutcome(string memory _result) internal {
         
         
         
         string memory con1;
         string memory con2;
         uint256 index;
         uint16 winner;
         
         
         // need to find the index of the contest in question (loop through all contests to find the one where contests.id = contestID global)
         // then pull both contestants from it
         
         // take the result string and for each contestant:
            // create a substring consisting of the entire result up to the first instance of the contestant
        
        // compare lengths of substrings: the longer substring = the loser
        // set outcome ints and call contestComplete with the index of the contest and the outcome
        
        for (uint256 i = 0; i < contests.length; i++){

            if((keccak256(abi.encode(contests[i].id))) == (keccak256(abi.encode(contestID)))){
                index = i;
                con1 = contests[i].contestant1;
                con2 = contests[i].contestant2;
            }
        }
        
     
        // create duplicate slices of _result string
        // string memory resultCopy = _result; //TODO: delete me if this all works
        strings.slice memory resSlice = _result.toSlice();
        strings.slice memory resCopySlice = _result.toSlice();
        
        // for each contestant call .rfind(contestant name) on a copy of the result string, to get the string preceding the first occurrance of the contestant's name
        strings.rfind(resSlice, con1.toSlice());
        strings.rfind(resCopySlice, con2.toSlice());
        // now _result contains the string leading up to contestant 1's name, and resultCopy contains the string leading up to contestant 2's name
        // that which is the longer string indicates the loser (because the loser's name always appears after the winner's)
        if(resSlice.len() < resCopySlice.len()){
            winner = 1; // contestant 1 won
        } else {
            winner = 2; // contestant 2 won
        }
        
        emit foundResult(winner);
        // finally call contestComplete with the index of the contest and the winner
        contestComplete(index, winner);
        
        
     }*/
     
     
    
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
