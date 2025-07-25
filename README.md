# Knowledge Graph Marketplace

A decentralized marketplace for trading structured knowledge and data insights built on the Stacks blockchain using Clarity smart contracts.

## Overview

The Knowledge Graph Marketplace enables users to buy, sell, and trade structured knowledge graphs and data insights in a trustless, decentralized environment. Users can monetize their data expertise while others can access valuable insights for their projects.

## Features

### Core Functionality
- **Knowledge Graph Listing**: Users can list their knowledge graphs with metadata, pricing, and categorization
- **Secure Purchasing**: STX-based payment system with automatic fee distribution
- **Access Control**: Granular permissions for purchased content
- **Rating System**: Community-driven quality assessment through reviews and ratings
- **User Profiles**: Reputation tracking and user statistics

### Smart Contract Features
- **Marketplace Fee**: 2.5% marketplace fee on all transactions
- **Data Integrity**: Content verification through hash validation
- **Search & Discovery**: Categorization and tagging system
- **Admin Controls**: Marketplace management and configuration

## Technical Specifications

### Contract Structure
- **Data Storage**: Maps for knowledge graphs, user profiles, purchases, reviews, and permissions
- **Error Handling**: Comprehensive error codes for all edge cases
- **Event Logging**: Transaction logging for off-chain indexing
- **Security**: Owner-based access controls and input validation

### Key Functions
- `list-knowledge-graph`: List new knowledge for sale
- `purchase-knowledge-graph`: Buy access to knowledge graphs
- `add-review`: Rate and review purchased content
- `create-user-profile`: Set up marketplace profile
- `update-knowledge-graph`: Modify existing listings

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Git
- Visual Studio Code (recommended)

### Installation
1. Clone the repository
2. Navigate to the project directory
3. Run `clarinet check` to validate the contract
4. Use `clarinet console` for interactive testing

## Contract Deployment

The contract can be deployed to:
- **Devnet**: For local development and testing
- **Testnet**: For pre-production testing
- **Mainnet**: For production deployment

## Usage Examples

### Listing a Knowledge Graph
```clarity
(contract-call? .knowledge-graph-marketplace list-knowledge-graph
  "ML Model Training Dataset"
  "Comprehensive dataset for machine learning model training with 100k samples"
  "Machine Learning"
  u1000000
  "sha256hash..."
  (some "https://metadata-uri.com")
  (list "ml" "dataset" "training")
)
```

### Purchasing Knowledge
```clarity
(contract-call? .knowledge-graph-marketplace purchase-knowledge-graph u1)
```

### Adding a Review
```clarity
(contract-call? .knowledge-graph-marketplace add-review u1 u5 "Excellent dataset, very comprehensive!")
```

## Security Considerations

- All transactions are atomic and fail-safe
- Input validation on all user-provided data
- Owner-only administrative functions
- Proper access control for purchased content

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Contact

For questions or support, please open an issue in the GitHub repository.

---

**Note**: This is a smart contract project. Always test thoroughly on devnet/testnet before mainnet deployment.