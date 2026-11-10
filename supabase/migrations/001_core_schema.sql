-- ==============================================================================
-- MADRASI — مَدرَستي
-- Migration 001: Core Database Schema (29 Tables)
-- Architecture: Multi-tenant by School with Strict Foreign Keys
-- Compatible with PostgreSQL 15+ / Supabase
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------------------------------------------------------
-- 1. ENUM DEFINITIONS
-- ------------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('manager', 'teacher', 'instructor', 'student', 'parent', 'superAdmin');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE verification_status AS ENUM ('notStarted', 'pending', 'manualReview', 'verified', 'rejected', 'locked');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE account_status AS ENUM ('active', 'disabled', 'blocked');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE school_status AS ENUM ('active', 'suspended');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE school_stage AS ENUM ('primary', 'intermediate', 'preparatory');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE track_type AS ENUM ('none', 'scientific', 'literary');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE membership_status AS ENUM ('pending', 'invited', 'approved', 'rejected', 'left');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE lesson_type AS ENUM ('text', 'pdf', 'image', 'board', 'video', 'booklet', 'announcement');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE exam_type AS ENUM ('daily', 'monthly', 'midyear', 'finalYear');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late', 'excused');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE note_kind AS ENUM ('educational', 'behavioral');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE link_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE leave_status AS ENUM ('pending', 'approved', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE meeting_type AS ENUM ('inPerson', 'audio', 'video');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE meeting_status AS ENUM ('pending', 'accepted', 'rejected', 'rescheduleProposed', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE subscription_status AS ENUM ('trial', 'active', 'expired', 'cancelled', 'grantedFree');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('pending', 'succeeded', 'failed', 'refunded');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ------------------------------------------------------------------------------
-- 2. USERS & PROFILES (TABLE 1)
-- ------------------------------------------------------------------------------
-- The profiles table is the single source of truth for user roles and verification.
-- Roles are stored here and NEVER trusted from client user_metadata.
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone TEXT NOT NULL UNIQUE, -- Iraqi E.164 (+9647XXXXXXXXX)
    full_name TEXT NOT NULL,
    role user_role NOT NULL,
    photo_url TEXT,
    verification verification_status NOT NULL DEFAULT 'pending',
    badge_verified BOOLEAN NOT NULL DEFAULT FALSE,
    status account_status NOT NULL DEFAULT 'active',
    status_reason TEXT,
    governorate TEXT NOT NULL,
    specialization TEXT,
    subject_ids TEXT[] DEFAULT '{}',
    teacher_code TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Constraint: Blue verified badge is ONLY permitted for manager, teacher, instructor, or superAdmin.
-- NEVER for students or parents.
DO $$ BEGIN
    ALTER TABLE profiles ADD CONSTRAINT chk_badge_eligibility 
        CHECK (badge_verified = FALSE OR role IN ('manager', 'teacher', 'instructor', 'superAdmin'));
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Trigger: Strictly protect role elevation and administrative status fields
CREATE OR REPLACE FUNCTION protect_profile_sensitive_fields()
RETURNS TRIGGER AS $$
DECLARE
    v_caller_role user_role;
BEGIN
    -- Check if current authenticated caller is superAdmin
    SELECT role INTO v_caller_role FROM profiles WHERE id = auth.uid();

    -- On INSERT:
    IF TG_OP = 'INSERT' THEN
        -- Only an existing superAdmin can create a superAdmin profile
        IF NEW.role = 'superAdmin' AND (v_caller_role IS DISTINCT FROM 'superAdmin') THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: Unauthorized role assignment: superAdmin.';
        END IF;
        -- Regular signup cannot self-grant verified blue badges or active status overrides
        IF v_caller_role IS DISTINCT FROM 'superAdmin' THEN
            NEW.badge_verified := FALSE;
            NEW.verification := 'pending';
            NEW.status := 'active';
            NEW.status_reason := NULL;
        END IF;
        RETURN NEW;
    END IF;

    -- On UPDATE:
    IF TG_OP = 'UPDATE' THEN
        -- Allow full administrative updates if caller is verified superAdmin
        IF v_caller_role = 'superAdmin' THEN
            RETURN NEW;
        END IF;

        -- Non-superAdmin users CANNOT change their role
        IF NEW.role IS DISTINCT FROM OLD.role THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: Users are strictly forbidden from modifying their own role.';
        END IF;

        -- Non-superAdmin users CANNOT change verified blue badge status
        IF NEW.badge_verified IS DISTINCT FROM OLD.badge_verified THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: Users cannot self-grant verified blue badges.';
        END IF;

        -- Non-superAdmin users CANNOT change verification workflow state
        IF NEW.verification IS DISTINCT FROM OLD.verification THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: Users cannot self-modify their identity verification status.';
        END IF;

        -- Non-superAdmin users CANNOT change account status (active/disabled/blocked)
        IF NEW.status IS DISTINCT FROM OLD.status OR NEW.status_reason IS DISTINCT FROM OLD.status_reason THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: Users cannot change their account status or suspension reason.';
        END IF;

        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trg_protect_profile_fields ON profiles;
