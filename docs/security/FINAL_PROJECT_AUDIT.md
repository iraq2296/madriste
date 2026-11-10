# MADRASI — Final Project Audit
Date: 2026-11-10
Scope: repository source review on branch `security/hardening-review-2026-11`.
This is a static source review. No Supabase database, production secrets, external payment provider, Apple signing environment, or Android release environment was accessed.

## Executive decision

**NOT READY FOR PRODUCTION / PUBLIC RELEASE.** The repository contains a useful Flutter prototype and a proposed Supabase schema, but several core production workflows are still preview-only, stubbed, or inconsistent with the database schema. There are release-blocking migration, authentication, identity-verification, payment, and authorization issues.

The security migrations 004–008 are proposals only. They have not been applied or verified against PostgreSQL. Do not run the migration directory as-is until the migration history and rollback file are corrected.

## Critical / release blockers

### C-01 — Migration history is unsafe and ambiguous
- Both `001_core_schema.sql` and `001_initial_schema.sql` exist under the Supabase migrations directory with the same numeric version prefix.
- Supabase migration versions must be unique. The two files also define overlapping schema objects; the initial schema uses non-idempotent `CREATE TYPE` statements.
- `003_rollback.sql` is located inside the automatically applied migrations directory. Its filename makes it look like a normal forward migration, not a manual rollback. The file is destructive and contains drop/cascade operations (per prior review).
- **Impact:** a fresh migration run can fail due to duplicate versioning, or execute destructive rollback SQL if the migration tooling treats it as a forward migration.
- **Required:** establish the actual deployed migration history first; choose one canonical baseline; move rollback scripts outside `supabase/migrations` and document manual use; never rewrite already-applied migration versions without a controlled baseline/reset plan.

### C-02 — Production authentication does not hydrate the real account
- `SupabaseAuthService.verifyOtp` verifies the OTP and queries `profiles`, but then resolves the app user through the local in-memory `DataStore.userByPhone`.
- A real registered Supabase user may therefore authenticate successfully but still have no local AppUser/profile state. This can break role routing and can cause the app to use preview/demo assumptions.
- It then calls `register_device` RPC. No definition of that RPC was found in migrations 001–008.
- **Required:** map the authenticated profile response into a trusted domain model; fail closed if the profile is absent/inactive; implement and test server-side device registration with concurrency-safe session revocation; never silently fall back to preview mode after a backend is configured.

### C-03 — Face verification Edge Function is a fake success path
- `supabase/functions/verify-face/index.ts` checks only that `FACE_PROVIDER` is set, then returns a hard-coded score of 0.94 and liveness=true.
- It does not authenticate the caller, bind `userId` to `auth.uid()`, call a provider, validate the profile image, or enforce a size/type limit. CORS allows every origin.
- **Impact:** setting a provider environment variable can make every request appear verified without any biometric check.
- **Required:** disable this function or make it always return 503 until a real provider adapter exists; require JWT, verify caller/profile ownership, use private storage object IDs rather than client-provided base64, enforce MIME/size limits, call the contracted provider, record attempts server-side, rate-limit, and restrict CORS.

### C-04 — Payments are not integrated
- The Flutter payment adapters explicitly throw `ServiceNotConfiguredException`; the separate sandbox gateway is synthetic and must never be used to activate real subscriptions.
- No production checkout Edge Function or verified webhook implementation was found in the inspected repository.
- **Required:** contract an Iraqi licensed Mastercard-capable acquirer/PSP; implement server-created checkout and signature-verified webhook; derive amount/plan/discount on server; enforce idempotency and replay protection; activate subscription only from verified provider events. Keep live payment disabled until end-to-end sandbox and legal review pass.

### C-05 — Seed script is incompatible with the current schema
- `supabase/seed.sql` references objects/columns absent from `001_core_schema.sql`, including `stages_grades`, `sections`, `users`, `student_grades`, and columns such as `stage`, `directorate`, `address`, `is_verified`, and `subscription_status` that do not match the current schema.
- It uses non-UUID text identifiers where current schema columns are UUIDs.
- **Impact:** this seed cannot reliably initialize the current database and may fail immediately.
- **Required:** remove/replace it with a schema-aligned development seed that runs only in a disposable local/test project. Keep production seed separate and non-personal.

## High severity

### H-01 — Client-side preview store is not a production repository
- The app has a large in-memory `DataStore` populated with preview data. The source describes feature repositories/realtime hydration, but the repository tree does not contain the claimed feature-specific production repository layer.
- Many app screens can render from local lists; local state is not proof of persisted server state or server authorization.
- **Required:** build explicit Supabase repositories for every production feature, remove demo users/OTP from release builds, and add end-to-end tests proving each screen reads/writes only server data.

### H-02 — Several requested workflows are absent or stubbed
- Payment, OCR, face verification, call/meeting integration, push notifications, storage cleanup, backup execution, and support access need production implementations or are only described in documentation.
- The only inspected Edge Function is the face stub. Documentation mentions `otp_guard`, `send-push`, scheduled cleanup, and backup jobs, but corresponding implementations were not found in the repository tree.
- **Required:** create an implementation inventory and mark each feature as implemented, simulated, or unavailable; do not advertise unimplemented functionality.

### H-03 — RLS coverage is incomplete by design
- RLS is enabled, but tables including `exam_schedules`, `student_notes`, `parent_meetings`, `teacher_follows`, `class_schedules`, `library_favorites`, `discounts`, `manual_extensions`, and `audit_logs` have no reviewed client policies in the baseline (default deny).
- Default deny is safer than broad access, but it means these product features will fail for normal users until deliberate policies/RPCs exist.
- **Required:** design policies per workflow and test read/write paths. Do not add broad role-only policies without tenant, class, relationship, and subscription constraints.

