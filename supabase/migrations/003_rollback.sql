-- ==============================================================================
-- MADRASI — مَدرَستي
-- Migration 003: Safe Rollback Script (Reverse Dependency Order)
-- Use this script to completely and safely revert migrations 001 and 002
-- in Development or Staging environments.
-- ==============================================================================

-- 1. DROP RLS POLICIES & FUNCTIONS
DROP FUNCTION IF EXISTS auth_user_role() CASCADE;
DROP FUNCTION IF EXISTS auth_is_super_admin() CASCADE;
DROP FUNCTION IF EXISTS auth_is_member_of_school(UUID) CASCADE;
DROP FUNCTION IF EXISTS auth_user_school_role(UUID) CASCADE;
DROP FUNCTION IF EXISTS auth_is_manager_of_school(UUID) CASCADE;
DROP FUNCTION IF EXISTS auth_is_linked_parent_of(UUID) CASCADE;
DROP FUNCTION IF EXISTS auth_has_active_subscription() CASCADE;

-- 2. DROP TRIGGERS
DROP TRIGGER IF EXISTS trg_device_limit ON device_sessions;
DROP FUNCTION IF EXISTS check_device_limit() CASCADE;

-- 3. DROP TABLES (IN REVERSE FOREIGN KEY DEPENDENCY ORDER)
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS device_sessions CASCADE;
DROP TABLE IF EXISTS manual_extensions CASCADE;
DROP TABLE IF EXISTS discounts CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS subscription_plans CASCADE;
DROP TABLE IF EXISTS library_favorites CASCADE;
DROP TABLE IF EXISTS library_resources CASCADE;
DROP TABLE IF EXISTS ministerial_exams CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS parent_meetings CASCADE;
DROP TABLE IF EXISTS leave_requests CASCADE;
DROP TABLE IF EXISTS parent_link_requests CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS student_notes CASCADE;
DROP TABLE IF EXISTS class_schedules CASCADE;
DROP TABLE IF EXISTS class_attendance CASCADE;
DROP TABLE IF EXISTS grade_entries CASCADE;
DROP TABLE IF EXISTS exam_schedules CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS teacher_follows CASCADE;
DROP TABLE IF EXISTS school_memberships CASCADE;
DROP TABLE IF EXISTS subjects CASCADE;
DROP TABLE IF EXISTS class_groups CASCADE;
DROP TABLE IF EXISTS academic_years CASCADE;
DROP TABLE IF EXISTS schools CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- 4. DROP ENUM TYPES
DROP TYPE IF EXISTS payment_status CASCADE;
DROP TYPE IF EXISTS subscription_status CASCADE;
DROP TYPE IF EXISTS meeting_status CASCADE;
DROP TYPE IF EXISTS meeting_type CASCADE;
DROP TYPE IF EXISTS leave_status CASCADE;
DROP TYPE IF EXISTS link_status CASCADE;
DROP TYPE IF EXISTS note_kind CASCADE;
DROP TYPE IF EXISTS attendance_status CASCADE;
DROP TYPE IF EXISTS exam_type CASCADE;
DROP TYPE IF EXISTS lesson_type CASCADE;
DROP TYPE IF EXISTS membership_status CASCADE;
DROP TYPE IF EXISTS track_type CASCADE;
DROP TYPE IF EXISTS school_stage CASCADE;
DROP TYPE IF EXISTS school_status CASCADE;
DROP TYPE IF EXISTS account_status CASCADE;
DROP TYPE IF EXISTS verification_status CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;
