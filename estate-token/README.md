# Real Estate Investment Tokenization Protocol

A comprehensive Clarity smart contract for fractional real estate investment on the Stacks blockchain, enabling investors to purchase tokenized shares of real estate properties and receive proportional rental income distributions.

## 🏢 Overview

This protocol allows for the tokenization of real estate properties, enabling fractional ownership through fungible tokens. Investors can purchase property tokens representing ownership shares and receive rental income distributions proportional to their holdings.

### Key Features

- **Fractional Ownership**: Properties are divided into tokens representing ownership shares
- **Rental Income Distribution**: Automated distribution of rental income to token holders
- **Property Management**: Comprehensive property lifecycle management
- **Secondary Markets**: Support for token trading between investors
- **Transparent Financials**: Real-time tracking of property performance and income
- **Multi-Property Support**: Single contract managing multiple properties

## 🏗️ Architecture

### Core Components

1. **Property Management**: Creation, funding, and lifecycle management of properties
2. **Investment System**: Token-based investment with STX transfers
3. **Income Distribution**: Rental income collection and dividend distribution
4. **Financial Tracking**: Comprehensive property financials and performance metrics
5. **Secondary Market**: Token trading infrastructure

### Property Lifecycle

```
Fundraising → Active → Sold/Liquidated
     ↓           ↓
  Investment   Income
   Phase      Generation
```

## 📊 Data Structures

### Properties
- **Basic Info**: Name, description, location, type
- **Financial**: Total value, token supply, funding targets
- **Status**: Fundraising, active, sold, liquidated
- **Management**: Property manager, rental estimates

### Investor Holdings
- **Ownership**: Token quantities and investment amounts
- **Returns**: Dividend history and claim tracking
- **Timing**: Investment dates and claim timestamps

### Income Distributions
- **Amounts**: Total income, per-token distributions
- **Tracking**: Claim status, distribution periods
- **Eligibility**: Token holder snapshots

## 🔧 Core Functions

### Property Creation
```clarity
(create-property name description location property-type 
                total-value total-tokens target-funding 
                funding-deadline property-manager annual-rent-estimate)
```

### Investment
```clarity
(invest-in-property property-id stx-amount)
```

### Income Management
```clarity
(record-rental-income property-id income-amount)
(record-expense property-id expense-amount description)
(distribute-income property-id distribution-id)
(claim-dividend property-id distribution-id)
```

### Property Management
```clarity
(update-property-valuation property-id new-valuation)
(update-property-status property-id new-status)
```

## 💰 Fee Structure

### Platform Fees
- **Investment Fee**: 2.5% (250 basis points) on investments
- **Management Fee**: 2% (200 basis points) on rental income
- **Maximum Limits**: Platform fee ≤ 10%, Management fee ≤ 5%

### Investment Requirements
- **Minimum Investment**: 100 STX
- **Token Precision**: Micro-STX (1 STX = 1,000,000 micro-STX)

## 🎯 Use Cases

### For Investors
- **Fractional Real Estate**: Access to real estate with lower capital requirements
- **Passive Income**: Regular rental income distributions
- **Diversification**: Invest across multiple properties
- **Liquidity**: Trade tokens on secondary markets

### For Property Managers
- **Capital Raising**: Efficient fundraising through tokenization
- **Investor Management**: Automated distribution and reporting
- **Transparency**: Real-time financial tracking
- **Global Access**: Reach international investors

### For Developers
- **Property Tokenization**: Convert real estate into digital assets
- **Automated Operations**: Smart contract-based management
- **Regulatory Compliance**: Built-in investor protection mechanisms

## 🔐 Security Features

### Access Control
- **Owner-Only Functions**: Platform administration restricted to contract owner
- **Manager Authorization**: Property-specific management permissions
- **Investor Protection**: Investment limits and validation

### Financial Safety
- **Fee Limits**: Maximum fee percentages enforced
- **Balance Validation**: Sufficient token/balance checks
- **Double-Claim Prevention**: Dividend claim tracking

### Operational Security
- **Status Validation**: Property status checks for operations
- **Deadline Enforcement**: Investment deadline validation
- **Amount Validation**: Positive amount requirements

## 📈 Financial Calculations

### Token Pricing
```
Price per Token = Total Property Value ÷ Total Tokens
```

### Ownership Percentage
```
Ownership % = (Tokens Owned ÷ Total Tokens) × 100
```

### Dividend Calculation
```
Dividend = Tokens Owned × Income per Token
Income per Token = Total Distributable Income ÷ Tokens in Circulation
```

### Fee Calculations
```
Platform Fee = Investment Amount × Platform Fee Rate ÷ 10,000
Management Fee = Rental Income × Management Fee Rate ÷ 10,000
```

## 🚀 Getting Started

### Prerequisites
- Stacks blockchain testnet/mainnet access
- Clarity CLI or development environment
- STX tokens for testing/deployment

### Deployment
1. Deploy the smart contract to Stacks blockchain
2. Initialize contract with desired fee rates
3. Create first property for testing
4. Set up property management permissions

### Testing
Run the comprehensive test suite:
```bash
npm test
```

Tests cover:
- Property creation and validation
- Investment logic and calculations
- Income distribution mechanisms
- Fee calculations
- Edge cases and error handling

## 📊 Property Status Flow

```
STATUS_FUNDRAISING (1) → Investment Phase
    ↓ (Target Reached)
STATUS_ACTIVE (2) → Income Generation
    ↓ (Property Sold)
STATUS_SOLD (3) → Final Distribution
    ↓ (Assets Liquidated)
STATUS_LIQUIDATED (4) → Closed
```

## 🔍 Read-Only Functions

### Property Information
- `get-property`: Retrieve property details
- `get-property-finances`: Financial status and history
- `get-property-stats`: Performance metrics

### Investor Information
- `get-investor-holdings`: Token ownership and investment history
- `calculate-pending-dividends`: Unclaimed dividend amounts
- `calculate-investor-ownership-percentage`: Ownership percentage

### Financial Calculations
- `calculate-token-value`: Current token value including appreciation
- `get-income-distribution`: Distribution period details

## ⚠️ Important Considerations

### Investment Risks
- Real estate market volatility
- Property-specific risks (vacancy, maintenance)
- Regulatory changes
- Smart contract risks

### Technical Limitations
- Blockchain transaction costs
- Settlement times
- Contract upgrade limitations

### Regulatory Compliance
- Securities regulations may apply
- Tax implications for investors
- Jurisdiction-specific requirements

## 🛠️ Development & Contribution

### Contract Structure
- **Constants**: Error codes and configuration values
- **Data Maps**: Property, investor, and financial data storage
- **Public Functions**: User-facing operations
- **Private Functions**: Internal helper functions
- **Read-Only Functions**: Data access without state changes

### Testing Strategy
- Unit tests for all mathematical calculations
- Integration tests for complete workflows
- Edge case testing for error conditions
- Gas optimization testing

## 📝 License

This project is provided as-is for educational and development purposes. Ensure proper legal and regulatory compliance before deployment in production environments.

## 🤝 Support

For technical questions, feature requests, or bug reports, please review the code documentation and test cases. The contract includes comprehensive error handling and validation to guide proper usage.

---

**⚡ Built on Stacks blockchain with Clarity smart contracts**