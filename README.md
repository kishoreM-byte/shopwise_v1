# ShopWise 🛋️

### Intelligent Furniture Shopping Platform

ShopWise is a smart furniture shopping platform built with Flutter. It connects customers with registered furniture retailers and helps them discover products, compare options, estimate actual purchasing costs, and manage their shopping activities in one place.

## ✨ Key Features

### Customer Features
- **Product Discovery:** Browse furniture products across registered shops.
- **Location-Based Shop Discovery:** Find nearby furniture retailers.
- **Smart Comparison:** Compare up to four products based on important details.
- **Smart Score:** Evaluate products using Value, Quality, Availability, and Offers.
- **True Cost Calculation:** Estimate the actual cost, including product price, travel expenses, toll charges, delivery, and installation.
- **Smart Trip:** Consider travel routes and shop visits while planning purchases.
- **Wishlist:** Save products for future reference.
- **Enquiries and Orders:** Contact retailers and manage purchase activities.
- **Ratings and Reviews:** Share product and shopping experiences.

### Retailer Features
- Manage shop information and service details.
- Add and update furniture products.
- Manage product availability and stock.
- View and respond to customer enquiries.
- Manage customer orders.

## 🧠 Smart Features

### Smart Score

ShopWise calculates a weighted score to help customers evaluate products.

| Evaluation Factor | Weight |
|---|---:|
| Value | 35% |
| Quality | 35% |
| Availability | 15% |
| Offers | 15% |

### True Cost Calculation

The platform estimates the actual purchasing expense by considering:

- Product price
- Petrol and travel expenses
- Toll charges
- Delivery charges
- Installation charges

It also considers travel expenses when customers visit a shop to confirm delivery arrangements.

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Application programming language |
| Firebase Authentication | User authentication |
| Cloud Firestore | Cloud database |
| Firebase Security Rules | Data access and security |
| Cloudinary | Product image storage |
| OpenStreetMap | Map data |
| OSRM | Route and distance calculation |

## 📁 Project Structure

```text
shopwise_v1/
├── android/
├── assets/
├── lib/
│   ├── models/
│   ├── screens/
│   ├── services/
│   ├── widgets/
│   └── main.dart
├── rules-test/
├── test/
├── firestore.rules
├── firestore.indexes.json
├── pubspec.yaml
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Firebase project
- Cloudinary account

### Installation

1. Clone the repository:

```bash
git clone https://github.com/kishoreM-byte/shopwise_v1.git
```

2. Navigate to the project directory:

```bash
cd shopwise_v1
```

3. Install dependencies:

```bash
flutter pub get
```

4. Configure Firebase for your development environment using FlutterFire CLI.

5. Configure the required Cloudinary settings.

6. Run the application:

```bash
flutter run
```

## 🧪 Testing and Verification

Run Flutter tests:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

Run Firestore security rules tests:

```bash
firebase emulators:exec --only firestore "cd rules-test && npm test"
```

### Latest Verification Results

- 161 Flutter tests passed.
- 44 Firestore security rules tests passed.
- Flutter static analysis completed with no issues.

## 🔐 Security

- Firebase Authentication is used for user authentication.
- Firestore Security Rules protect application data.
- Ownership and access validation are applied to relevant operations.
- Stock and order status validations help maintain data consistency.
- Private keys and service account credentials must not be committed to the repository.

## 🔮 Future Scope

- AI-powered furniture recommendations.
- Improved product discovery and personalization.
- Enhanced customer-retailer interaction.
- Advanced shopping insights and decision support.

## 👨‍💻 Development Team

- Kishore M
- Esai Selvi M

## 📄 License

No open-source license has currently been selected for this project. All rights are reserved unless a license is added.