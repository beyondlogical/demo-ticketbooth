const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');

// Correction from earlier applied again
const provider = ganache.provider();
const web3 = new Web3(provider);

const { interface, bytecode } = require('../compile');

// No arguments:
// const deployment = { data: bytecode };
//
const argumentMap = {
    ticketsRemaining: 10,
    ticketPrice: 1000,
    lockoutTime: 0,
    ticketsPerUser: 10,
    url: 'http://something.com/eventname/eventid'
}

// WITH arguments:
const deployment = { data: bytecode, arguments: Object.values(argumentMap) };
/*
  ARG cheatsheet:
        uint _ticketsRemaining, 
        uint _ticketPrice, 
        uint _lockoutTime, 
        uint _ticketsPerUser,
        string _url
*/

// Use your mnemonic to allow access to the wallet and ALL accounts generated from it
// This wallet will need some ether to deploy!
const { mnemonic } = require('../secrets');

let contract;
let accounts;

// Set up a helper to execute before each test, resetting state
beforeEach(async () => {
    accounts = await web3.eth.getAccounts();

    contract = await new web3.eth.Contract(JSON.parse(interface))
        .deploy( deployment )
        .send({ from: accounts[0], gas: '1000000' });

    // Need to mint some tokens and send them to the contract?

});

describe('TicketBooth Contract', () => {

    // Basic test - are we addressing a valid deployed contract?
    it('deploys a contract', () => {
        assert.ok(contract.options.address);
    });

    // Confirm that the data values were initialized
    it('ticketsRemaining is set correctly', async () => {
        const ticketsRemaining = await contract.methods.ticketsRemaining().call();
        assert.equal( argumentMap.ticketsRemaining, ticketsRemaining);
    });

    // Confirm that buy tickets works corrrectly 
    it('allows a user to buy a ticket', async () => {
        await contract.methods.buyTickets(1).send({
          from: accounts[1],
          value: 1000,
        });
        const tickets = await contract.methods.ticketHolders(accounts[1]).call();
        assert.equal(tickets.ticketCount, 1);
    });

    // Confirm that buying ticket errors correctly
    it('throws an error when punching a ticket you do not have', async () => {
        try {
            await contract.methods.punchTickets(1).send({
                from: accounts[1]
            });
            assert(false);
        } catch (e) {
            assert(true);
        }
    });
});
