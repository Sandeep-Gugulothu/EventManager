import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Int "mo:base/Int";

actor EventManagement {
    // Types
    type EventId = Text;
    
    type Event = {
        id: EventId;
        creator: Principal;
        title: Text;
        description: Text;
        date: Time.Time;
        location: Text;
        category: Text;
        capacity: Nat;
        price: Nat;
        imageUrl: Text;
        registeredUsers: [Principal];
        isActive: Bool;
        createdAt: Time.Time;
    };

    type User = {
        id: Principal;
        subscribedEvents: [EventId];
        createdEvents: [EventId];
        registeredEvents: [EventId];
        profile: UserProfile;
    };

    type UserProfile = {
        username: Text;
        email: Text;
        createdAt: Time.Time;
    };

    // Stable storage
    private stable var eventEntries: [(EventId, Event)] = [];
    private stable var userEntries: [(Principal, User)] = [];

    // Runtime state
    private var events = HashMap.HashMap<EventId, Event>(0, Text.equal, Text.hash);
    private var users = HashMap.HashMap<Principal, User>(0, Principal.equal, Principal.hash);

    // System functions for upgrades
    system func preupgrade() {
        eventEntries := Iter.toArray(events.entries());
        userEntries := Iter.toArray(users.entries());
    };

    system func postupgrade() {
        for ((k, v) in eventEntries.vals()) { events.put(k, v) };
        for ((k, v) in userEntries.vals()) { users.put(k, v) };
    };

    // User Management
    public shared(msg) func createProfile(username: Text, email: Text) : async Result.Result<(), Text> {
        let caller = msg.caller;
        if (Principal.isAnonymous(caller)) return #err("Anonymous principals cannot create profiles");

        let newUser : User = {
            id = caller;
            subscribedEvents = [];
            createdEvents = [];
            registeredEvents = [];
            profile = {
                username = username;
                email = email;
                createdAt = Time.now();
            };
        };

        users.put(caller, newUser);
        #ok(())
    };

    // Event Management
    public shared(msg) func createEvent(
        title: Text,
        description: Text,
        date: Time.Time,
        location: Text,
        category: Text,
        capacity: Nat,
        price: Nat,
        imageUrl: Text
    ) : async Result.Result<EventId, Text> {
        let caller = msg.caller;
        if (Principal.isAnonymous(caller)) return #err("Anonymous principals cannot create events");

        let eventId = generateEventId(title, Time.now());
        let newEvent : Event = {
            id = eventId;
            creator = caller;
            title = title;
            description = description;
            date = date;
            location = location;
            category = category;
            capacity = capacity;
            price = price;
            imageUrl = imageUrl;
            registeredUsers = [];
            isActive = true;
            createdAt = Time.now();
        };

        events.put(eventId, newEvent);

        // Update user's created events
        switch (users.get(caller)) {
            case (?user) {
                let updatedUser = {
                    user with
                    createdEvents = Array.append(user.createdEvents, [eventId])
                };
                users.put(caller, updatedUser);
            };
            case null { };
        };

        #ok(eventId)
    };

    public shared(msg) func registerForEvent(eventId: EventId) : async Result.Result<(), Text> {
        let caller = msg.caller;
        if (Principal.isAnonymous(caller)) return #err("Anonymous principals cannot register for events");

        switch (events.get(eventId)) {
            case (?event) {
                if (event.registeredUsers.size() >= event.capacity) {
                    return #err("Event is at full capacity");
                };

                if (Array.find<Principal>(event.registeredUsers, func(p) { p == caller }) != null) {
                    return #err("Already registered for this event");
                };

                let updatedEvent = {
                    event with
                    registeredUsers = Array.append(event.registeredUsers, [caller])
                };
                events.put(eventId, updatedEvent);

                // Update user's registered events
                switch (users.get(caller)) {
                    case (?user) {
                        let updatedUser = {
                            user with
                            registeredEvents = Array.append(user.registeredEvents, [eventId])
                        };
                        users.put(caller, updatedUser);
                    };
                    case null { };
                };

                #ok(())
            };
            case null { #err("Event not found") };
        }
    };

    // Query functions
    public query func getAllEvents() : async [Event] {
        Iter.toArray(events.vals())
    };

    public query func getEvent(eventId: EventId) : async Result.Result<Event, Text> {
        switch (events.get(eventId)) {
            case (?event) { #ok(event) };
            case null { #err("Event not found") };
        }
    };

    public query func getUserProfile(userId: Principal) : async Result.Result<User, Text> {
        switch (users.get(userId)) {
            case (?user) { #ok(user) };
            case null { #err("User not found") };
        }
    };

    public query func getEventsByCategory(category: Text) : async [Event] {
        let matching = Buffer.Buffer<Event>(0);
        for (event in events.vals()) {
            if (event.category == category) {
                matching.add(event);
            };
        };
        Buffer.toArray(matching)
    };

    // Helper functions
    private func generateEventId(title: Text, timestamp: Time.Time) : EventId {
        Text.concat(title, Int.toText(timestamp))
    };
}