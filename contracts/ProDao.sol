pragma solidity ^0.6.0;

import "./SafeMath.sol";

contract Prodao {
    
    using SafeMath for uint256;
    using SafeMath for uint8;

    /*
    EVENTS 
    */
    event MentorAdded(address newMentorAddress);
    event Withdraw(address indexed userAddress, uint256 amount);
    event ProposeSession(address indexed studentKey, address indexed mentorKey, uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute);
    event AcceptSession(address indexed mentorKey, address indexed studentKey);
    event DeclineSession(address indexed mentorKey, address indexed studentKey);
    event ConfirmSession(address indexed studentKey, address token, string ipfsHash);
    event Deposit(address sender, uint amount);
    event SubmitVote(address indexed mentorKey, address newMentor, uint8 vote);
    
    
    struct Mentor {
        bool isMentor; // is always true for every mentor since (s)he has been voted in
        uint256 gratitudeTokens; // the gratitude tokens sent by students for each skill the mentor helps in
        bool[1] skills; // list of skills [frontendDev, backendDev, dataScience, blockchainDev, smartContracts, QA, etc] the mentor offers
        uint256 priceSession; // price per one session 
        uint256 sessionsTotal; // total number of sessions the mentor had
    }
    
    struct Student {
        bool isStudent;
        uint256 effort;
        bool[1] skills; // list of skills the student is working on 
        uint256 sessionsTotal; // total number of sessions the student had
    }
    
    struct MentorProposal {
        bool exists;
        address newMentor; // applying mentor
        uint256 yesVotes; // number of yes votes for the mentor
        uint256 noVotes; // number of no votes for the mentor
        bool result; // default false, becomes true if > 66% of existing mentors vote the new mentor in, or yesVotes / noVotes > 2
        string mentorInformation; // information on this mentor
        mapping(address => Vote) mentorVotes; // the mapping of mentors to their votes on this mentor
    }

    enum Vote {
        Null, // default value if mentor did not vote 
        Yes,
        No
    }
    
    mapping(address => Mentor) public mentors; // existing mentors
    mapping(address => Student) public students; // existing students
    mapping (address => uint256) public balances; // balances of all users
    mapping(address => MentorProposal) public newMentors; // users who applied to become members but are still being voted in

    address[] public mentorList;

    modifier onlyStudent {
        require(students[msg.sender].isStudent == true, "not a student");
        _;
    }

    modifier onlyMentor {
        require(mentors[msg.sender].isMentor == true, "not a mentor");
        _;
    }
    
    
    constructor() public {
        // address firstAddress = 0x24aA0566Fc4a75a740A0BC5fCB1509d6621932D0;
        // require(!mentors[msg.sender].isMentor, "first mentor already created");
        mentors[msg.sender] = Mentor(true, 1, [false], 1, 1);
        mentorList.push(msg.sender);
    }
    
    // deposit some money into the balance in order to become a student
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
        balances[msg.sender] = balances[msg.sender] + msg.value;
        students[msg.sender] = Student(true, 0, [false], 0);
    }
    
    function studentDeposit(address newStudent) external payable {
        require(msg.value > 0.1 ether);
        emit Deposit(newStudent, msg.value);
        balances[newStudent] = balances[newStudent] + msg.value;
        students[newStudent] = Student(true, 0, [false], 0);
    }
    
    // the mentor can change their price per session 
    function changePriceSession(address mentorKey, uint256 newPrice) external onlyMentor {
        require(msg.sender == mentorKey, "the calling address is not the same as the mentor changing the price");
        Mentor storage mentor = mentors[mentorKey];
        mentor.priceSession = newPrice;
    }
    
    
    function paySession(address payable mentorKey, address studentKey, uint256 sessions) external onlyStudent payable {
        require(msg.sender == studentKey, "the calling address is not the same as the student paying for the session");
        require(mentors[mentorKey].isMentor, "the receiving address is not an existing mentor");
        require(balances[studentKey] >= mentors[mentorKey].priceSession * sessions);
        balances[studentKey] = balances[studentKey] - mentors[mentorKey].priceSession * sessions;
        mentorKey.transfer(mentors[mentorKey].priceSession * sessions);
    }
    
    // for each executed session the student can send between zero and ten tokens to the mentor as gratitude 
    function mintGratitudeTokens(address studentKey, address mentorKey, uint256 amountGratitudeTokens) external onlyStudent {
        require(msg.sender == studentKey);
        require(amountGratitudeTokens <= 10);
        mentors[mentorKey].gratitudeTokens.add(amountGratitudeTokens);
    }
    
    // the results of the mentors vote returns true if the number of yes votes is at least two times more than no votes 
    function _getMentorVote(address newMentor) internal returns (bool mentorVote) {
        MentorProposal memory mentorProposal = newMentors[newMentor];

        if (mentorProposal.yesVotes * 100 > mentorList.length * 66) {
            mentorVote = true;
        } else {
            mentorVote = false;
        }
    
        return mentorVote;
    }
    
    function applyMentor(address applicant, string memory information) public {
        require(msg.sender == applicant, "the address of the caller of the function is not the same as the applicant's address");
        require(!mentors[applicant].isMentor, "mentor already voted in");
        require(!newMentors[applicant].exists, "mentor already applied");
        newMentors[applicant] = MentorProposal(true, applicant, 0, 0, false, information);
    }
    
    function submitVote(address newMentor, uint8 mentorVote) public onlyMentor {
        address mentorAddress = msg.sender;
        Mentor storage mentor = mentors[mentorAddress];
        
        require(!mentors[newMentor].isMentor, "mentor already voted in");
        require(newMentors[newMentor].exists, "mentor did not apply");
        MentorProposal storage mentorProposal = newMentors[newMentor];
        
        require(mentorVote <= 2, "0 for Null, 1 for Yes, 2 for No");
        Vote vote = Vote(mentorVote);
    
        require(mentorProposal.mentorVotes[mentorAddress] == Vote.Null, "mentor has already voted");
        require(vote == Vote.Yes || vote == Vote.No, "vote must be either yes or no");
    
        mentorProposal.mentorVotes[mentorAddress] = vote;
    
        if (vote == Vote.Yes) {
            mentorProposal.yesVotes = mentorProposal.yesVotes.add(1);
    
        } else if (vote == Vote.No) {
            mentorProposal.noVotes = mentorProposal.noVotes.add(1);
        }
     
        emit SubmitVote(msg.sender, mentorAddress, mentorVote);
        
        mentorProposal.result = _getMentorVote(newMentor);
        
        if (mentorProposal.result == true) {
            
            // create new mentor if after the last vote his share of yes votes from existing mentors surpassed 66% 
            mentors[newMentor] = Mentor(true, 0, [false], 0, 0);
            mentorList.push(newMentor);
            emit MentorAdded(newMentor);
        }
    }
    
    function getMentorsNumber() public view returns (uint256) {
        return mentorList.length;
    }
       
}