import Principal "mo:base/Principal";
import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Error "mo:base/Error";
import Time "mo:base/Time";
import Hash "mo:base/Hash";
import Types "types";

shared(msg) actor class PaymentHandler() {
    private type PaymentId = Nat;
    
    private type Payment = {
        id: PaymentId;
        amount: Nat;
        from: Principal;
        to: Principal;
        timestamp: Time.Time;
        status: Types.PaymentStatus;
        refundable: Bool;
    };

    private stable var nextPaymentId: PaymentId = 0;
    private let payments = HashMap.HashMap<PaymentId, Payment>(0, Nat.equal, Hash.hash);
    private let balances = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);

    // Initialize or add funds to balance
    public shared(msg) func addFunds(amount: Nat) : async Result.Result<(), Text> {
        let caller = msg.caller;

        switch (balances.get(caller)) {
            case (null) {
                balances.put(caller, amount);
            };
            case (?currentBalance) {
                balances.put(caller, currentBalance + amount);
            };
        };
        #ok()
    };

    // Process payment
    public shared(msg) func processPayment(
        to: Principal,
        amount: Nat,
        refundable: Bool
    ) : async Result.Result<PaymentId, Text> {
        let caller = msg.caller;
        
        switch (balances.get(caller)) {
            case (null) { #err("Insufficient balance") };
            case (?balance) {
                if (balance < amount) {
                    return #err("Insufficient balance");
                };

                let newBalance = balance - amount;
                balances.put(caller, newBalance);

                switch (balances.get(to)) {
                    case (null) {
                        balances.put(to, amount);
                    };
                    case (?recipientBalance) {
                        balances.put(to, recipientBalance + amount);
                    };
                };

                let paymentId = nextPaymentId;
                nextPaymentId += 1;

                let payment: Payment = {
                    id = paymentId;
                    amount = amount;
                    from = caller;
                    to = to;
                    timestamp = Time.now();
                    status = #completed;
                    refundable = refundable;
                };

                payments.put(paymentId, payment);
                #ok(paymentId)
            };
        }
    };

    public shared(msg) func getPaymentStatus(paymentId: PaymentId) : async Result.Result<Types.PaymentStatus, Text> {
        switch (payments.get(paymentId)) {
            case (null) { #err("Payment not found") };
            case (?payment) { #ok(payment.status) };
        }
    };

    public query func getBalance(user: Principal) : async Nat {
        switch (balances.get(user)) {
            case (null) { 0 };
            case (?balance) { balance };
        }
    };
}