CREATE TRIGGER trg_protect_profile_fields
BEFORE INSERT OR UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION protect_profile_sensitive_fields();

-- ------------------------------------------------------------------------------
-- 3. SCHOOLS & ACADEMIC YEARS (TABLES 2, 3, 4, 5)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    governorate TEXT NOT NULL,
    district TEXT NOT NULL,
    stages school_stage[] NOT NULL,
    manager_id UUID NOT NULL REFERENCES profiles(id),
    verified BOOLEAN NOT NULL DEFAULT FALSE,
    status school_status NOT NULL DEFAULT 'active',
    suspension_reason TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    phone TEXT,
    passing_percent NUMERIC(5,2) NOT NULL DEFAULT 50.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS academic_years (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    label TEXT NOT NULL, -- e.g. '2025–2026', '2026–2027'
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS class_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    stage school_stage NOT NULL,
    grade INT NOT NULL,
    track track_type NOT NULL DEFAULT 'none',
    section TEXT NOT NULL, -- 'A', 'B', 'C'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subjects (
    id TEXT PRIMARY KEY,
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    name_ku TEXT NOT NULL,
    icon_key TEXT NOT NULL,
    color_index INT NOT NULL DEFAULT 0
);

-- ------------------------------------------------------------------------------
-- 4. MEMBERSHIPS & RELATIONS (TABLES 6, 7)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    role user_role NOT NULL,
    status membership_status NOT NULL DEFAULT 'pending',
    class_group_ids UUID[] DEFAULT '{}',
    subject_ids TEXT[] DEFAULT '{}',
    via_invite BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_school_membership UNIQUE (user_id, school_id)
);

-- Trigger: Strictly enforce initial pending state and prevent self-approval or self-assigned roles
CREATE OR REPLACE FUNCTION enforce_membership_initial_state()
RETURNS TRIGGER AS $$
DECLARE
    v_caller_role user_role;
    v_is_school_mgr BOOLEAN;
BEGIN
    SELECT role INTO v_caller_role FROM profiles WHERE id = auth.uid();
    SELECT EXISTS (SELECT 1 FROM schools WHERE id = NEW.school_id AND manager_id = auth.uid()) INTO v_is_school_mgr;

    -- On INSERT:
    IF TG_OP = 'INSERT' THEN
        -- If caller is not superAdmin or school manager:
        IF NOT (v_caller_role = 'superAdmin' OR v_is_school_mgr) THEN
            -- Force user_id to be the authenticated caller
            NEW.user_id := auth.uid();
            -- Force status to be pending
            NEW.status := 'pending';
            -- Force role to strictly match user's true verified profile role
            SELECT role INTO NEW.role FROM profiles WHERE id = auth.uid();
            -- Clear assigned classes/subjects on initial join request
            NEW.class_group_ids := '{}';
            NEW.subject_ids := '{}';
            NEW.via_invite := FALSE;
        END IF;
        RETURN NEW;
    END IF;

    -- On UPDATE:
    IF TG_OP = 'UPDATE' THEN
        -- Only school manager or super admin can approve memberships or assign classes
        IF NOT (v_caller_role = 'superAdmin' OR v_is_school_mgr) THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: Only the school manager or super admin can approve memberships or assign classes.';
        END IF;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trg_membership_safety ON school_memberships;
