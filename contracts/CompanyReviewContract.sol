// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./VerifySignature.sol";

contract CompanyReviewContract is VerifySignature {
    // Structs
    struct Company {
        bool isRegistered;
        address companyAddress;
    }

    struct Review {
        string period;
        string availability; // "available" or "closed"
    }

    struct ReviewCompany {
        bool isRegistered;
        address reviewCompanyAddress;
    }

    // Mappings
    mapping(address => Company) public companies;
    mapping(address => Review) public reviews;
    mapping(address => ReviewCompany) public reviewCompanies;

    // Events
    event CompanyRegistered(address indexed companyAddress);
    event ReviewCompanyRegistered(address indexed reviewCompanyAddress);
    event ReviewCreated(
        address indexed companyAddress,
        string period,
        string availability
    );
    event ReviewResultProvided(
        address indexed reviewCompanyAddress,
        address indexed companyAddress,
        string result
    );

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyRegisteredCompany() {
        require(
            companies[msg.sender].isRegistered,
            "Only registered companies can call this function"
        );
        _;
    }

    modifier onlyReviewCompany() {
        require(
            reviewCompanies[msg.sender].isRegistered,
            "Only registered review companies can call this function"
        );
        _;
    }

    modifier reviewAvailable(address companyAddress) {
        require(
            keccak256(abi.encodePacked(reviews[companyAddress].availability)) ==
                keccak256("available"),
            "Review is not available"
        );
        _;
    }

    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function registerCompany(
        address companyAddress,
        bytes32 _ethSignedMessageHash,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public onlyOwner {
        require(
            !companies[companyAddress].isRegistered,
            "Company is already registered"
        );

        (bool a, address empty1, address empty2) = verifyWithRVS(
            owner,
            _ethSignedMessageHash,
            r,
            s,
            v
        );
        require(a, "Invalid signature by ECDSA");

        companies[companyAddress] = Company(true, companyAddress);
        emit CompanyRegistered(companyAddress);
    }

    function registerReviewCompany(
        address _reviewCompanyAddress,
        bytes memory signature
    ) public onlyOwner {
        require(
            !reviewCompanies[_reviewCompanyAddress].isRegistered,
            "Review company is already registered"
        );

        // Verify the signature
        bytes32 messageHash = keccak256(
            abi.encodePacked(_reviewCompanyAddress)
        );
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        require(
            recoverSigner(ethSignedMessageHash, signature) == owner,
            "Invalid signature"
        );

        reviewCompanies[_reviewCompanyAddress] = ReviewCompany(
            true,
            _reviewCompanyAddress
        );
        emit ReviewCompanyRegistered(_reviewCompanyAddress);
    }

    function createReview(
        string memory period,
        string memory availability
    ) public onlyRegisteredCompany {
        reviews[msg.sender] = Review(period, availability);
        emit ReviewCreated(msg.sender, period, availability);
    }

    function provideReviewResult(
        address companyAddress,
        string memory result
    ) public onlyReviewCompany reviewAvailable(companyAddress) {
        emit ReviewResultProvided(msg.sender, companyAddress, result);
    }
}
