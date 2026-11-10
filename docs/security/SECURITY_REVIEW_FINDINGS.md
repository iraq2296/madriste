# MADRASI — Security Review Findings

Date: 2026-11-10
Scope: migrations 001–005, with emphasis on review-branch migrations 004 and 005.
Status: Static review only. No SQL has been executed. No database was connected.

## Release decision

**NOT APPROVED for production.** The review migrations are proposals and require validation in an isolated Supabase/PostgreSQL database. Do not merge or deploy based only on this report.

## Findings

### F-01 — Manager-created membership flow is blocked by RLS
- Severity: High (workflow correctness / authorization)
- Evidence: migration 002 policy `p_memberships_insert` only permits `user_id = auth.uid() AND status = 'pending'`.
- Migration 005 adds a manager-created membership branch to `enforce_membership_initial_state()` that expects a manager to insert a membership for another user with status pending/invited.
- The existing INSERT policy prevents that manager insert before the trigger can provide the intended workflow.
- Required action: design a narrow INSERT policy allowing only the manager of the target school to create an invitation, with trusted profile-role matching and pending/invited status. Keep self-join separate. Add negative tests for cross-school and role escalation attempts.

### F-02 — Leave request school and recipient integrity is not enforced
- Severity: High
- Status: **Addressed in proposal by migration 006; not database-verified.**
- Migration 006 requires an approved parent-child link for the exact parent, student, and school tuple, requires a non-empty recipient list, and checks every recipient is authorized staff for that school.
- It also freezes attachment metadata after creation and permits parent cancellation only while pending.
- Required validation: test wrong-school submissions, empty recipients, unauthorized recipients, parent cancellation, parent approval denial, and staff approval authorization.

### F-03 — Parent-link workflow has privacy and approver-integrity questions
- Severity: Medium
- Evidence: `auth_is_school_workflow_staff(school_id,user_id)` is executable by all authenticated users and accepts an arbitrary user ID. It returns a boolean about another user's staff status in a school.
- The function is used to validate the selected approver. The boolean response may allow membership probing.
- Required action: avoid exposing an arbitrary-user membership oracle. Prefer a trusted trigger/RPC validation path or a narrower helper whose caller identity is fixed where possible. Test approver selection and school isolation.

### F-04 — Public directory behavior may break after security_invoker
- Severity: High (workflow / compatibility)
- Evidence: migration 004 changes `public_profiles` to `security_invoker = true`, while the underlying `profiles` SELECT policy in migration 002 generally limits users to their own profile, superAdmin, or profiles visible to a manager.
- Result: ordinary authenticated users may no longer be able to discover safe public profile fields for other users.
- Required action: replace the view with a carefully designed safe directory endpoint (for example, a narrowly scoped SECURITY DEFINER function with fixed search_path and explicit columns/filters), or another design that does not expose private profile fields. Test privacy and expected search workflows.

### F-05 — PostgreSQL execution and RLS tests are missing
- Severity: Critical release gate
- Evidence: existing Dart tests simulate policy logic and do not execute PostgreSQL RLS. Migrations 004 and 005 have not been run.
- Required action: apply migrations 001–005 to a disposable database in order; run SQL-level tests using anon, authenticated users with distinct roles, and service_role. Include positive and negative cases, cross-school access, UPDATE USING/WITH CHECK relocation attempts, trigger behavior, and function EXECUTE grants. Do not use production data.

### F-06 — Other RLS-enabled tables remain default-deny or incompletely specified
- Severity: Medium (feature readiness)
- Evidence: tables including `exam_schedules`, `student_notes`, `parent_meetings`, `teacher_follows`, `class_schedules`, `library_favorites`, `discounts`, `manual_extensions`, and `audit_logs` have no client policies in migration 002 (some are intentionally noted as default-deny in migration 005).
- Required action: do not add broad policies. Define each feature's access matrix first, then add narrowly scoped policies and tests. Default-deny is safer than accidental exposure but means those workflows are not ready.

### F-07 — Trigger function privilege behavior needs database verification
- Severity: Medium
- Evidence: migrations 004 and 005 revoke EXECUTE from PUBLIC/anon/authenticated on trigger functions after creating/replacing them.
- Required action: verify trigger execution under the actual PostgreSQL/Supabase role model in a disposable database. Also inspect function ownership, table grants, default privileges, and SECURITY DEFINER ownership.

### F-08 — Conversation participant integrity is incomplete
- Severity: High
- Evidence: migration 002 lets a user create a conversation when their own ID appears in `participant_ids`; it does not establish that every other participant is eligible to communicate under the app's role/school/parent-child rules.
- Required action: validate participant membership and allowed role combinations in a trusted trigger/RPC. Prevent later participant-list tampering and test cross-school conversations.

### F-09 — Parent cancellation path for leave requests is unclear
- Severity: Medium (workflow correctness)
- Evidence: migration 005 trigger allows a pending leave request to transition to `cancelled`, but the UPDATE policy appears to authorize only listed staff recipients, the manager, or superAdmin—not the parent who created the request.
- Required action: decide whether parents can cancel pending requests. If yes, add a narrowly scoped parent-owner cancellation policy and trigger branch that only allows pending -> cancelled by the original parent.

## Additional implementation notes
- The payment gateway found in the reviewed Dart source is a mock; live payment processing is not configured. Do not enable real payments until a provider integration, signed server-side verification, idempotency, amount/currency validation, and webhook security are implemented and tested.
- The rollback migration is destructive and must not be run as part of normal deployment.
- The two review migrations are not certified production-safe by this static review.

## Recommended validation sequence
1. Resolve F-01 through F-04 and F-08/F-09 in a reviewed migration.
2. Build a disposable Supabase/PostgreSQL test environment.
3. Apply migrations 001–005 in order and capture exact errors.
4. Add SQL integration tests for every role and school boundary.
5. Inspect grants, function ownership, views, triggers, and storage policies.
6. Only then prepare a draft pull request for human review. Merge/deploy requires explicit owner approval.


## Update after migration 006 (2026-11-10)
- Added `supabase/migrations/006_membership_invites_and_leave_integrity.sql`.
- F-01 and F-02 have proposed code changes, but remain open as release gates until PostgreSQL execution and integration tests pass.
- Migration 006 has not been executed. No merge, deployment, or production changes have occurred.


## Update after migration 007 (2026-11-10)
- Added `supabase/migrations/007_private_staff_validation_and_safe_directory.sql`.
- F-03: proposed replacement separates a private arbitrary-user staff predicate (not executable by client roles) from a client-callable helper that evaluates only `auth.uid()`. Parent-link and leave-request triggers use the private predicate to validate chosen approvers/recipients.
- F-04: proposed authenticated directory RPC returns an explicit allowlist of profile fields and omits phone and private verification/status metadata. The old `public_profiles` view remains security_invoker; application reads must be migrated to the RPC and tested.
- Both findings remain open as release gates until SQL is executed in a disposable database, grants/ownership are inspected, and positive/negative integration tests pass.
- No migration has been executed; no PR, merge, deployment, or production database change has occurred.