CREATE TRIGGER trg_membership_safety
BEFORE INSERT OR UPDATE ON school_memberships
FOR EACH ROW EXECUTE FUNCTION enforce_membership_initial_state();

CREATE TABLE IF NOT EXISTS teacher_follows (
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    approved BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (student_id, teacher_id, school_id)
);

-- ------------------------------------------------------------------------------
-- 5. ACADEMIC & TEACHING (TABLES 8, 9, 10, 11, 12, 13, 14)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    class_group_id UUID NOT NULL REFERENCES class_groups(id) ON DELETE CASCADE,
    subject_id TEXT NOT NULL REFERENCES subjects(id),
    teacher_id UUID NOT NULL REFERENCES profiles(id),
    year_id UUID NOT NULL REFERENCES academic_years(id),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type lesson_type NOT NULL DEFAULT 'text',
    attachment_name TEXT,
    attachment_url TEXT,
    published_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS exam_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    class_group_id UUID NOT NULL REFERENCES class_groups(id) ON DELETE CASCADE,
    subject_id TEXT NOT NULL REFERENCES subjects(id),
    teacher_id UUID NOT NULL REFERENCES profiles(id),
    year_id UUID NOT NULL REFERENCES academic_years(id),
    type exam_type NOT NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    max_grade NUMERIC(5,2) NOT NULL,
    notes TEXT,
    results_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS grade_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    subject_id TEXT NOT NULL REFERENCES subjects(id),
    teacher_id UUID NOT NULL REFERENCES profiles(id),
    year_id UUID NOT NULL REFERENCES academic_years(id),
    exam_type exam_type NOT NULL,
    title TEXT NOT NULL,
    score NUMERIC(5,2) NOT NULL,
    max_score NUMERIC(5,2) NOT NULL,
    exam_id UUID REFERENCES exam_schedules(id) ON DELETE SET NULL,
    published_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS class_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    class_group_id UUID NOT NULL REFERENCES class_groups(id) ON DELETE CASCADE,
    subject_id TEXT NOT NULL REFERENCES subjects(id),
    teacher_id UUID NOT NULL REFERENCES profiles(id),
    date DATE NOT NULL,
    session_start TIME NOT NULL,
    session_end TIME NOT NULL,
    status attendance_status NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS class_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    class_group_id UUID NOT NULL REFERENCES class_groups(id) ON DELETE CASCADE,
    subject_id TEXT NOT NULL REFERENCES subjects(id),
    teacher_id UUID NOT NULL REFERENCES profiles(id),
    weekday INT NOT NULL, -- 1=Monday .. 7=Sunday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS student_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    kind note_kind NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE, -- NULL for platform-wide announcements
    author_id UUID NOT NULL REFERENCES profiles(id),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    audience TEXT NOT NULL DEFAULT 'all',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 6. PARENT WORKFLOWS (TABLES 15, 16, 17)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS parent_link_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    approver_id UUID NOT NULL REFERENCES profiles(id),
    approver_role user_role NOT NULL,
    id_document_name TEXT NOT NULL,
    ocr_extracted_name TEXT,
    ocr_match BOOLEAN,
    status link_status NOT NULL DEFAULT 'pending',
    decision_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS leave_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    end_date DATE,
    reason TEXT NOT NULL,
    attachment_name TEXT,
    status leave_status NOT NULL DEFAULT 'pending',
    approved_by UUID REFERENCES profiles(id),
    recipient_ids UUID[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS parent_meetings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES profiles(id),
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    type meeting_type NOT NULL,
    time TIMESTAMPTZ NOT NULL,
    status meeting_status NOT NULL DEFAULT 'pending',
    reschedule_proposed_time TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 7. MESSAGING & CHAT (TABLES 18, 19)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    participant_ids UUID[] NOT NULL,
    title TEXT,
    is_group BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_message_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id),
    body TEXT NOT NULL,
    attachment_url TEXT,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    read_by UUID[] DEFAULT '{}'
);

