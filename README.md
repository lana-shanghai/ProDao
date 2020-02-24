# ProDao

Decentralized EdTech unicorn

# Description 

A smart contract to connect mentors and students in tech skills. 
Current version assumes that a user can apply to be a mentor, but in the future only existing mentors will be able to suggest a mentor. 
Mentors can vote a new mentor in by weighted majority.
Mentors list their tech skills and price per session. 
All users can suggest a new skill to learn/mentor in.

# Students

A user becomes a student after the first deposit to the contract. 
A student can place a request with a timestamp for a mentor, which the mentor can accept or reject. 
To protect from spam attacks the student has a limit to the number of requests that can be placed within a period of time. 

# Payments 

As soon as a mentor acccepts the request, they schedule a session. The student's eth or dai is locked in the contract. After the confirmation the funds are either withdrawn by the mentor or the student can challenge the session. After a session a student can mint reputation tokens and send them to the mentor.
Currently the payments happen directly, but further version will have an escrow, withdraw, and time window for challenging functionality. 

# Reputation 

The number of requests, actual sessions, received reputation tokens and upvotes on the session post-factum affect the mentor's weight.
The weighted reputation allows mentors to vote new mentors in more easily. Currently the realization is 66% of the mentors, but further development will depend on the recently active mentors. 

# Applications of ZK

Voting a mentor in or not. Sending reputation tokens to a mentor. 

# Further steps 

Payment channel between the student and mentor, record and store the session. 