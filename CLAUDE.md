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

# Run single test
flutter test test/widget_test.dart

# Generate code (if using freezed/json_serializable)
dart run build_runner build --delete-conflicting-outputs
```

## Project Architecture

This Flutter application follows a **Feature-First + Clean Architecture** pattern with clear separation of concerns.

### Recommended Directory Structure

```
lib/
├── app/                        # App-level configuration
│   ├── routes/                 # Routing
│   ├── theme/                  # Theme configuration
│   ├── config/                 # Environment configuration
│   ├── constants/              # Global constants
│   └── app.dart
│
├── core/                       # Core foundational capabilities (no business logic)
│   ├── network/                # Network layer
│   │   └── app_dio_factory.dart
│   ├── storage/                # Local storage (if added)
│   ├── utils/                  # Utility classes
│   │   ├── shanghai_clock.dart
│   │   └── fund_js_parsers.dart
│   ├── extensions/             # Extension methods (if added)
│   ├── errors/                 # Exception handling (if added)
│   ├── base/                   # Base classes (if added)
│   ├── services/               # Global services (if added)
│   └── widgets/                # Global common widgets
│
├── shared/                     # Cross-business shared
│   ├── models/
│   ├── enums/
│   ├── providers/
│   └── widgets/
│
├── features/                   # Business modules (CORE)
│   ├── home/                   # Home page
│   ├── fund/                   # Fund management
│   ├── account/                # Account management
│   ├── asset/                  # Asset overview
│   ├── settings/               # Settings
│   └── auth/                   # Authentication (if added)
│
├── generated/                  # Auto-generated (freezed, json_serializable)
│
└── main.dart                 # Application entry
```

### Feature Module Structure

Each feature module should follow this structure:

```
features/xxx/
├── api/                    # API layer (business-specific)
├── repository/              # Repository implementation
├── providers/               # State management (Riverpod)
├── pages/                  # Screen widgets
├── widgets/                # Feature-specific widgets
├── models/                 # Data models
├── services/               # Business logic (use cases)
├── states/                 # State classes
└── controllers/           # Controllers (if needed)
```

### Architecture Pattern

The project uses **Domain-Driven Design** with **Feature-First** organization:

#### 1. Feature Layer (`lib/features/`)

Business modules grouped by domain, each containing:

- **API**: Business-specific API calls
- **Repository**: Data access abstraction
- **Providers**: State management (Riverpod)
- **Pages**: Screen widgets (UI composition only)
- **Widgets**: Reusable components
- **Models**: Data structures
- **Services**: Business logic/use cases

#### 2. Core Layer (`lib/core/`)

Shared utilities and foundational capabilities:

- `AppDioFactory`: Creates configured Dio instance with standard headers and timeouts
- `ShanghaiClock`: Time utilities for Shanghai market operations
- `FundJsParsers`: Parses JavaScript responses from Eastmoney APIs

### Layer Responsibilities

#### Pages Layer

Screen-level widgets responsible for:

- Page layout and composition
- Page lifecycle
- **NOT**: API calls, complex logic, database operations

```dart
class FundHomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final funds = ref.watch(fundListProvider);

    return Scaffold(
      body: FundListView(funds: funds),
    );
  }
}
```

#### Widget Organization

##### Page-Private Widgets

Only used by current page:

```dart
features/fund/widgets/
  fund_card.dart
  profit_chart.dart
  holding_item.dart
```

##### Global Common Widgets

Truly common components (3+ business modules reuse):

```dart
core/widgets/
  app_button.dart
  app_loading.dart
  app_network_image.dart
  app_dialog.dart
```

#### API Organization

Business-specific APIs:

```dart
features/fund/api/
  fund_api.dart
```

NOT:

```dart
api/
  fund_api.dart
  user_api.dart
```

#### Repository Layer

Critical for maintainability - abstracts data sources:

**Without Repository** (disaster):

```dart
// Page directly calls API
final funds = await dio.get('/funds');
```

**With Repository** (maintainable):

```dart
class FundRepository {
  final FundApi api;

  FundRepository(this.api);

  Future<List<FundModel>> searchFunds(String keyword) {
    return api.searchFunds(keyword);
  }
}
```

Future-proof: API → SQLite + Cache + Mock (page never needs to change)

## Key Dependencies

| Function             | Recommended              | Notes                        |
| -------------------- | ------------------------ | ---------------------------- |
| Network              | Dio ^5.9.2               | HTTP client                  |
| State Management     | Riverpod                 | Type-safe, compile-time safe |
| Charts               | fl_chart ^1.2.0          | Visualizations               |
| Data Classes         | freezed, json_annotation | Code generation              |
| Linting              | flutter_lints ^6.0.0     | Dart lint rules              |
| Internationalization | intl                     | i18n support                 |

## Recommended Tech Stack (2026)

| Function             | Recommended           |
| -------------------- | --------------------- |
| Network              | Dio                   |
| State Management     | Riverpod              |
| Routing              | go_router             |
| Data Classes         | freezed               |
| Local Database       | Isar                  |
| Local KV             | shared_preferences    |
| Charts               | fl_chart              |
| Internationalization | intl                  |
| Logging              | logger                |
| Network Cache        | dio_cache_interceptor |

## Common Mistakes to Avoid

### Mistake 1: Pages directly request API

```dart
onPressed() async {
  final res = await Dio().get(...);
}
```

**Problem**: Hard to maintain, data sources cannot change

### Mistake 2: All widgets in global

```dart
widgets/
  300 files
```

**Problem**: File chaos, impossible to locate, global namespace pollution

### Mistake 3: Business logic in build()

```dart
Widget build() {
  final result = complexCalculate();
}
```

**Problem**: build() executes frequently, performance issues

### Mistake 4: One page with 3000 lines

**Problem**: Must split into smaller widgets

## Recommended Feature Modules for Asset Management App

```
features/
├── home/              # Dashboard
├── fund/               # Fund management
├── account/            # Account management
├── asset/              # Asset overview
├── transaction/        # Transaction records
├── statistics/         # Statistics & reports
└── settings/           # Settings
```

## Important Patterns

### Repository Pattern

All repositories in `lib/data/` or `lib/features/*/repository/` follow:

```dart
class XxxRepository implements XxxRepository {
  XxxRepository({Dio? dio, XxxApi? api})
    : _dio = dio ?? AppDioFactory.create(),
      _api = api;

  final Dio _dio;
  final XxxApi _api;

  // Implement interface methods...
}
```

**Key points:**

- Accept optional `dio` for testability
- Accept optional `api` for business-specific services
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
2. Create API in `lib/features/xxx/api/xxx_api.dart`
3. Create repository in `lib/features/xxx/repository/xxx_repository.dart` (if needed)
4. Create providers in `lib/features/xxx/providers/xxx_provider.dart`
5. Create pages in `lib/features/xxx/pages/`
6. Create widgets in `lib/features/xxx/widgets/`
7. Wire up providers in `lib/app/app.dart` or create new route

### Adding a New API Endpoint

1. Add method to domain interface
2. Implement in data repository or feature API
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
