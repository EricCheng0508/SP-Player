/// Typed failures for UI and repositories.
library;

sealed class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

final class FileFailure extends AppFailure {
  const FileFailure(super.message);
}

/// Picked file is not an allowed local audio/video type (e.g. image or document).
final class UnsupportedImportFileFailure extends AppFailure {
  const UnsupportedImportFileFailure() : super('');
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {this.statusCode});

  final int? statusCode;
}

/// A 402 from the user's own AI provider (BYOK), not from the Enjoy worker.
///
/// The rejection is about the provider's billing — showing the Enjoy
/// subscription upsell here would be wrong (spec 045 FR-008). Surfaces
/// without a dedicated branch render it through their generic failure path.
final class ProviderBillingFailure extends AppFailure {
  const ProviderBillingFailure(super.message);
}
