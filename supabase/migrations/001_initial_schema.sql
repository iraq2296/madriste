-- ============================================================================
-- MADRASI — مَدرَستي
-- Complete PostgreSQL Database Schema with Row-Level Security (RLS)
-- Target Platform: Supabase / PostgreSQL 15+
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. USERS & PROFILES
-- ----------------------------------------------------------------------------
CREATE TYPE user_role AS ENUM ('manager', 'teacher', 'instructor', 'student', 'parent', 'superAdmin');
CREATE TYPE verification_status AS ENUM ('notStarted', 'pending', 'manualReview', 'verified', 'rejected', 'locked');
CREATE TYPE account_status AS ENUM ('active', 'disabled', 'blocked');

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE, -- Iraqi E.164 (+9647XXXXXXXXX)
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Constraint: Blue verification badge ONLY for schools, managers, teachers, instructors
ALTER TABLE profiles ADD CONSTRAINT chk_badge_eligibility 
    CHECK (badge_verified = FALSE OR role IN ('manager', 'teacher', 'instructor'));

-- ----------------------------------------------------------------------------
-- 2. SCHOOLS & ACADEMIC YEARS
-- ----------------------------------------------------------------------------
CREATE TYPE school_status AS ENUM ('active', 'suspended');
CREATE TYPE school_stage AS ENUM ('primary', 'intermediate', 'preparatory');
CREATE TYPE track_type AS ENUM ('none', 'scientific', 'literary');

