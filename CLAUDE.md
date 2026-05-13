# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Build for iOS
flutter build ios

# Build for Android
flutter build apk
```

## Project Architecture

This Flutter application follows a clean architecture pattern with clear separation of concerns:

### Layer Structure

```
lib/
├── core/              # Cross-cutting capabilities
│   ├── network/      # HTTP client factory
│   └── utils/        # Shared utilities (clock, JS parsers)
├── features/         # Feature modules
│   ├── fund/        # Fund-related features and models
│   ├── portfolio/   # Portfolio management
│   ├── market/      # Market data features and models
│   └── settings/    # Settings features and models
├── data/             # Data layer implementations
│   ├── fund/        # Fund data repository (EastmoneyFundRepository)
│   ├── market/      # Market data repository
│   └── settings/    # Settings repository
├── domain/           # Domain interfaces
│   ├── fund/        # FundRepository interface
│   ├── market/      # MarketRepository interface
│   └── settings/    # SettingsRepository interface
├── app/              # App routing and entry point
└── main.dart         # Application entry
```

### Architecture Pattern

The project uses **Domain-Driven Design** with the following pattern:

1. **Domain Layer** (`lib/domain/`): Abstract interfaces defining contracts
   - `FundRepository`: Fund data operations interface
   - `MarketRepository`: Market data operations interface
   - `FundCloudStore`: Optional cloud storage for sector/LLM features

2. **Data Layer** (`lib/data/`): Implementations of domain interfaces
   - `EastmoneyFundRepository`: Implements FundRepository, fetches from Eastmoney APIs
   - Other repositories follow the same pattern

3. **Features** (`lib/features/`): UI components and models grouped by domain
   - Models: Data structures for each feature (fund_models.dart, market_models.dart, etc.)
   - Views: Reusable UI components (e.g., fund_search_bar.dart)

4. **Core** (`lib/core/`): Shared utilities
   - `AppDioFactory`: Creates configured Dio instance with standard headers and timeouts
   - `ShanghaiClock`: Time utilities for Shanghai market operations
   - `FundJsParsers`: Parses JavaScript responses from Eastmoney APIs

## Key Dependencies

- **dio** (^5.9.2): HTTP client for all network requests
- **fl_chart** (^1.2.0): Chart components for visualizations
- **flutter_lints** (^6.0.0): Dart lint rules

## Important Patterns

### Repository Pattern

All repositories in `lib/data/` follow this pattern:

```dart
class XxxRepository implements XxxRepository {
  XxxRepository({Dio? dio, XxxCloudStore? cloudStore})
    : _dio = dio ?? AppDioFactory.create(),
      _cloudStore = cloudStore;

  final Dio _dio;
  final XxxCloudStore? _cloudStore;

  // Implement interface methods...
}
```

**Key points:**
- Accept optional `dio` for testability
- Accept optional `cloudStore` for cloud features
- Use `AppDioFactory.create()` as default HTTP client

### Data Parsing

Eastmoney APIs return JavaScript, parsed by `FundJsParsers`:

```dart
// Parse JSONP callback responses
FundJsParsers.parseJsonpBody(body)

// Extract content from APIDATA responses
FundJsParsers.extractApidataContent(source)
```

### Time Handling

All time-sensitive operations use `ShanghaiClock` for market time consistency:

```dart
// Get current Shanghai market time
ShanghaiClock.now()

// Format date for API calls
ShanghaiClock.formatDate(dateTime)
```

## API Integration Notes

### Fund Data (`lib/data/fund/eastmoney_fund_repository.dart`)

This is the primary data source for fund information:

- **Base URL**: Various Eastmoney endpoints
- **Auth**: None required (public APIs)
- **Response Format**: JSONP for fund data, JSON for others

### Network Client (`lib/core/network/app_dio_factory.dart`)

The default Dio instance includes:
- Connect timeout: 10 seconds
- Receive timeout: 20 seconds
- Browser-like User-Agent header
- Status validation (200-499 considered successful)

### Cloud Features

Optional `FundCloudStore` enables:
- Related sector lookup
- LLM-powered fund text analysis

These features gracefully degrade if `cloudStore` is not provided.

## Common Development Tasks

### Adding a New Feature

1. Create models in `lib/features/xxx/models/xxx_models.dart`
2. Create domain interface in `lib/domain/xxx/xxx_repository.dart`
3. Implement repository in `lib/data/xxx/xxx_repository.dart`
4. Create UI components in `lib/features/xxx/view/`
5. Wire up in `lib/app/app.dart` or create new route

### Adding a New API Endpoint

1. Add method to domain interface
2. Implement in data repository
3. Add parsing logic to `FundJsParsers` if needed
4. Write tests for the new endpoint

### Working with Charts

Use `fl_chart` for visualizations. Current usage in `lib/app/app.dart`:

```dart
LineChart(
  LineChartData(
    gridData: const FlGridData(show: false),
    titlesData: const FlTitlesData(show: false),
    // ... configuration
  ),
)
```

## Testing

Test files should be placed in `test/` directory. Run tests with:

```bash
flutter test
```

## Documentation

- API documentation: `lib/data/fund/接口使用说明.md` (in Chinese)
- General project info: `README.md`