# TerraVerse

**Virtual Property Marketplace for the Digital Frontier**  
*Powered by SIP-009 Compliant NFTs*

---

## 🏙️ Overview

**TerraVerse** is a decentralized, on-chain real estate marketplace for trading virtual properties using non-fungible tokens (NFTs). Built with support for SIP-009 compliance, each property in TerraVerse is tokenized as a unique digital deed, allowing ownership, development, and market activity within a dynamic, location-based economy.

---

## 🔑 Key Features

- **NFT-based Property Deeds**  
  Each property is represented by a non-fungible token (`property-deed`), transferable and tradable.

- **Mayor-Governed Development**  
  Only the city mayor (contract deployer) can develop new properties or perform emergency reclamation.

- **Location & Zone Specifics**  
  Zone types: `RESIDENTIAL`, `COMMERCIAL`, `INDUSTRIAL`, `LUXURY`, `LANDMARK`  
  Property value and commission rates vary by zone type and square footage.

- **Marketplace Functionality**  
  - List and purchase properties with STX  
  - Automated developer commissions  
  - Listing removal and emergency reclaiming

- **Batch Development**  
  Efficiently mint and register up to 10 properties at once.

- **Rich Metadata**  
  Each property includes address, blueprint, and virtual tour URLs.

---

## 📦 SIP-009 Compliance

TerraVerse fully implements required SIP-009 traits:

- `get-token-uri`
- `get-last-token-id`
- `get-owner`
- `transfer`

---

## 📊 Economic Logic

- **Commission Model:**  
  Developers earn a % of the sale based on zone type:
  - `LANDMARK` - 15%  
  - `LUXURY` - 12%  
  - `COMMERCIAL` - 8%  
  - `INDUSTRIAL` - 6%  
  - `RESIDENTIAL` - 4%

- **Estimated Property Value:**  
  Automatically calculated by multiplying zone-based rate with square footage.

---

## 🧮 Utility Functions

- `get-total-properties` – total properties developed  
- `get-properties-by-owner` – returns user's holdings  
- `get-zone-count` – count of properties in a given zone  
- `estimate-property-value` – get virtual property valuation  

---

## 🚀 Quick Start

1. **Deploy the Contract**  
   Set yourself as `city-mayor` by deploying the smart contract.

2. **Develop a Property**  
   Use `develop-property` or `batch-develop` to mint new properties.

3. **List for Sale**  
   Call `list-property` with a valid price to put it on the marketplace.

4. **Buy a Property**  
   Use `purchase-property` to acquire listed property and transfer funds.

---

## 🔐 Access Control

| Function                    | Access       |
|----------------------------|--------------|
| `develop-property`         | Mayor only   |
| `update-city-registry`     | Mayor only   |
| `emergency-reclaim`        | Mayor only   |
| `list-property`            | Property owner only |
| `remove-listing`           | Landlord only |

---

## 📚 Contract Structure

- `property-deed` – NFT token definition
- `property-details` – Metadata for each property
- `real-estate-listings` – Marketplace listing info
- `development-commission` – Developer reward mapping

---

## 🛠️ Future Ideas

- Property auctions  
- In-game integration with 3D metaverses  
- DAO-based zoning governance  
- Mortgage and leasing mechanics  