-- ------------------------------------------------------------------------------
-- 8. EDUCATIONAL LIBRARY & MINISTERIAL EXAMS (TABLES 20, 21, 22)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ministerial_exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stage school_stage NOT NULL,
    grade INT NOT NULL,
    subject_id TEXT NOT NULL REFERENCES subjects(id),
    year INT NOT NULL,
    round INT NOT NULL CHECK (round IN (1, 2, 3)),
    has_model_answer BOOLEAN NOT NULL DEFAULT FALSE,
    questions_file_name TEXT NOT NULL,
    questions_file_url TEXT NOT NULL,
    answers_file_name TEXT,
    answers_file_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS library_resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    stage school_stage NOT NULL,
    grade INT NOT NULL,
    subject_id TEXT NOT NULL REFERENCES subjects(id),
    author_teacher_name TEXT NOT NULL,
    author_teacher_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    resource_type TEXT NOT NULL, -- 'summary', 'curriculum_book', 'notes'
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    extracted_text TEXT NOT NULL DEFAULT '',
    removed_by_owner BOOLEAN NOT NULL DEFAULT FALSE,
    removal_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS library_favorites (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    resource_id UUID NOT NULL REFERENCES library_resources(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, resource_id)
);

-- ------------------------------------------------------------------------------
-- 9. SUBSCRIPTIONS & MASTERCARD (TABLES 23, 24, 25, 26)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS subscription_plans (
    id TEXT PRIMARY KEY,
    role user_role NOT NULL,
    price_iqd INT NOT NULL,
    duration_days INT NOT NULL DEFAULT 30, -- Strictly Monthly (30 days)
    trial_days INT NOT NULL DEFAULT 7,     -- Strictly 7 days free trial
    effective_from TIMESTAMPTZ NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    plan_id TEXT NOT NULL REFERENCES subscription_plans(id),
    status subscription_status NOT NULL DEFAULT 'trial',
    started_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    locked_price_iqd INT NOT NULL,
    auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Payments table: NEVER stores full card numbers or CVV.
-- Only tokenized gateway references and last 4 digits for billing records.
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount_iqd INT NOT NULL,
    status payment_status NOT NULL,
    card_last4 TEXT NOT NULL, -- Mastercard tokenized last 4 digits only
    provider_ref TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS discounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    percent INT NOT NULL CHECK (percent > 0 AND percent <= 100),
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    roles user_role[] DEFAULT '{manager, teacher, instructor}',
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS manual_extensions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    days INT NOT NULL,
    reason TEXT NOT NULL,
    granted_by UUID NOT NULL REFERENCES profiles(id),
    is_free_grant BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 10. SECURITY, AUDIT & SESSIONS (TABLES 28, 29)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS device_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    device_name TEXT NOT NULL,
    platform TEXT NOT NULL,
    city TEXT,
    last_active TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_current BOOLEAN NOT NULL DEFAULT FALSE
);

-- Trigger: Limit to max 2 simultaneous devices per account
-- Concurrency-Safe: Serializes concurrent device registrations per user via row-level lock
-- and atomically evicts the oldest session to guarantee strictly <= 2 devices.
CREATE OR REPLACE FUNCTION check_device_limit()
RETURNS TRIGGER AS $$
DECLARE
    v_count INT;
BEGIN
    -- 1. Serialize concurrent logins for this user using an exclusive row lock on profiles
    PERFORM 1 FROM profiles WHERE id = NEW.user_id FOR UPDATE;

    -- 2. Count active devices under exclusive lock
    SELECT COUNT(*) INTO v_count FROM device_sessions WHERE user_id = NEW.user_id;

    -- 3. If 2 or more devices exist, evict the oldest device atomically
    IF v_count >= 2 THEN
        DELETE FROM device_sessions 
        WHERE id = (
            SELECT id FROM device_sessions 
            WHERE user_id = NEW.user_id 
            ORDER BY last_active ASC 
            LIMIT 1
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS trg_device_limit ON device_sessions;
CREATE TRIGGER trg_device_limit
BEFORE INSERT ON device_sessions
FOR EACH ROW EXECUTE FUNCTION check_device_limit();

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id UUID NOT NULL REFERENCES profiles(id),
    action TEXT NOT NULL,
    target TEXT NOT NULL,
    reason TEXT,
    at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

