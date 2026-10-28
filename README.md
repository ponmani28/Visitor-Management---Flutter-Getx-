# Visitor Management

A Flutter application for front-desk teams to register visitors, issue QR passes, and manage visits from registration through check-out.

## Features

- Demo sign-in page with protected visitor screens and sign-out
- Dashboard with daily visitor and visit-status metrics
- Visitor registration, editing, search, and status filtering
- Visitor details, including visit timestamps and a QR pass
- QR scanning to look up a visitor by their pass ID
- Visit workflow: `Registered` → `Checked In` → `Checked Out`
- Confirmation before deleting a visitor
- Light and dark themes, with loading, error, and empty states

## Technology

- Flutter and Dart
- GetX for dependency injection, routing, and reactive state
- Dio for REST API requests
- `qr_flutter` for QR pass generation
- `mobile_scanner` and `permission_handler` for QR scanning
- `intl` for date formatting

## Requirements

Install Flutter with a Dart SDK that satisfies the constraint in `pubspec.yaml`. QR scanning requires a physical Android or iOS device, or an emulator with camera support.

## Getting Started

From the project directory, install dependencies and run the app:

```powershell
flutter pub get
flutter run
```

Grant camera permission when prompted to use the QR scanner.

## Visitor Data and API

Visitor records are stored by a remote REST API, not only on the device. After sign-in, the app requests the visitor list from the API; records therefore remain available after an app restart.

The sign-in screen is a UI/demo flow only: any non-empty username and password are accepted. It does not authenticate a user, secure visitor data, or persist a session. Use a real backend authentication flow before deploying the app with sensitive data.

The default configuration points to the NilesLabs Playground API:

| Setting | Default |
| --- | --- |
| Base URL | `https://playground.nileslabs.com/api/v1` |
| Visitors resource | `/custom/visitors` |
| Identity header | `X-Playground-Identity` |

The app sends the configured identity header with its API requests. The default playground identity is a fixed development value, not a user account or device-specific ID. As a result, app instances using that same value share the same playground dataset. Do not treat this header as authentication or use the playground configuration for production data.

Configure the API at build or run time with Dart defines:

```powershell
flutter run `
  --dart-define=API_BASE_URL=https://api.example.com `
  --dart-define=API_VISITORS_PATH=/visitors `
  --dart-define=API_IDENTITY=your-development-identity
```

Use an HTTPS endpoint and a proper authentication mechanism for production. Keep credentials out of source control and build logs.

### API Endpoints

The default visitor resource uses these operations:

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/custom/visitors?limit=200` | List visitors |
| `GET` | `/custom/visitors/:id` | Fetch a visitor |
| `POST` | `/custom/visitors` | Create a visitor |
| `PUT` | `/custom/visitors/:id` | Update a visitor |
| `DELETE` | `/custom/visitors/:id` | Delete a visitor |

The API may return a visitor list directly or wrapped in a `data`, `visitors`, `items`, or `records` field. A single visitor may be returned directly or wrapped in `data`.

### Visitor Record

The API record uses `snake_case` fields. The server supplies the visitor ID when a record is created.

```json
{
  "id": "server-generated-id",
  "name": "Aarav Sharma",
  "mobile": "9876543210",
  "email": "aarav@example.com",
  "visitor_type": "Customer",
  "project": "Project A",
  "purpose": "Client meeting",
  "status": "Registered",
  "created_at": "2026-10-27T08:15:00.000Z",
  "check_in_time": null,
  "check_out_time": null
}
```

- Visitor types: `Customer`, `Vendor`, or `Other`
- Projects: `Project A`, `Project B`, or `Project C`
- Statuses: `Registered`, `Checked In`, or `Checked Out`
- Name, mobile number, visitor type, project, and purpose are required; email is optional.
- Mobile numbers must contain exactly 10 digits.

## Visit Workflow

- New records start with the `Registered` status.
- Registered visitors may be checked in; the app records the check-in time.
- Checked-in visitors may be checked out; the app records the check-out time.
- Other status transitions are not allowed.
- The QR pass encodes the visitor ID. Scanning the pass looks up that record through the API.

## Build an Android APK

```powershell
flutter build apk --debug
```

The APK is written to:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

For a release APK, use `flutter build apk --release`.

## Verify

Run static analysis and the test suite:

```powershell
flutter analyze
flutter test
```

## Project Structure

```text
lib/
  app/
    core/          # App configuration, errors, theme, utilities, shared widgets
    data/          # Visitor model, API provider, repository, controller
    modules/       # Dashboard, visitor list, forms, details, scanner, home
    routes/        # GetX route definitions
  main.dart        # App entry point and dependency initialization
test/              # Unit and widget tests
```