### H-04 — Existing RLS rules need further cross-tenant integrity constraints
- For lessons, grades, attendance, schedules, exams and related records, verify that school_id, class_group_id, year_id, subject_id, teacher membership, student enrollment, and exam references all point to the same school and authorized class/subject.
- RLS checks on the row's school_id alone do not prove that referenced rows belong to that same school.
- **Required:** use composite foreign keys/unique constraints or trusted triggers/RPCs to enforce cross-table school consistency, plus bounds checks such as score <= max_score, positive max_score, valid class grade/stage and valid schedule times.

### H-05 — Profile directory and chat proposals are not database-verified
- Migration 007 proposes a safe directory RPC and private staff predicate; migration 008 proposes chat participant validation.
- These need PostgreSQL validation, explicit grants/ownership inspection, and integration tests. The chat proposal currently permits broad same-school group conversations for eligible users; it does not implement finer role-to-role messaging, consent/acceptance, or blocking.
- **Required:** define the product messaging matrix before enabling group creation.

### H-06 — Parent relationship / identity evidence is not legal proof
- OCR and face matching are not government identity verification. Documentation correctly states this limitation.
- Ensure no parent sees a child's data until a school-authorized approver has accepted the link; verify that the approver is entitled to act for the selected school. Review document retention and deletion with Iraqi legal counsel.

### H-07 — Privacy and storage controls are not complete
- The schema stores attachment URLs/names, identity document names, face-related data, and parent/student relationships. No reviewed Storage bucket policies, private bucket setup, signed URL expiry, object ownership checks, or scheduled monthly deletion implementation were found.
- **Required:** private buckets, path ownership rules, short-lived signed URLs, malware/type scanning, upload size limits, encryption/retention policy, audit trails, and tested scheduled deletion.

### H-08 — CI is incomplete and does not prove production readiness
- The inspected workflow runs Flutter analyze/tests and web/Android builds. It does not run PostgreSQL/Supabase migrations or RLS integration tests, does not build iOS, and does not run on the security review branch via the listed branch filters.
- Dart tests named as database/RLS integration tests are local in-memory simulations; they do not connect to PostgreSQL.
- **Required:** add local Supabase/Postgres CI with clean database migration apply, migration reset, RLS tests under anon/authenticated/service_role, Flutter unit/widget tests, Android build, and macOS iOS build. Pin toolchain versions that are actually available and tested.

### H-09 — Demo credentials and preview OTP must be release-gated
- README documents public demo phone numbers and OTP `123456`; PreviewAuthService accepts this fixed code.
- **Required:** compile preview auth and demo seed only into debug/profile builds or a separately signed internal demo flavor. Production must fail closed if backend configuration is missing.

## Medium severity / product readiness

- No iOS CI build/signing evidence. Apple signing, push entitlements, camera permissions, privacy manifests, and App Store privacy disclosures remain unverified.
- Android manifest and permissions require a least-privilege review; release signing and Play policy declarations remain unverified.
- No operational evidence for backups/restore drills, monitoring, incident response, disaster recovery, or support access auditing.
- Subscription trial start, grace periods, renewal, cancellation, refund, chargeback, pricing history, and timezone behavior need server-authoritative tests.
- Account recovery and phone-number changes require server-side proofing and abuse limits; do not trust client OCR or local state.
- Internationalization, RTL, accessibility, low-bandwidth operation, offline behavior, and device compatibility need real-device QA.
- No performance/load test, penetration test, dependency vulnerability scan, or privacy/legal review evidence was found.

## Review of proposed migrations 004–008
These files are unexecuted proposals, not verified fixes. In particular:
- Verify trigger function execution and ownership after `REVOKE ALL`; test under actual Supabase roles.
- Inspect all SECURITY DEFINER functions for fixed search_path, safe schema qualification, owner, execute grants, and row-level behavior.
- Migration 007's public directory returns `subject_ids` and `teacher_code`; confirm those are intended public fields and do not reveal information users expect private.
- Migration 008 should be checked for trigger/RLS interaction, superAdmin/service_role bypass behavior, null school handling, participant revocation after membership/link removal, and message/read-receipt lifecycle.
- Reconcile the migration 006/007/008 policies with the exact policy names in the baseline. Policy name mismatches can leave old permissive policies active because PostgreSQL combines permissive policies with OR.
- Add explicit revocation tests for a user removed from a school or a parent-child link that is later revoked; existing conversations should not necessarily remain accessible forever.

## Release acceptance checklist
Do not declare production-ready until all are true:
1. Migration history is unambiguous; destructive rollback is outside the forward migration directory.
2. Fresh local Supabase reset and upgrade from a representative existing database both succeed.
3. Every SECURITY DEFINER function has audited owner, search_path, grants, and tests.
4. RLS tests cover every table and every role, including cross-school and revoked relationships.
5. Production auth uses only Supabase identity/profile state and device RPCs exist and are tested.
6. Face verification uses a real contracted provider and cannot return synthetic success.
7. Payments are activated only by verified provider webhooks.
8. Storage policies, signed URLs, retention/deletion jobs, and backups are tested.
9. All advertised features have working server-side implementations.
10. CI passes Flutter analysis/tests, PostgreSQL/Supabase security tests, Android release build, and iOS build.
11. Security review, privacy/legal review, penetration test, and restore drill are complete.

## Current disposition
**Prototype / internal preview only. Not production-ready.**
The review branch contains proposed hardening migrations 004–008 and this report. No database migrations were executed, no live provider was connected, and no production deployment was performed.
