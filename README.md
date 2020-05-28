# Hons
Public repository for my CM4105 solution

## User Manual

### Load file into IDE
- travel to https://remix.ethereum.org in browser of choice (development was undertaken in Mozilla Firefox)
- observe important windows: main window (currently displaying the Home page), the toolbar on the far left (containing File Explorer, Compiler etc. and activated plug-ins), the terminal beneath the main window (expand to see transactions)
- in the main window, select "IMPORT FROM:" [GitHub] and enter the link to the file: https://github.com/JMRGU/Hons/Sports_Betting_App.sol
  - file should be loaded, expand File Explorer and open file
- OR select "New File" and copy-paste the code directly into the new file.


### Compile and run solution
- in toolbar, expand "Solidity compiler"
- select suitable compiler version (verified with compiler vers: "0.5.17+commit.d19bba13")
- leave Language ("Solidity") etc. as defaults
- select [Compile]
- code will be compiled, IDE will load required libraries etc.
- at completion, ignore inevitable warnings
- expand "Deploy and run transactions"
- observe the following elements:
  - "ENVIRONMENT" (enable different types of test VMs; tested using JavaScript VM)
  - "ACCOUNT" (list of virtual accounts created to test with)
  - "GAS LIMIT" (the maximum amount of gas that the account is willing to spend to power a transaction, default: 3e6)
  - "VALUE" (the amount of ETH/wei etc. to send with the transaction, default: 0)
  - "CONTRACT" (the selected contract to interact with)
- select an account (this account will be the "owner" of the smart contract)
- raise GAS LIMIT to 8000000 (note: this is because deploying a smart contract can be an expensive operation: testing showed 8e6 is sufficient to reliably deploy the contract (if deployment transaction fails, raise this higher and retry))
- leave VALUE etc. default
- ensure "Sports_Betting_App.sol" is the selected CONTRACT
- select [Deploy]
- deployment transaction is sent, after a short delay the transaction should succeed and the contract is deployed
- observe the terminal window: the transaction should appear there alongside a large green tick (for success) or red cross (for failure).  Expand the transaction to see the metadata stored within, including source/destination addresses and any message data.
- observe "Transactions recorded" and "Deployed contracts" in the Deploy window.  Expand the deployed contracts and observe the methods and fields displayed.  Call the methods by setting relevant data 


### Sample operations

#### Create a new contest
- enter the Deploy tab
- Select the owner's account
- add an amount of ETH if required (note: the first call to the API is always free; subsequent calls require payment, typically 1 ETH)
- enter a suitable database ID in the "callApi()" field, and click [callApi]
- the transaction is sent
- observe the "Provable - oracle service" tab, the query sent is registered, and the response can be seen in real time
- once the response is received, the application instantaneously derives the relevant information and creates the contest

#### Display active contests
- in the Deploy tab, any user may select [showContests] to retrieve the list of active contests
- open the transaction to see the result emitted as an event
- where the transaction has failed, the result will indicate that there are currently zero active contests
- where the transaction has succeeded, the result will display the details of each contest currently active

#### Place a bet on a contest
- in the Deploy tab
- enter the amount to bet in the VALUE field (minimum = 10 wei, maximum = 10000000000000000000 wei, or 10 ETH)
- in the "placeBet" field, enter the array index of the contest to bet on, and an integer 1 for contestant 1 or 2 for contestant 2, and separated by a comma (or click the expand arrow to display the two separate fields)
- click [placeBet]
- the amount of the bet will be sent to the contract, and the bettor's address and bet recorded internally
- observe the balance of the selected account to confirm funds left the account
- select [showContests] to display the contest with the amount added to the contestant's totals of bets placed

#### Complete a contest and pay out winning wagers
- in the Deploy tab, select the owner's account
- provide "contestComplete" wih the array index of the contest to conclude, and the winning contestant (1 = contestant 1, 2 = contestant 2, any other positive integer = draw or unexpected outcome)
- click [contestComplete]
- if the outcome was a draw or unexpected, the application will return every wager placed back to the original bettor
- if the outcome was 1, the application will pay every user who placed a bet on contestant 1, with their share of the total amount placed on contestant 2 (and vice versa)
- finally the application will delete the completed contest
- observe the balances of the betting accounts to confirm successful transactions

#### Delete a contest
- in the Deploy tab, as the owner account
- provide one of the "deleteContest" fields with either the array index of the contest to be deleted (if known) or the names of the contestants involved
- click the relevant [deleteContest] button
- the contract will locate the contest in memory
- if the contest has bets placed, the application will refund these to the bettors
- finally the application deletes the contest
- click [showContests] to confirm contest deleted


### Useful plug-ins
- expand "Plugin Manager", select desired plug-ins from "Inactive Modules" list and click [Activate] to enable
- some plug-ins to consider:
  - Solidity compiler
  - Deploy & run transactions
  - Debugger
  - Gas Profiler
  - Provable - oracle service
