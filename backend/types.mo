import Principal "mo:base/Principal";
import Time "mo:base/Time";

module {
    public type TokenId = Nat;
    public type EventId = Nat;
    
    public type TokenMetadata = {
        tokenId: TokenId;
        eventId: EventId;
        creator: Principal;
        metadata: ?[Nat8];
    };

    public type PaymentStatus = {
        #pending;
        #completed;
        #refunded;
        #failed;
    };

    public type EventStatus = {
        #active;
        #cancelled;
        #completed;
    };
}