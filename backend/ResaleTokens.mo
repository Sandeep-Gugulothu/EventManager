import Principal "mo:base/Principal";
import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Time "mo:base/Time";
import Hash "mo:base/Hash";
import Types "types";

shared(msg) actor class TicketTrading() {
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
    
    private type ResaleTicket = {
        tokenId: TokenId;
        eventId: EventId;
        seller: Principal;
        price: Nat;
        listingTime: Time.Time;
        available: Bool;
    };

    // State variables
    private let resaleMarket = HashMap.HashMap<TokenId, ResaleTicket>(0, Nat.equal, Hash.hash);
    
    // Reference to other canisters
    private let paymentHandler = actor("payment-canister-id") : actor {
        processPayment : shared (Principal, Nat, Bool) -> async Result.Result<Nat, Text>;
        getPaymentStatus : shared Nat -> async Result.Result<Types.PaymentStatus, Text>;
    };

    private let eventManager = actor("event-canister-id") : actor {
        getTicketOwner : query (TokenId) -> async ?Principal;
        transferTicket : shared (TokenId, Principal) -> async Result.Result<(), Text>;
        getEvent : query (EventId) -> async ?Event;
    };

    // List ticket for resale
    public shared(msg) func listTicketForResale(
        tokenId: TokenId,
        eventId: EventId,
        price: Nat
    ) : async Result.Result<(), Text> {
        let caller = msg.caller;
        
        // Verify ticket ownership
        switch (await eventManager.getTicketOwner(tokenId)) {
            case (null) { #err("Ticket not found") };
            case (?owner) {
                if (owner != caller) {
                    return #err("You don't own this ticket");
                };

                let resaleTicket: ResaleTicket = {
                    tokenId = tokenId;
                    eventId = eventId;
                    seller = caller;
                    price = price;
                    listingTime = Time.now();
                    available = true;
                };

                resaleMarket.put(tokenId, resaleTicket);
                #ok()
            };
        }
    };

    // Purchase resale ticket
    public shared(msg) func purchaseResaleTicket(tokenId: TokenId) : async Result.Result<(), Text> {
        let caller = msg.caller;
        
        switch (resaleMarket.get(tokenId)) {
            case (null) { #err("Ticket not found in resale market") };
            case (?ticket) {
                if (not ticket.available) {
                    return #err("Ticket is no longer available");
                };

                // Process payment first
                switch (await paymentHandler.processPayment(ticket.seller, ticket.price, false)) {
                    case (#err(e)) { #err("Payment failed: " # e) };
                    case (#ok(paymentId)) {
                        // Verify payment completion
                        switch (await paymentHandler.getPaymentStatus(paymentId)) {
                            case (#err(e)) { #err("Payment verification failed: " # e) };
                            case (#ok(status)) {
                                if (status != #completed) {
                                    return #err("Payment not completed");
                                };

                                // Transfer ticket ownership
                                switch (await eventManager.transferTicket(tokenId, caller)) {
                                    case (#err(e)) { #err("Transfer failed: " # e) };
                                    case (#ok()) {
                                        // Update resale market
                                        let updatedTicket = {
                                            ticket with
                                            available = false;
                                        };
                                        resaleMarket.put(tokenId, updatedTicket);
                                        #ok()
                                    };
                                }
                            };
                        }
                    };
                }
            };
        }
    };

    // Cancel resale listing
    public shared(msg) func cancelResaleListing(tokenId: TokenId) : async Result.Result<(), Text> {
        let caller = msg.caller;
        
        switch (resaleMarket.get(tokenId)) {
            case (null) { #err("Ticket not found in resale market") };
            case (?ticket) {
                if (ticket.seller != caller) {
                    return #err("Only the seller can cancel the listing");
                };

                if (not ticket.available) {
                    return #err("Listing is no longer active");
                };

                resaleMarket.delete(tokenId);
                #ok()
            };
        }
    };

    // Update resale price
    public shared(msg) func updateResalePrice(
        tokenId: TokenId,
        newPrice: Nat
    ) : async Result.Result<(), Text> {
        let caller = msg.caller;
        
        switch (resaleMarket.get(tokenId)) {
            case (null) { #err("Ticket not found in resale market") };
            case (?ticket) {
                if (ticket.seller != caller) {
                    return #err("Only the seller can update the price");
                };

                if (not ticket.available) {
                    return #err("Listing is no longer active");
                };

                let updatedTicket = {
                    ticket with
                    price = newPrice;
                };
                resaleMarket.put(tokenId, updatedTicket);
                #ok()
            };
        }
    };

    // Query functions
    public query func getResaleTicket(tokenId: TokenId) : async ?ResaleTicket {
        resaleMarket.get(tokenId)
    };

    public query func getAllActiveResaleTickets() : async [ResaleTicket] {
        let buffer = Buffer.Buffer<ResaleTicket>(0);
        for ((_, ticket) in resaleMarket.entries()) {
            if (ticket.available) {
                buffer.add(ticket);
            };
        };
        Buffer.toArray(buffer)
    };

    public query func getSellerListings(seller: Principal) : async [ResaleTicket] {
        let buffer = Buffer.Buffer<ResaleTicket>(0);
        for ((_, ticket) in resaleMarket.entries()) {
            if (ticket.seller == seller and ticket.available) {
                buffer.add(ticket);
            };
        };
        Buffer.toArray(buffer)
    };
}