// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title TRUST CHAIN - Reputation Scoring Platform for Freelance Professionals
 * @dev Smart contract for managing freelancer reputation scores and reviews
 * @author TRUST CHAIN Development Team
 */
contract Project {
    
    // Struct to store freelancer profile information
    struct FreelancerProfile {
        address freelancerAddress;
        string name;
        string skills;
        uint256 totalScore;
        uint256 reviewCount;
        uint256 completedProjects;
        bool isActive;
        uint256 registrationTime;
    }
    
    // Struct to store review information
    struct Review {
        address client;
        address freelancer;
        uint256 projectId;
        uint8 rating; // 1-5 stars
        string comment;
        uint256 timestamp;
        bool isVerified;
    }
    
    // State variables
    mapping(address => FreelancerProfile) public freelancers;
    mapping(uint256 => Review) public reviews;
    mapping(address => mapping(address => bool)) public hasReviewed;
    
    address[] public freelancerList;
    uint256 public reviewCounter;
    address public owner;
    
    // Events
    event FreelancerRegistered(address indexed freelancer, string name);
    event ReviewSubmitted(address indexed client, address indexed freelancer, uint8 rating, uint256 reviewId);
    event ScoreUpdated(address indexed freelancer, uint256 newScore);
    event ProfileUpdated(address indexed freelancer, string newSkills);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyRegisteredFreelancer() {
        require(freelancers[msg.sender].isActive, "Only registered freelancers can call this function");
        _;
    }
    
    modifier validRating(uint8 _rating) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        reviewCounter = 0;
    }
    
    /**
     * @dev Register a new freelancer on the platform
     * @param _name Freelancer's display name
     * @param _skills Comma-separated list of skills
     */
    function registerFreelancer(string memory _name, string memory _skills) external {
        require(!freelancers[msg.sender].isActive, "Freelancer already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        
        freelancers[msg.sender] = FreelancerProfile({
            freelancerAddress: msg.sender,
            name: _name,
            skills: _skills,
            totalScore: 0,
            reviewCount: 0,
            completedProjects: 0,
            isActive: true,
            registrationTime: block.timestamp
        });
        
        freelancerList.push(msg.sender);
        
        emit FreelancerRegistered(msg.sender, _name);
    }
    
    /**
     * @dev Submit a review for a freelancer
     * @param _freelancer Address of the freelancer being reviewed
     * @param _projectId Unique project identifier
     * @param _rating Rating from 1 to 5 stars
     * @param _comment Review comment
     */
    function submitReview(
        address _freelancer,
        uint256 _projectId,
        uint8 _rating,
        string memory _comment
    ) external validRating(_rating) {
        require(freelancers[_freelancer].isActive, "Freelancer not registered");
        require(!hasReviewed[msg.sender][_freelancer], "You have already reviewed this freelancer");
        require(msg.sender != _freelancer, "Cannot review yourself");
        
        reviewCounter++;
        
        reviews[reviewCounter] = Review({
            client: msg.sender,
            freelancer: _freelancer,
            projectId: _projectId,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp,
            isVerified: false
        });
        
        hasReviewed[msg.sender][_freelancer] = true;
        
        // Update freelancer's score and stats
        freelancers[_freelancer].totalScore += _rating;
        freelancers[_freelancer].reviewCount++;
        freelancers[_freelancer].completedProjects++;
        
        emit ReviewSubmitted(msg.sender, _freelancer, _rating, reviewCounter);
        emit ScoreUpdated(_freelancer, calculateReputationScore(_freelancer));
    }
    
    /**
     * @dev Calculate the reputation score for a freelancer
     * @param _freelancer Address of the freelancer
     * @return Calculated reputation score (0-100)
     */
    function calculateReputationScore(address _freelancer) public view returns (uint256) {
        FreelancerProfile memory profile = freelancers[_freelancer];
        
        if (profile.reviewCount == 0) {
            return 0;
        }
        
        // Base score calculation (average rating * 20 to get scale 0-100)
        uint256 baseScore = (profile.totalScore * 20) / profile.reviewCount;
        
        // Bonus for number of completed projects (max 10 points)
        uint256 projectBonus = profile.completedProjects > 50 ? 10 : (profile.completedProjects * 10) / 50;
        
        // Bonus for account age (max 5 points)
        uint256 ageBonus = block.timestamp > profile.registrationTime + 365 days ? 5 : 0;
        
        uint256 finalScore = baseScore + projectBonus + ageBonus;
        return finalScore > 100 ? 100 : finalScore;
    }
    
    /**
     * @dev Update freelancer's skills
     * @param _newSkills Updated skills string
     */
    function updateSkills(string memory _newSkills) external onlyRegisteredFreelancer {
        freelancers[msg.sender].skills = _newSkills;
        emit ProfileUpdated(msg.sender, _newSkills);
    }
    
    /**
     * @dev Get freelancer profile information
     * @param _freelancer Address of the freelancer
     * @return FreelancerProfile struct with all profile data
     */
    function getFreelancerProfile(address _freelancer) external view returns (FreelancerProfile memory) {
        require(freelancers[_freelancer].isActive, "Freelancer not found");
        return freelancers[_freelancer];
    }
    
    // View functions
    function getTotalFreelancers() external view returns (uint256) {
        return freelancerList.length;
    }
    
    function getTotalReviews() external view returns (uint256) {
        return reviewCounter;
    }
    
    function getReview(uint256 _reviewId) external view returns (Review memory) {
        require(_reviewId > 0 && _reviewId <= reviewCounter, "Invalid review ID");
        return reviews[_reviewId];
    }
}
