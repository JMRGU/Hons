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


### Useful plug-ins
- expand "Plugin Manager", select desired plug-ins from "Inactive Modules" list and click [Activate] to enable
- some plug-ins to consider:
  - Solidity compiler
  - Deploy & run transactions
  - Debugger
  - Gas Profiler
  - Provable - oracle service
