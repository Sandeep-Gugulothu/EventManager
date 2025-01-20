# Event Management App

An intuitive Event Management Application designed to streamline the process of discovering, managing, and registering for events. Built with the goal of simplicity and flexibility, this app offers a responsive interface and core features to handle events effectively.

---

## Features

### 1. **Event Browsing**
- Discover events from various categories, including conferences, workshops, meetups, and social gatherings.
- Filter events based on categories and search terms to find relevant events effortlessly.

### 2. **Event Details**
- View detailed information for each event, including:
  - Event title and description
  - Date and location
  - Capacity and remaining spots
  - Registration fees

### 3. **Registration System**
- Users can register for events with a single click.
- Seamless confirmation process ensures simplicity and speed.

### 4. **Event Creation**
- Organizers can create new events by filling in key details such as title, description, date, location, category, capacity, and price.
- Categories include predefined options like "conference," "workshop," and "meetup."

### 5. **Responsive Design**
- The application is designed to work seamlessly on all screen sizes, from desktops to mobile devices.

---

## Usage of Internet Computer Protocol (ICP)
The Event Management App leverages the **Internet Computer Protocol (ICP)** to enhance functionality and scalability:

### Key ICP Features:
1. **Decentralized Hosting**
   - Events and user data are stored on a decentralized network, ensuring reliability and minimizing downtime.

2. **Scalability**
   - The app can handle a growing number of users and events without performance degradation, thanks to ICP's efficient scaling capabilities.

3. **Data Security**
   - ICP’s blockchain-based architecture ensures that event data is secure, tamper-proof, and transparent.

4. **Smart Contract Integration**
   - Event registration and ticketing processes are automated using smart contracts, enabling trustless transactions.

5. **Low Costs**
   - Hosting and running the application on ICP significantly reduce operational costs compared to traditional cloud services.

---

## Currently we only implemented the part of the idea due to time constraint there could be lot more enhancements made

---

## Contributions
Contributions are welcome! Feel free to fork the repository, create feature branches, and submit pull requests.

---

## License
This project is licensed under the MIT License.



## Prerequisites

- [DFX SDK](https://sdk.dfinity.org/docs/quickstart/local-quickstart.html) (version 0.9.0 or higher)
- [Node.js](https://nodejs.org/) (version 14 or higher)
- [Git](https://git-scm.com/)

## Project Structure

```
event-ticket-system/
├── src/
│   ├── types.mo
│   ├── payment_handler.mo
│   ├── event_manager.mo
│   └── trading.mo
├── dfx.json
└── README.md
```

## Setup Instructions

1. Clone the repository:
```bash
git clone https://github.com/your-username/event-ticket-system.git
cd event-ticket-system
```

2. Install dependencies:
```bash
npm install
```

3. Start the local Internet Computer replica:
```bash
dfx start --clean --background
```

4. Deploy the canisters:
```bash
dfx deploy
```

## Configuration

1. Update your `dfx.json`:
```json
{
  "canisters": {
    "types": {
      "main": "src/types.mo",
      "type": "motoko"
    },
    "payment_handler": {
      "main": "src/payment_handler.mo",
      "type": "motoko"
    },
    "event_manager": {
      "main": "src/event_manager.mo",
      "type": "motoko"
    },
    "trading": {
      "main": "src/trading.mo",
      "type": "motoko"
    }
  },
  "defaults": {
    "build": {
      "packtool": "vessel sources",
      "args": ""
    }
  },
  "networks": {
    "local": {
      "bind": "127.0.0.1:8000",
      "type": "ephemeral"
    }
  },
  "version": 1
}
```

2. After deployment, update the canister IDs in the code:
   - Note the canister IDs from the deployment output
   - Update the actor references in `trading.mo` and `event_manager.mo`

## Usage Examples

### Creating an Event

```motoko
// Create a new event
let event_result = await event_manager.createEvent(
    "Concert 2025",
    "Annual summer concert",
    Time.now() + 7 * 24 * 60 * 60 * 1000000000, // 7 days from now
    1000, // total tickets
    100 // base price
);
```

### Purchasing Tickets

```motoko
// Purchase a ticket
let purchase_result = await event_manager.purchaseTicket(eventId);

// Batch purchase
let batch_result = await event_manager.batchPurchaseTickets(eventId, 5);
```

### Reselling Tickets

```motoko
// List ticket for resale
let listing_result = await trading.listTicketForResale(tokenId, eventId, 150);

// Purchase resale ticket
let resale_purchase = await trading.purchaseResaleTicket(tokenId);
```

## Testing

1. Run the test suite:
```bash
dfx test
```

2. Test specific functionality:
```bash
dfx canister call event_manager createEvent '(record { name = "Test Event"; description = "Test Description"; date = 1735689600000000000; totalTickets = 100; basePrice = 50 })'
```

## Intercanister Communication

The system uses actor interfaces for communication between canisters:
- Event Manager ↔ Payment Handler
- Trading System ↔ Event Manager
- Trading System ↔ Payment Handler

## Security Considerations

- All financial transactions are handled by the Payment Handler
- Ticket ownership is verified before transfers
- Event status is checked before operations
- Payment verification is required for all purchases

## Troubleshooting

Common issues and solutions:

1. **Deployment Failures**
   ```bash
   dfx stop
   dfx start --clean --background
   dfx deploy
   ```

2. **Canister ID Issues**
   - Verify canister IDs in the code match deployed canisters
   - Check `dfx.json` configuration

3. **Payment Processing Errors**
   - Ensure sufficient balance in payment handler
   - Verify proper principal IDs

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/new-feature`
3. Commit your changes: `git commit -am 'Add new feature'`
4. Push to the branch: `git push origin feature/new-feature`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the GitHub repository or contact the development team.
