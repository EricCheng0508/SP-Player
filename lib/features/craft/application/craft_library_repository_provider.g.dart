// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'craft_library_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(craftLibraryRepository)
final craftLibraryRepositoryProvider = CraftLibraryRepositoryProvider._();

final class CraftLibraryRepositoryProvider
    extends
        $FunctionalProvider<
          CraftLibraryRepository,
          CraftLibraryRepository,
          CraftLibraryRepository
        >
    with $Provider<CraftLibraryRepository> {
  CraftLibraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'craftLibraryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$craftLibraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<CraftLibraryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CraftLibraryRepository create(Ref ref) {
    return craftLibraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CraftLibraryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CraftLibraryRepository>(value),
    );
  }
}

String _$craftLibraryRepositoryHash() =>
    r'21442a6766b823c4cee045e671914c121765b546';
