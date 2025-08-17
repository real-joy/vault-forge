# VaultForge Protocol

[![License](https://img.shields.io/badge/license-ISC-blue.svg)](LICENSE)
[![Clarity Version](https://img.shields.io/badge/clarity-3.0-orange.svg)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/stacks-blockchain-purple.svg)](https://stacks.org/)

## Overview

VaultForge is a next-generation decentralized portfolio coordination protocol designed for Bitcoin Layer 2 ecosystems. It empowers users to design resilient, multi-asset strategies that adapt to market dynamics while preserving full custody and trustless execution.

## Vision

Rather than leaving portfolio management to centralized platforms, VaultForge enables self-sovereign asset allocation, dynamic rebalancing, and granular risk control - all powered by the security foundation of Bitcoin.

Just as a forge transforms raw material into strong alloys, VaultForge transforms fragmented assets into a cohesive, optimized portfolio. It's tailored for DeFi users seeking both simplicity and institutional-grade sophistication.

## Core Features

- **🏗️ Diverse Portfolios**: Create portfolios with up to 10 different tokens
- **⚖️ Automated Rebalancing**: Smart rebalancing based on user-defined triggers
- **🎯 Precision Allocation**: Target percentage allocation with validation
- **📊 On-chain Tracking**: Complete portfolio history and performance monitoring
- **💰 Transparent Fees**: Clear fee structure for sustainable operations
- **🔒 Robust Security**: Comprehensive error handling for secure interactions

## Architecture

### Smart Contract Structure

```text
VaultForge Protocol
├── Data Variables
│   ├── protocol-owner
│   ├── portfolio-counter
│   └── protocol-fee (0.25%)
├── Data Maps
│   ├── Portfolios (portfolio metadata)
│   ├── PortfolioAssets (asset allocations)
│   └── UserPortfolios (user-portfolio mapping)
└── Functions
    ├── Read-Only Functions
    ├── Public Functions
    └── Private Functions
```

### Key Constants

- **MAX_TOKENS_PER_PORTFOLIO**: 10 tokens maximum per portfolio
- **BASIS_POINTS**: 10,000 (for percentage calculations)
- **REBALANCE_THRESHOLD**: ~24 hours (144 blocks)

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (v16 or higher)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/real-joy/vault-forge.git
   cd vault-forge
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Check contract syntax**

   ```bash
   clarinet check
   ```

### Development

#### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage and cost analysis
npm run test:report

# Watch mode for continuous testing
npm run test:watch
```

#### Contract Deployment

```bash
# Deploy to testnet
clarinet deploy --testnet

# Deploy to mainnet (ensure proper configuration)
clarinet deploy --mainnet
```

## API Reference

### Public Functions

#### `create-portfolio`

Creates a new portfolio with specified tokens and allocations.

```clarity
(create-portfolio (initial-tokens (list 10 principal)) (percentages (list 10 uint)))
```

**Parameters:**

- `initial-tokens`: List of token contract addresses (max 10)
- `percentages`: Corresponding allocation percentages in basis points

**Returns:** `(response uint uint)` - Portfolio ID on success

**Example:**

```clarity
(contract-call? .vault-forge create-portfolio 
  (list 'SP1H1733V5MZ3SZ9XRW9FKYGEZT0JDGEB8Y634C7R.ststx-token 
        'SP3DX3H4FEYZJZ586MFBS25ZW3HZDMEW92260R2PR.Wrapped-Bitcoin)
  (list u5000 u5000)) ;; 50% each
```

#### `rebalance-portfolio`

Triggers rebalancing for a portfolio.

```clarity
(rebalance-portfolio (portfolio-id uint))
```

#### `update-portfolio-allocation`

Updates the target allocation for a specific asset.

```clarity
(update-portfolio-allocation (portfolio-id uint) (token-id uint) (new-percentage uint))
```

### Read-Only Functions

#### `get-portfolio`

Retrieves portfolio information.

```clarity
(get-portfolio (portfolio-id uint))
```

#### `get-portfolio-asset`

Gets specific asset information within a portfolio.

```clarity
(get-portfolio-asset (portfolio-id uint) (token-id uint))
```

#### `get-user-portfolios`

Returns all portfolio IDs for a user.

```clarity
(get-user-portfolios (user principal))
```

#### `calculate-rebalance-amounts`

Calculates if a portfolio needs rebalancing.

```clarity
(calculate-rebalance-amounts (portfolio-id uint))
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `ERR-NOT-AUTHORIZED` | Caller not authorized for this action |
| 101 | `ERR-INVALID-PORTFOLIO` | Portfolio doesn't exist or is inactive |
| 102 | `ERR-INSUFFICIENT-BALANCE` | Insufficient balance for operation |
| 103 | `ERR-INVALID-TOKEN` | Invalid token address or configuration |
| 104 | `ERR-REBALANCE-FAILED` | Rebalancing operation failed |
| 105 | `ERR-PORTFOLIO-EXISTS` | Portfolio already exists |
| 106 | `ERR-INVALID-PERCENTAGE` | Invalid percentage value |
| 107 | `ERR-MAX-TOKENS-EXCEEDED` | Exceeded maximum tokens per portfolio |
| 108 | `ERR-LENGTH-MISMATCH` | Token and percentage lists length mismatch |
| 109 | `ERR-USER-STORAGE-FAILED` | Failed to update user portfolio storage |
| 110 | `ERR-INVALID-TOKEN-ID` | Invalid token ID for portfolio |

## Usage Examples

### Creating a Balanced Portfolio

```clarity
;; Create a 3-token portfolio: 40% STX, 30% Bitcoin, 30% USDC
(contract-call? .vault-forge create-portfolio
  (list 'SP1H1733V5MZ3SZ9XRW9FKYGEZT0JDGEB8Y634C7R.ststx-token
        'SP3DX3H4FEYZJZ586MFBS25ZW3HZDMEW92260R2PR.Wrapped-Bitcoin
        'SP3DX3H4FEYZJZ586MFBS25ZW3HZDMEW92260R2PR.token-usdc)
  (list u4000 u3000 u3000))
```

### Rebalancing a Portfolio

```clarity
;; Rebalance portfolio with ID 1
(contract-call? .vault-forge rebalance-portfolio u1)
```

### Checking Portfolio Status

```clarity
;; Get portfolio information
(contract-call? .vault-forge get-portfolio u1)

;; Check if rebalancing is needed
(contract-call? .vault-forge calculate-rebalance-amounts u1)
```

## Testing

The project includes comprehensive test suites using Vitest and the Clarinet SDK:

```typescript
// Example test structure
describe("VaultForge Protocol", () => {
  it("should create portfolio successfully", () => {
    // Test implementation
  });
  
  it("should handle rebalancing correctly", () => {
    // Test implementation
  });
});
```

## Security Considerations

### Access Control

- Only portfolio owners can modify their portfolios
- Protocol owner has administrative privileges
- All functions include proper authorization checks

### Validation

- Percentage allocations must sum to 100% (10,000 basis points)
- Maximum of 10 tokens per portfolio
- Input validation on all parameters

### Error Handling

- Comprehensive error codes for debugging
- Safe unwrapping of optional values
- Graceful failure modes

## Fee Structure

- **Protocol Fee**: 0.25% (25 basis points)
- Fees are collected on rebalancing operations
- Transparent and predictable cost structure

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Clarity best practices
- Include comprehensive tests for new features
- Update documentation for API changes
- Ensure all tests pass before submitting

## Roadmap

- [ ] **V1.0**: Core portfolio management functionality
- [ ] **V1.1**: Advanced rebalancing strategies
- [ ] **V1.2**: Integration with external price oracles
- [ ] **V2.0**: Cross-chain asset support
- [ ] **V2.1**: Automated yield farming integration
- [ ] **V3.0**: DAO governance implementation

## License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on [Stacks](https://stacks.org/) blockchain
- Developed with [Clarinet](https://github.com/hirosystems/clarinet)
- Inspired by the Bitcoin DeFi ecosystem
