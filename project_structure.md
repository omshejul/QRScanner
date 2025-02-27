# Project Structure

## BASICQRCodeView.swift

- **Enum `QRType`**: Defines types of QR codes (e.g., WiFi, Web URL, Text, etc.).
- **Struct `BASICQRCodeView`**:
  - **Inputs**: `type` (QRType), user inputs for QR code generation.
  - **Outputs**: QR code image, error messages.
  - **Functions**:
    - `generateQRString()`: Generates a string for QR code based on type.
    - `generateVCard()`: Creates a vCard string for contact QR codes.
    - `isInputInvalid()`: Checks if the input is valid for QR code generation.
    - `getPlaceholder()`: Provides placeholder text based on QR type.

## AdvanceQRCodeView.swift

- **Enum `AdvanceQRType`**: Defines advanced types of QR codes (e.g., UPI Payment).
- **Struct `AdvanceQRCodeView`**:
  - **Inputs**: `type` (AdvanceQRType), specific inputs for advanced QR code generation.
  - **Outputs**: QR code image, error messages.
  - **Functions**:
    - Specialized QR code generation for UPI payments and other advanced formats.

## BarcodeGeneratorView.swift

- **Struct `BarcodeGeneratorView`**:
  - **Inputs**: `type` (BarcodeType), content for barcode generation.
  - **Outputs**: Generated barcode image, error messages.
  - **Functions**:
    - `getBarcodeIcon(for type: BarcodeType)`: Returns appropriate icon for barcode type.
    - Barcode generation for various formats (Aztec, Code128, etc.).

## QRCodeScannerView.swift

- **Struct `QRCodeScannerView`**:

  - **Inputs**: Completion handler for scanned QR code.
  - **Outputs**: Scanned QR code string.
  - **Functions**:
    - `makeCoordinator()`: Creates a coordinator for handling metadata output.
    - `makeUIViewController()`: Sets up the scanner view controller.
    - `updateUIViewController()`: Updates the scanner view controller.

- **Class `ScannerViewController`**:
  - **Functions**:
    - `setupScanner()`: Configures the scanner.
    - `setupPreviewLayer()`: Sets up the preview layer for the camera.
    - `startScanning()`: Starts the scanning session.
    - `stopScanning()`: Stops the scanning session.

## QRCodeGeneratorView.swift

- **Struct `QRCodeGeneratorView`**:

  - **Functions**:
    - `getSystemIcon(for type: QRType)`: Returns system icon name for QR type.
    - `saveToCreateHistory(_ createdText: String)`: Saves created QR code text to history.
    - `generateQRCodeAndShare()`: Generates a QR code and prepares it for sharing.
    - `generateQRCode()`: Generates a QR code based on user input.

- **Struct `QRCodeOptionRowSocial`**:

  - **Inputs**: `imageName`, `title`.
  - **Outputs**: UI view for social QR code options.

- **Struct `QRCodeOptionRow`**:

  - **Inputs**: `icon`, `title`.
  - **Outputs**: UI view for QR code options.

- **Struct `SocialQRCodeView`**:
  - **Inputs**: `platform`, `templateURL`, `inputPlaceholder`, `exampleInput`.
  - **Functions**:
    - `generateQRCode()`: Generates a QR code for social media platforms.
    - `generateQRCodeAndShare()`: Generates a QR code and prepares it for sharing.

## ScanResultView.swift

- **Struct `ScanResultView`**:

  - **Inputs**: `scannedText`, `onDismiss`.
  - **Functions**:
    - `generateQRCode(from string: String, isDarkMode: Bool)`: Generates a QR code image.
    - `determineQRType(from text: String)`: Determines the type of QR code.
    - `shareScannedText()`: Shares the scanned text.
    - `connectToWiFi(_ text: String)`: Connects to WiFi using QR code.
    - `saveContact(_ vCard: String)`: Saves contact from vCard.
    - `openMATMSGEmail(_ text: String)`: Opens email client with MATMSG format.
    - `generateQRCodeImage(from string: String, isDarkMode: Bool, size: CGFloat)`: Generates a QR code image.

- **Struct `SectionView`**:

  - **Inputs**: `title`, `content`.

- **Struct `ActionButtonsView`**:
  - **Inputs**: `scannedText`.

## QRCodeScannerContainer.swift

- **Struct `QRCodeScannerContainer`**:

  - **Inputs**: User interactions for scanning.
  - **Outputs**: Scanned QR code, scan history.
  - **Functions**:
    - `playScanSound()`: Plays sound and vibration on scan.
    - `saveToScanHistory(_ scannedText: String)`: Saves scanned text to history.

- **Struct `ScannerCorner`**:
  - **Inputs**: `rotation`, `position`.

## HistoryView.swift

- **Struct `HistoryView`**:
  - **Functions**:
    - `getIcon(for text: String)`: Returns icon name based on scanned text type.
    - `loadHistory()`: Loads scan and create history from UserDefaults.
    - `deleteScanHistoryItem(at offsets: IndexSet)`: Deletes a scan history item.
    - `deleteCreateHistoryItem(at offsets: IndexSet)`: Deletes a create history item.

## QRScannerApp.swift

- **Struct `QRScannerApp`**:
  - **Functions**:
    - `applyTheme()`: Applies the selected theme to the app.

## Utils.swift

- **Extensions**:
  - `hideKeyboard()`: Hides the keyboard.
  - Various utility functions for the application.

## TabBarView.swift

- **Struct `TabBarView`**:
  - **Functions**:
    - `setupTabBarAppearance()`: Configures the tab bar appearance.

## MainMenuView.swift

- **Struct `MainMenuView`**:
  - **No specific functions**: Contains navigation links to different sections of the app.

## SettingsView.swift

- **Struct `SettingsView`**:
  - **Functions**:
    - `applyTheme()`: Applies the selected theme to the app.
    - Settings management for the application.
