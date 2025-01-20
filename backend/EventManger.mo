import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Time "mo:base/Time";
import Error "mo:base/Error";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Hash "mo:base/Hash";
import Types "types";

shared(msg) actor class EventManager() {
    private type TokenId = Types.TokenId;
    private type EventId = Types.EventId;
    
    private type Event = {
        id: EventId;
        name: Text;
        description: Text;
        date: Time.Time;
        totalTickets: Nat;
        ticketsRemaining: Nat;
        basePrice: Nat;
        owner: Principal;
        status: Types.EventStatus;
    };

    private type Ticket = {
        eventId: EventId;
        tokenId: TokenId;
        owner: Principal;
        metadata: ?[Nat8];
    };

    private stable var nextEventId: EventId = 0;
    private stable var nextTokenId: TokenId = 0;
    
    private let events = HashMap.HashMap<EventId, Event>(0, Nat.equal, Hash.hash);
    private let tickets = HashMap.HashMap<TokenId, Ticket>(0, Nat.equal, Hash.hash);
    private let userTickets = HashMap.HashMap<Principal, Buffer.Buffer<TokenId>>(0, Principal.equal, Principal.hash);

    // Create new event
    public shared(msg) func createEvent(
        name: Text,
        description: Text,
        date: Time.Time,
        totalTickets: Nat,
        basePrice: Nat
    ) : async Result.Result<EventId, Text> {
        let caller = msg.caller;
        
        let eventId = nextEventId;
        nextEventId += 1;

        let newEvent: Event = {
            id = eventId;
            name = name;
            description = description;
            date = date;
            totalTickets = totalTickets;
            ticketsRemaining = totalTickets;
            basePrice = basePrice;
            owner = caller;
            status = #active;
        };

        events.put(eventId, newEvent);

        // Mint tickets for the event
        ignore await mintEventTickets(eventId);
        
        #ok(eventId)
    };

    private func mintEventTickets(eventId: EventId) : async Result.Result<(), Text> {
        switch (events.get(eventId)) {
            case (null) { #err("Event not found") };
            case (?event) {
                var i = 0;
                while (i < event.totalTickets) {
                    let tokenId = nextTokenId;
                    nextTokenId += 1;

                    let newTicket: Ticket = {
                        eventId = eventId;
                        tokenId = tokenId;
                        owner = event.owner;
                        metadata = null;
                    };

                    tickets.put(tokenId, newTicket);
                    i += 1;
                };
                #ok()
            };
        }
    };

    public shared(msg) func transferTicket(tokenId: TokenId, to: Principal) : async Result.Result<(), Text> {
        let caller = msg.caller;
        
        switch (tickets.get(tokenId)) {
            case (null) { #err("Ticket not found") };
            case (?ticket) {
                if (ticket.owner != caller) {
                    return #err("Not ticket owner");
                };

                let updatedTicket = {
                    ticket with
                    owner = to;
                };
                
                tickets.put(tokenId, updatedTicket);

                // Update user ticket mappings
                switch (userTickets.get(to)) {
                    case (null) {
                        let newBuffer = Buffer.Buffer<TokenId>(1);
                        newBuffer.add(tokenId);
                        userTickets.put(to, newBuffer);
                    };
                    case (?buffer) {
                        buffer.add(tokenId);
                        userTickets.put(to, buffer);
                    };
                };

                #ok()
            };
        }
    };

    public query func getTicketOwner(tokenId: TokenId) : async ?Principal {
        switch (tickets.get(tokenId)) {
            case (null) { null };
            case (?ticket) { ?ticket.owner };
        }
    };

    public query func getUserTickets(user: Principal) : async [TokenId] {
        switch (userTickets.get(user)) {
            case (null) { [] };
            case (?buffer) { Buffer.toArray(buffer) };
        }
    };
}