pragma solidity >=0.4.22 <=0.8.17;

contract EtherElection {
    address owner;

    uint constant FEE = 1 ether;
    uint8 numberOfCandidates;
    mapping(address => bool) enrolledCandidates;
    uint candidatesPot;

    uint constant VOTE_FEE = 10000 wei;
    mapping(address => bool) voted;
    mapping(address => uint8) votes;
    address winner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier enrollmentComplete() {
        require(numberOfCandidates == 3, "enrollment in progress");
        _;
    }

    modifier exactVoteFee() {
        require(msg.value == VOTE_FEE);
        _;
    }

    function enroll() public payable {
        require(numberOfCandidates < 3, "all candidates selected");
        require(!enrolledCandidates[msg.sender], "cannot enroll twice");
        require(msg.value == FEE, "enrollment fee not correct");
        numberOfCandidates++;
        enrolledCandidates[msg.sender] = true;
        candidatesPot += FEE;
    }

    function vote(address candidate) public payable enrollmentComplete() exactVoteFee() {
        require(enrolledCandidates[candidate], "candidate not enrolled");
        require(!voted[msg.sender], "vote already cast");
        require(winner == address(0), "voting is complete, there is a winner");

        votes[candidate]++;
        voted[msg.sender] = true;

        if (votes[candidate] == 5) {
            winner = candidate;
        }

    }

    function getWinner() public view returns (address) {
        require(winner != address(0), "no winner yet");
        return winner;
    }

    function claimReward() public {
        require(msg.sender == winner, "must be winner");
        require(winner != address(0), "winner not decided");
        require(candidatesPot == 3 ether, "already claimed");
        candidatesPot = 0;
        (bool sent, ) = payable(winner).call{value: 3 ether}("");
        require(sent, "claim failed");
    }

    function collectFees() public onlyOwner {
        require(candidatesPot == 0, "candidate pot not empty");
        require(winner != address(0), "winner not declared");
        selfdestruct(payable(owner));
    }
}
