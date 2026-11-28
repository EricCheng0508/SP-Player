# REST service layer (removed)

The upstream REST service layer — `RestApi` base class, shared `JsonMap`
typedef, `ApiClient` (bearer auth + camelCase↔snake_case decoding), and the
`*Api` services under `lib/data/api/services/` (auth, audio, video, recording,
vocabulary, transcript, user, stats, direct uploads, subscription, credits,
chat/ASR/translation/dictionary/azure-token/YouTube-transcripts) — was removed
when the account / credits / cloud-sync spine was deleted.

See [ADR-0107](../decisions/0107-local-only-no-account-spine.md) for what
replaced it:

- **BYOK AI calls** go through
  [`byok_http_client.dart`](../../lib/features/ai/data/byok/byok_http_client.dart)
  (plain `package:http`, SSRF-guarded, `ApiException` with `byokProvider: true`).
- **The one remaining worker call** (Discover's YouTube channel/playlist feed)
  goes through
  [`youtube_feed_api.dart`](../../lib/data/api/services/ai/youtube_feed_api.dart)
  (`package:http`, JSON Feed v1.1, unauthenticated).
- `api_client_provider.dart` now only provides the shared `httpClient` provider.

This page remains as a pointer for history; the old pattern docs live in git
history.
