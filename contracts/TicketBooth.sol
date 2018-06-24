pragma solidity ^0.4.24;
/*
 * @title TicketBooth Application
 * 
 * User Roles:
 *  - Ticket Master
 *  - User
 *
 * User Stories:
 *  - Ticket Master can: 
 *      - set the number of tickets for sale to an event
 *      - set the price of tickets for sale to an event
 *      - set the number of tickets that can be bought (maximum)
 *      - set a lockout time/ticket availability timeframe
 *      - set a url that points to details
 *      - punch redeemed tickets
 *
 *  - Ticket Holder can:
 *      - can buy a ticket
 *      - redeem a ticket
 *      - view ticket wallet (number of tickets/ticket amount/how many are left/ticket details)
 *      - check ticket status
 *      - must burn ticket upon entry to event
 *  
 *  - Non Ticket Holder can:
 *      - cannot view ticket wallet (number of tickets/ticket amount/how many are left/ticket details)
 *      - can buy a ticket
 *
 */
 
 contract TicketBooth {
     
    uint public ticketsRemaining;
    uint public ticketPrice;
    string public url;
    uint public lockoutTime;
    uint public ticketsPerUser;
    
    struct ticketHolder {
        uint ticketCount;
        uint ticketsPunched;
    }
    
    address ticketMaster;
    
    mapping (address => ticketHolder) public ticketHolders;
    
    constructor(
        uint _ticketsRemaining, 
        uint _ticketPrice, 
        uint _lockoutTime, 
        uint _ticketsPerUser,
        string _url
    ) public {
       /* set up state */ 
       
       ticketMaster = msg.sender;
       ticketsRemaining = _ticketsRemaining;
       ticketPrice = _ticketPrice;
       lockoutTime = _lockoutTime;
       ticketsPerUser = _ticketsPerUser;
       url = _url;

    }
    
    /* allows the user to buy a ticket*/
    function buyTickets (
        uint numberOfTickets
    )
        public
        payable
    {
        // Ensure there are some tickets being bought
        require (numberOfTickets > 0);
        // Don't buy more tickets than exist
        require (ticketsRemaining >= numberOfTickets);
        // Don't buy more tickets than per user cap
        require (ticketHolders[msg.sender].ticketCount + numberOfTickets <= ticketsPerUser);
        // Check they sent enough ether along to buy
        
        require (numberOfTickets * ticketPrice <= msg.value);
        
        // Increase ticketHolder's count
        ticketHolders[msg.sender].ticketCount += numberOfTickets; // Overflow not possible, tickets remaining bounds this
        ticketsRemaining -= numberOfTickets; // Underflow protected by require statement
        
        // Give user their change back after the state changes ^^
        uint _change = msg.value - (numberOfTickets * ticketPrice);
        msg.sender.transfer(_change);  // kicks off an external call - must ensure no draining callback
        
        // Send the ticketMaster their money.
        ticketMaster.transfer(address(this).balance);
    }
    
    /* marking the ticket as used */
    function punchTickets (uint numberOfPunches) public {
           
        // Make sure they are not punching more tickets than they own
        require(ticketHolders[msg.sender].ticketCount >= numberOfPunches + ticketHolders[msg.sender].ticketsPunched);
        
        ticketHolders[msg.sender].ticketsPunched += numberOfPunches;
        
    }
 }
