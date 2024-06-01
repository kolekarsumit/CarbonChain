// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Carbonchain {
    address public owner = 0x480c56828B1e23875b80835E79D6A8Cb72823758;
    uint256 public carbonLimit = 250;
    uint256 public treeNo = 46;
    uint256 public costPerTree = 5;
    uint256 public costGWei = 3500; //cost of GWei equivalent to 1 INR= 3500
    uint256 public transactionCounter;
    uint256 public contractBalance;
    uint256 public fund;

    struct Company {
        uint256 companyId;
        string companyName;
        string companyDescription;
        string companyEmail;
        address walletAddress;
    }

    struct CompanyInfo {
        uint256 companyId;
        string companyName;
        address companyAddress;
    }

    struct Entry {
        uint256 number;
        uint256 applicabletax;
        uint256 month;
    }

    struct Transaction {
        uint256 index;
        uint256 taxAmount;
        uint256 timestamp;
        bool status; // true for paid, false for not paid
        address companyAddress;
    }

    struct UserDeposit {
        string name;
        string country;
        uint256 amount;
    }

    mapping(address => Company) public companies;
    mapping(address => CompanyInfo) public companyInfoMap;
    mapping(string => address) internal companyAddressByName; // mapping to store company addresses by name
    mapping(address => Entry[]) public companyEntries; // Separate array for past entries of each company
    mapping(uint256 => Transaction) public transactionLog;
    UserDeposit[] public userDeposits;
    address[] public companyAddresses; // Array to store addresses of registered companies
    uint256 public companyIdCounter;
    mapping(address => bool) public removedCompanies; // Track removed companies

    event CompanyRegistered(
        address indexed walletAddress,
        string companyName,
        string companyDescription
    );
    event TaxPaid(
        address indexed companyAddress,
        uint256 taxAmount,
        uint256 timestamp,
        uint256 transactionIndex
    );
    event DepositToContract(
        address indexed from,
        string name,
        string country,
        uint256 amount
    ); // Event for deposit to contract

    constructor() {
        companyIdCounter = 0;
        transactionCounter = 0;
        contractBalance = 0;
    }

    function register(
        uint256 _companyId,
        string memory _companyName,
        string memory _companyDescription,
        string memory _companyEmail
    ) public {
        require(
            bytes(_companyName).length > 0,
            "Company name must not be empty"
        );
        require(
            bytes(_companyDescription).length > 0,
            "Company description must not be empty"
        );
        require(
            bytes(_companyEmail).length > 0,
            "Company email cannot be empty"
        );
        require(
            companyAddressByName[_companyName] == address(0),
            "Company name already registered"
        );

        // Check if the company address has been removed
        require(
            !removedCompanies[msg.sender],
            "Company address has been removed"
        );

        companies[msg.sender] = Company(
            _companyId,
            _companyName,
            _companyDescription,
            _companyEmail,
            msg.sender
        );
        companyAddresses.push(msg.sender); // Adds the address of the registered company to the array

        CompanyInfo memory companyInfo = CompanyInfo(
            _companyId,
            _companyName,
            msg.sender
        );
        companyInfoMap[msg.sender] = companyInfo;

        // Add the company address to the new mapping using the company name as the key
        companyAddressByName[_companyName] = msg.sender;

        emit CompanyRegistered(msg.sender, _companyName, _companyDescription);

        companyIdCounter++;
    }

    function login() public view returns (uint256, string memory, address) {
        require(
            companies[msg.sender].walletAddress != address(0),
            "Company not registered"
        );

        Company memory company = companies[msg.sender];
        return (company.companyId, company.companyName, company.walletAddress);
    }

    // get company by address
    function getCompanyInfo(
        address _companyAddress
    ) public view returns (uint256, string memory, address) {
        CompanyInfo memory companyInfo = companyInfoMap[_companyAddress];
        return (
            companyInfo.companyId,
            companyInfo.companyName,
            companyInfo.companyAddress
        );
    }

    // get company info by company name
    function getCompanyInfoByName(
        string memory _companyName
    ) public view returns (uint256, string memory, address) {
        address companyAddress = companyAddressByName[_companyName];
        require(companyAddress != address(0), "Company not found");
        CompanyInfo memory companyInfo = companyInfoMap[companyAddress];
        return (
            companyInfo.companyId,
            companyInfo.companyName,
            companyInfo.companyAddress
        );
    }

    function displayAllCompaniesAndRecentNumbers()
        public
        view
        returns (uint256[] memory, string[] memory, uint256[] memory)
    {
        uint256[] memory companyIds = new uint256[](companyAddresses.length);
        string[] memory companyNames = new string[](companyAddresses.length);
        uint256[] memory recentNumbers = new uint256[](companyAddresses.length);

        for (uint256 i = 0; i < companyAddresses.length; i++) {
            address companyAddress = companyAddresses[i];
            Entry[] storage entries = companyEntries[companyAddress];

            companyIds[i] = companies[companyAddress].companyId;
            companyNames[i] = companies[companyAddress].companyName;
            if (entries.length > 0) {
                recentNumbers[i] = entries[entries.length - 1].number;
            } else {
                recentNumbers[i] = 0; // If no entries, assign 0 as the recent number
            }
        }

        return (companyIds, companyNames, recentNumbers);
    }

    function displayPastRecordsForLoggedInCompany()
        public
        view
        returns (Entry[] memory)
    {
        address companyAddress = msg.sender;
        return companyEntries[companyAddress];
    }

    // Carbon Storage To get Total Tacx in INR
    function store(uint256 num, uint256 month) public {
        uint256 applicabletonne = num > carbonLimit ? num - carbonLimit : 0;
        uint256 totalTreeCount = applicabletonne * treeNo;
        uint256 tax = totalTreeCount * costPerTree;
        Entry memory newEntry = Entry(num, tax, month);
        companyEntries[msg.sender].push(newEntry); // Store the entry details for the company
    }

    // Pay Tax function (modified to be payable)
    function payTax(uint256 amount) public payable returns (string memory) {
        require(amount > 0, "Amount should be greater than zero");
        require(msg.value >= amount, "Insufficient ether sent");

        address companyAddress = msg.sender;
        Entry[] storage entries = companyEntries[companyAddress];
        if (entries.length == 0) {
            return "No tax to pay";
        }
        uint256 mostRecentTax = entries[entries.length - 1].applicabletax;
        mostRecentTax = mostRecentTax * costGWei;
        require(amount == mostRecentTax, "Tax amount mismatch, payment failed");

        // Transfer received ether to contract balance
        contractBalance += msg.value;

        entries[entries.length - 1].applicabletax = 0; // Mark tax as paid
        transactionCounter++;
        Transaction memory newTransaction = Transaction(
            transactionCounter,
            amount,
            block.timestamp,
            true,
            companyAddress
        );
        transactionLog[transactionCounter] = newTransaction;
        emit TaxPaid(
            companyAddress,
            amount,
            block.timestamp,
            transactionCounter
        );
        return "Tax paid successfully";
    }

    // Get payable tax
    function getPayableTax() public view returns (uint256) {
        address companyAddress = msg.sender;
        Entry[] storage entries = companyEntries[companyAddress];
        if (
            entries.length == 0 &&
            entries[entries.length - 1].applicabletax == 0
        ) {
            return 0; // No payable tax
        }
        uint256 mostRecentTax = entries[entries.length - 1].applicabletax;
        mostRecentTax = mostRecentTax * costGWei;
        return mostRecentTax;
    }

    // Get all past transactions for the logged in company
    function getTransactionHistory()
        public
        view
        returns (Transaction[] memory)
    {
        address companyAddress = msg.sender;
        uint256 numTransactions = transactionCounter;
        uint256 count = 0;
        for (uint256 i = 1; i <= numTransactions; i++) {
            if (transactionLog[i].companyAddress == companyAddress) {
                count++;
            }
        }
        Transaction[] memory transactions = new Transaction[](count);
        count = 0;
        for (uint256 i = 1; i <= numTransactions; i++) {
            if (transactionLog[i].companyAddress == companyAddress) {
                transactions[count] = transactionLog[i];
                count++;
            }
        }
        return transactions;
    }

    //Government side setting
    function viewCarbonLimit() public view returns (uint256) {
        return carbonLimit;
    }

    function viewTreeNo() public view returns (uint256) {
        return treeNo;
    }

    function viewCostPerTree() public view returns (uint256) {
        return costPerTree;
    }

    function viewCostGWei() public view returns (uint256) {
        return costGWei;
    }

    function setCarbonLimit(uint256 i) public {
        if (msg.sender == owner) {
            carbonLimit = i;
        }
    }

    function setTreeno(uint256 j) public {
        if (msg.sender == owner) {
            treeNo = j;
        }
    }

    function setCostPerTree(uint256 k) public {
        if (msg.sender == owner) {
            costPerTree = k;
        }
    }

    function setCostGWei(uint256 l) public {
        if (msg.sender == owner) {
            costGWei = l;
        }
    }

    // Function to display contract balance (only accessible by contract owner)
    function viewContractBalance() public view returns (uint256) {
        require(
            msg.sender == owner,
            "Only contract owner can view contract balance"
        );
        return contractBalance;
    }

    // Function to withdraw funds from contract balance (only accessible by contract owner)
    function withdrawFromContractBalance(uint256 amount) public {
        require(
            msg.sender == owner,
            "Only contract owner can withdraw from contract balance"
        );
        require(amount <= contractBalance, "Insufficient balance in contract");

        // Transfer funds to owner
        payable(owner).transfer(amount);

        // Update contract balance
        contractBalance -= amount;
    }

    // Function to remove a company from registered companies
    function removeCompany(address _companyAddress) public {
        require(msg.sender == owner, "Only contract owner can remove company");

        // Check if the company exists
        require(
            companies[_companyAddress].walletAddress != address(0),
            "Company does not exist"
        );

        // Remove company from companyAddresses array
        for (uint256 i = 0; i < companyAddresses.length; i++) {
            if (companyAddresses[i] == _companyAddress) {
                // Swap with the last element and delete
                companyAddresses[i] = companyAddresses[
                    companyAddresses.length - 1
                ];
                companyAddresses.pop();
                break;
            }
        }

        // Remove company from mappings
        delete companies[_companyAddress];
        delete companyInfoMap[_companyAddress];

        // Mark company as removed
        removedCompanies[_companyAddress] = true;
    }

    // Deposit function to accept ethers from users along with their name and country
    function depositToContract(
        string memory _name,
        string memory _country
    ) public payable {
        require(msg.value > 0, "Amount should be greater than zero");

        // Update contract balance
        contractBalance += msg.value;
        fund += msg.value;

        // Store user deposit details
        userDeposits.push(UserDeposit(_name, _country, msg.value));

        // Emit event for the deposit
        emit DepositToContract(msg.sender, _name, _country, msg.value);
    }

    // Function to retrieve total number of user deposits
    function getUserDepositCount() public view returns (uint256) {
        return userDeposits.length;
    }

    // Function to retrieve user deposit details at a given index
    function getUserDeposit(
        uint256 index
    ) public view returns (string memory, string memory, uint256) {
        require(index < userDeposits.length, "Index out of bounds");
        UserDeposit memory deposit = userDeposits[index];
        return (deposit.name, deposit.country, deposit.amount);
    }

    //Function to view funds collected
    function viewFundsCollected() public view returns (uint256) {
        return fund;
    }
}