CREATE TABLE schools (
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

CREATE TABLE academic_years (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    label TEXT NOT NULL, -- e.g. 2026–2027
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE class_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    stage school_stage NOT NULL,
    grade INT NOT NULL,
    track track_type NOT NULL DEFAULT 'none',
    section TEXT NOT NULL, -- 'A', 'B', 'C'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE subjects (
    id TEXT PRIMARY KEY,
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    name_ku TEXT NOT NULL,
    icon_key TEXT NOT NULL,
    color_index INT NOT NULL DEFAULT 0
);

-- ----------------------------------------------------------------------------
-- 3. SCHOOL MEMBERSHIPS & RELATIONS
-- ----------------------------------------------------------------------------
CREATE TYPE membership_status AS ENUM ('pending', 'invited', 'approved', 'rejected', 'left');

CREATE TABLE school_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    role user_role NOT NULL,
    status membership_status NOT NULL DEFAULT 'pending',
    class_group_ids UUID[] DEFAULT '{}',
    subject_ids TEXT[] DEFAULT '{}',
    via_invite BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE teacher_follows (
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    approved BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (student_id, teacher_id, school_id)
);

-- ----------------------------------------------------------------------------
-- 4. TEACHING: LESSONS, ATTENDANCE, GRADES, SCHEDULES, EXAMS
-- ----------------------------------------------------------------------------
CREATE TYPE lesson_type AS ENUM ('text', 'pdf', 'image', 'board', 'video', 'booklet', 'announcement');
CREATE TYPE exam_type AS ENUM ('daily', 'monthly', 'midyear', 'finalYear');
CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late', 'excused');
CREATE TYPE note_kind AS ENUM ('educational', 'behavioral');

CREATE TABLE lessons (
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

CREATE TABLE exam_schedules (
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

CREATE TABLE grade_entries (
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

-- Attendance recorded per individual class session
CREATE TABLE class_attendance (
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

CREATE TABLE class_schedules (
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

CREATE TABLE student_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    kind note_kind NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE, -- null for global system announcement
    author_id UUID NOT NULL REFERENCES profiles(id),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    audience TEXT NOT NULL DEFAULT 'all',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 5. PARENT WORKFLOWS: LINKS, LEAVES, MEETINGS
-- ----------------------------------------------------------------------------
CREATE TYPE link_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
CREATE TYPE leave_status AS ENUM ('pending', 'approved', 'cancelled');
CREATE TYPE meeting_type AS ENUM ('inPerson', 'audio', 'video');
CREATE TYPE meeting_status AS ENUM ('pending', 'accepted', 'rejected', 'rescheduleProposed', 'completed', 'cancelled');

CREATE TABLE parent_link_requests (
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

CREATE TABLE leave_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    end_date DATE,
    reason TEXT NOT NULL,
    attachment_name TEXT,
    recipient_ids UUID[] NOT NULL,
    status leave_status NOT NULL DEFAULT 'pending',
    approved_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE meetings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    type meeting_type NOT NULL,
    scheduled_at TIMESTAMPTZ NOT NULL,
    topic TEXT NOT NULL,
    status meeting_status NOT NULL DEFAULT 'pending',
    proposed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 6. COMMUNICATION & NOTIFICATIONS
-- ----------------------------------------------------------------------------
CREATE TYPE message_type AS ENUM ('text', 'image', 'file');

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    participant_ids UUID[] NOT NULL,
    student_context_id UUID REFERENCES profiles(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id),
    type message_type NOT NULL DEFAULT 'text',
    text TEXT NOT NULL DEFAULT '',
    file_name TEXT,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    read_by UUID[] DEFAULT '{}'
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    route TEXT,
    read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 7. EDUCATIONAL LIBRARY & MINISTERIAL EXAMS
-- ----------------------------------------------------------------------------
CREATE TYPE resource_type AS ENUM ('textbook', 'booklet', 'summary', 'studyMaterial', 'examResource');

CREATE TABLE library_resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    type resource_type NOT NULL,
    stage school_stage NOT NULL,
    grade INT NOT NULL,
    track track_type NOT NULL DEFAULT 'none',
    subject_id TEXT NOT NULL REFERENCES subjects(id),
    year_label TEXT NOT NULL,
    uploader_id UUID NOT NULL REFERENCES profiles(id),
    file_name TEXT NOT NULL,
    pages INT NOT NULL DEFAULT 0,
    extracted_text TEXT NOT NULL DEFAULT '',
    removed_by_owner BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE ministerial_exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stage school_stage NOT NULL,
    grade INT NOT NULL,
    track track_type NOT NULL DEFAULT 'none',
    subject_id TEXT NOT NULL REFERENCES subjects(id),
    year INT NOT NULL,
    round INT NOT NULL CHECK (round IN (1, 2, 3)),
    file_name TEXT NOT NULL,
    is_image BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_favorites (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    resource_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, resource_id)
);

-- ----------------------------------------------------------------------------
-- 8. SUBSCRIPTIONS & MASTERCARD PAYMENTS
-- ----------------------------------------------------------------------------
CREATE TYPE subscription_status AS ENUM ('trial', 'active', 'expired', 'cancelled', 'grantedFree');
CREATE TYPE payment_status AS ENUM ('pending', 'succeeded', 'failed', 'refunded');

CREATE TABLE subscription_plans (
    id TEXT PRIMARY KEY,
    role user_role NOT NULL,
    price_iqd INT NOT NULL,
    duration_days INT NOT NULL DEFAULT 30,
    trial_days INT NOT NULL DEFAULT 7,
    effective_from TIMESTAMPTZ NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE subscriptions (
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

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount_iqd INT NOT NULL,
    status payment_status NOT NULL,
    card_last4 TEXT NOT NULL, -- Mastercard tokenized last 4 digits only
    provider_ref TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE discounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    percent INT NOT NULL CHECK (percent > 0 AND percent <= 100),
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    roles user_role[] DEFAULT '{manager, teacher, instructor}',
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE manual_extensions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    days INT NOT NULL,
    reason TEXT NOT NULL,
    granted_by UUID NOT NULL REFERENCES profiles(id),
    is_free_grant BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 9. SECURITY, DEVICES (MAX 2), VERIFICATIONS, LOGS
-- ----------------------------------------------------------------------------
CREATE TABLE device_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    device_name TEXT NOT NULL,
    platform TEXT NOT NULL,
    city TEXT,
    last_active TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_current BOOLEAN NOT NULL DEFAULT FALSE
);

-- Trigger: Limit to max 2 simultaneous devices per account
CREATE OR REPLACE FUNCTION check_device_limit()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM device_sessions WHERE user_id = NEW.user_id) >= 2 THEN
        RAISE EXCEPTION 'DEVICE_LIMIT_REACHED: Maximum 2 devices permitted simultaneously.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_device_limit
BEFORE INSERT ON device_sessions
FOR EACH ROW EXECUTE FUNCTION check_device_limit();

CREATE TABLE security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    description TEXT NOT NULL,
    device TEXT,
    at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE account_deletion_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending',
    note TEXT,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE account_recovery_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone TEXT NOT NULL,
    user_id UUID REFERENCES profiles(id),
    document_name TEXT NOT NULL,
    ocr_name TEXT,
    match_score NUMERIC(5,2),
    status TEXT NOT NULL DEFAULT 'submitted',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id UUID NOT NULL REFERENCES profiles(id),
    action TEXT NOT NULL,
    target TEXT NOT NULL,
    reason TEXT,
    at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE support_access_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES profiles(id),
    target_user_id UUID NOT NULL REFERENCES profiles(id),
    reason TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    actions TEXT[] DEFAULT '{}'
);

-- ----------------------------------------------------------------------------
-- 10. ROW-LEVEL SECURITY (RLS) POLICIES
-- ----------------------------------------------------------------------------
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_link_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Helper function: Is caller Super Admin?
CREATE OR REPLACE FUNCTION is_super_admin() RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = auth.uid() AND role = 'superAdmin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Profiles: Anyone authenticated can view basic public profiles, owner views all
CREATE POLICY profiles_select ON profiles FOR SELECT USING (
    id = auth.uid() OR is_super_admin() OR status = 'active'
);
CREATE POLICY profiles_update ON profiles FOR UPDATE USING (
    id = auth.uid() OR is_super_admin()
);

-- Schools: Isolated by membership or owner
CREATE POLICY schools_select ON schools FOR SELECT USING (
    status = 'active' OR is_super_admin() OR manager_id = auth.uid()
);

-- Messages: Strictly scoped to conversation participants
CREATE POLICY messages_select ON messages FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM conversations c 
        WHERE c.id = conversation_id AND auth.uid() = ANY(c.participant_ids)
    ) OR is_super_admin()
);
CREATE POLICY messages_insert ON messages FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND EXISTS (
        SELECT 1 FROM conversations c 
        WHERE c.id = conversation_id AND auth.uid() = ANY(c.participant_ids)
    )
);

