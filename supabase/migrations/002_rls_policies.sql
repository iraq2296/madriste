-- ==============================================================================
-- MADRASI — مَدرَستي
-- Migration 002: Row-Level Security (RLS) Policies & Database-Enforced Authorization
-- IMPORTANT SECURITY RULE:
-- Roles and permissions are evaluated STRICTLY against the trusted 'profiles' and
-- 'school_memberships' tables. NEVER from JWT claims or client-provided user_metadata.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. TRUSTED SECURITY HELPER FUNCTIONS (SECURITY DEFINER)
-- Hardened with explicit search_path and restricted execute permissions
-- ------------------------------------------------------------------------------

-- Get current authenticated user's verified role directly from the profiles table
CREATE OR REPLACE FUNCTION auth_user_role()
RETURNS user_role AS $$
    SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp;

-- Check if current authenticated user is Super Admin
CREATE OR REPLACE FUNCTION auth_is_super_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'superAdmin'
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp;

-- Check if current authenticated user is an approved member of a given school
CREATE OR REPLACE FUNCTION auth_is_member_of_school(p_school_id UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM school_memberships 
        WHERE user_id = auth.uid() 
          AND school_id = p_school_id 
          AND status = 'approved'
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp;

-- Get current user's role in a specific school (e.g. for multi-school teachers)
CREATE OR REPLACE FUNCTION auth_user_school_role(p_school_id UUID)
RETURNS user_role AS $$
    SELECT role FROM school_memberships 
    WHERE user_id = auth.uid() 
      AND school_id = p_school_id 
      AND status = 'approved'
    LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp;

-- Check if current user is the manager of a given school
CREATE OR REPLACE FUNCTION auth_is_manager_of_school(p_school_id UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM schools 
        WHERE id = p_school_id 
          AND manager_id = auth.uid()
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp;

-- Check if current user is an approved linked parent of a given student
CREATE OR REPLACE FUNCTION auth_is_linked_parent_of(p_student_id UUID)
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM parent_link_requests 
        WHERE parent_id = auth.uid() 
          AND student_id = p_student_id 
          AND status = 'approved'
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp;

-- Check if current user has an active, usable subscription (or is student/parent)
CREATE OR REPLACE FUNCTION auth_has_active_subscription()
RETURNS BOOLEAN AS $$
DECLARE
    v_role user_role;
BEGIN
    SELECT role INTO v_role FROM profiles WHERE id = auth.uid();
    -- Students and Parents are permanently free
    IF v_role IN ('student', 'parent') THEN
        RETURN TRUE;
    END IF;
    -- Paid roles require active or trial subscription
    RETURN EXISTS (
        SELECT 1 FROM subscriptions 
        WHERE user_id = auth.uid() 
          AND (status = 'active' OR status = 'trial' OR status = 'grantedFree')
          AND ends_at > NOW()
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, pg_temp;

-- Revoke default public execution and grant to authenticated role only
REVOKE ALL ON FUNCTION auth_user_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION auth_user_role() TO authenticated;

REVOKE ALL ON FUNCTION auth_is_super_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION auth_is_super_admin() TO authenticated;

REVOKE ALL ON FUNCTION auth_is_member_of_school(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION auth_is_member_of_school(UUID) TO authenticated;

REVOKE ALL ON FUNCTION auth_user_school_role(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION auth_user_school_role(UUID) TO authenticated;

REVOKE ALL ON FUNCTION auth_is_manager_of_school(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION auth_is_manager_of_school(UUID) TO authenticated;

REVOKE ALL ON FUNCTION auth_is_linked_parent_of(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION auth_is_linked_parent_of(UUID) TO authenticated;

REVOKE ALL ON FUNCTION auth_has_active_subscription() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION auth_has_active_subscription() TO authenticated;

-- ------------------------------------------------------------------------------
-- 2. ENABLE RLS ON ALL TABLES
-- ------------------------------------------------------------------------------
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_link_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE ministerial_exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE library_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE library_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE manual_extensions ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 3. PROFILES POLICIES & PRIVACY PROTECTION
-- ------------------------------------------------------------------------------
-- Full record containing phone number and administrative status is strictly private.
-- Only the user themselves, superAdmin, or an authorized school manager can read it.
DROP POLICY IF EXISTS p_profiles_select ON profiles;
CREATE POLICY p_profiles_select ON profiles FOR SELECT USING (
    id = auth.uid() 
    OR auth_is_super_admin() 
    OR EXISTS (
        SELECT 1 FROM school_memberships sm 
        JOIN schools s ON s.id = sm.school_id 
        WHERE sm.user_id = profiles.id 
          AND s.manager_id = auth.uid() 
          AND sm.status = 'approved'
    )
);

-- Public Directory View: Safe for student/teacher colleague lookups.
-- Completely strips phone numbers, status reasons, and private account metadata.
CREATE OR REPLACE VIEW public_profiles AS
SELECT 
    id,
    full_name,
    role,
    photo_url,
    badge_verified,
    governorate,
    specialization,
    subject_ids,
    teacher_code,
    created_at
FROM profiles
WHERE status = 'active';

GRANT SELECT ON public_profiles TO authenticated;

DROP POLICY IF EXISTS p_profiles_insert ON profiles;
CREATE POLICY p_profiles_insert ON profiles FOR INSERT WITH CHECK (
    id = auth.uid()
);

DROP POLICY IF EXISTS p_profiles_update ON profiles;
CREATE POLICY p_profiles_update ON profiles FOR UPDATE USING (
    id = auth.uid() OR auth_is_super_admin()
) WITH CHECK (
    id = auth.uid() OR auth_is_super_admin()
);

-- ------------------------------------------------------------------------------
-- 4. SCHOOLS & ACADEMIC YEARS POLICIES
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS p_schools_select ON schools;
CREATE POLICY p_schools_select ON schools FOR SELECT USING (
    status = 'active' OR manager_id = auth.uid() OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_schools_insert ON schools;
CREATE POLICY p_schools_insert ON schools FOR INSERT WITH CHECK (
    manager_id = auth.uid() OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_schools_update ON schools;
CREATE POLICY p_schools_update ON schools FOR UPDATE USING (
    manager_id = auth.uid() OR auth_is_super_admin()
);

-- Academic Years: Scoped to school members
DROP POLICY IF EXISTS p_years_select ON academic_years;
CREATE POLICY p_years_select ON academic_years FOR SELECT USING (
    auth_is_member_of_school(school_id) OR auth_is_manager_of_school(school_id) OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_years_modify ON academic_years;
CREATE POLICY p_years_modify ON academic_years FOR ALL USING (
    auth_is_manager_of_school(school_id) OR auth_is_super_admin()
);

-- Class Groups: Scoped to school members
DROP POLICY IF EXISTS p_cgroups_select ON class_groups;
CREATE POLICY p_cgroups_select ON class_groups FOR SELECT USING (
    auth_is_member_of_school(school_id) OR auth_is_manager_of_school(school_id) OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_cgroups_modify ON class_groups;
CREATE POLICY p_cgroups_modify ON class_groups FOR ALL USING (
    auth_is_manager_of_school(school_id) OR auth_is_super_admin()
);

-- Subjects: Public catalog readable by all authenticated users
DROP POLICY IF EXISTS p_subjects_select ON subjects;
CREATE POLICY p_subjects_select ON subjects FOR SELECT USING (true);

-- ------------------------------------------------------------------------------
-- 5. SCHOOL MEMBERSHIPS (MULTI-TENANCY CORE)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS p_memberships_select ON school_memberships;
CREATE POLICY p_memberships_select ON school_memberships FOR SELECT USING (
    user_id = auth.uid() 
    OR auth_is_manager_of_school(school_id) 
    OR auth_is_member_of_school(school_id) 
    OR auth_is_super_admin()
);

-- Users can submit their own join requests (strictly forced to status = 'pending')
DROP POLICY IF EXISTS p_memberships_insert ON school_memberships;
CREATE POLICY p_memberships_insert ON school_memberships FOR INSERT WITH CHECK (
    user_id = auth.uid() AND status = 'pending'
);

-- Only the school manager or super admin can approve/reject membership
DROP POLICY IF EXISTS p_memberships_update ON school_memberships;
CREATE POLICY p_memberships_update ON school_memberships FOR UPDATE USING (
    auth_is_manager_of_school(school_id) OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_memberships_delete ON school_memberships;
CREATE POLICY p_memberships_delete ON school_memberships FOR DELETE USING (
    user_id = auth.uid() OR auth_is_manager_of_school(school_id) OR auth_is_super_admin()
);

-- ------------------------------------------------------------------------------
-- 6. GRADE ENTRIES (STRICT ISOLATION & REJECTION OF UNAUTHORIZED WRITES)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS p_grades_select ON grade_entries;
CREATE POLICY p_grades_select ON grade_entries FOR SELECT USING (
    student_id = auth.uid() -- Student sees only own grades
    OR auth_is_linked_parent_of(student_id) -- Parent sees only approved linked child's grades
    OR (auth_is_member_of_school(school_id) AND auth_user_school_role(school_id) IN ('teacher', 'instructor', 'manager'))
    OR auth_is_manager_of_school(school_id)
    OR auth_is_super_admin()
);

-- ONLY teachers/instructors of that school with an active subscription can INSERT grades.
-- Students attempting an INSERT are strictly DENIED by PostgreSQL!
DROP POLICY IF EXISTS p_grades_insert ON grade_entries;
CREATE POLICY p_grades_insert ON grade_entries FOR INSERT WITH CHECK (
    teacher_id = auth.uid()
    AND auth_is_member_of_school(school_id)
    AND auth_user_school_role(school_id) IN ('teacher', 'instructor')
    AND auth_has_active_subscription()
);

-- ONLY the teacher who recorded the grade or the school manager can UPDATE
DROP POLICY IF EXISTS p_grades_update ON grade_entries;
CREATE POLICY p_grades_update ON grade_entries FOR UPDATE USING (
    (teacher_id = auth.uid() AND auth_has_active_subscription())
    OR auth_is_manager_of_school(school_id)
    OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_grades_delete ON grade_entries;
CREATE POLICY p_grades_delete ON grade_entries FOR DELETE USING (
    teacher_id = auth.uid() OR auth_is_manager_of_school(school_id) OR auth_is_super_admin()
);

-- ------------------------------------------------------------------------------
-- 7. CLASS ATTENDANCE (STRICT ISOLATION)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS p_attendance_select ON class_attendance;
CREATE POLICY p_attendance_select ON class_attendance FOR SELECT USING (
    student_id = auth.uid()
    OR auth_is_linked_parent_of(student_id)
    OR (auth_is_member_of_school(school_id) AND auth_user_school_role(school_id) IN ('teacher', 'instructor', 'manager'))
    OR auth_is_manager_of_school(school_id)
    OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_attendance_insert ON class_attendance;
CREATE POLICY p_attendance_insert ON class_attendance FOR INSERT WITH CHECK (
    teacher_id = auth.uid()
    AND auth_is_member_of_school(school_id)
    AND auth_user_school_role(school_id) IN ('teacher', 'instructor')
    AND auth_has_active_subscription()
);

DROP POLICY IF EXISTS p_attendance_update ON class_attendance;
CREATE POLICY p_attendance_update ON class_attendance FOR UPDATE USING (
    teacher_id = auth.uid() OR auth_is_manager_of_school(school_id) OR auth_is_super_admin()
);

-- ------------------------------------------------------------------------------
-- 8. LESSONS & CURRICULUM
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS p_lessons_select ON lessons;
CREATE POLICY p_lessons_select ON lessons FOR SELECT USING (
    auth_is_member_of_school(school_id) OR auth_is_manager_of_school(school_id) OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_lessons_insert ON lessons;
CREATE POLICY p_lessons_insert ON lessons FOR INSERT WITH CHECK (
    teacher_id = auth.uid()
    AND auth_is_member_of_school(school_id)
    AND auth_user_school_role(school_id) IN ('teacher', 'instructor')
    AND auth_has_active_subscription()
);

DROP POLICY IF EXISTS p_lessons_update ON lessons;
CREATE POLICY p_lessons_update ON lessons FOR UPDATE USING (
    (teacher_id = auth.uid() AND auth_has_active_subscription())
    OR auth_is_manager_of_school(school_id)
    OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_lessons_delete ON lessons;
CREATE POLICY p_lessons_delete ON lessons FOR DELETE USING (
    teacher_id = auth.uid() OR auth_is_manager_of_school(school_id) OR auth_is_super_admin()
);

-- ------------------------------------------------------------------------------
-- 9. PARENT LINK REQUESTS & LEAVES
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS p_parent_links_select ON parent_link_requests;
CREATE POLICY p_parent_links_select ON parent_link_requests FOR SELECT USING (
    parent_id = auth.uid() 
    OR auth_is_manager_of_school(school_id) 
    OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_parent_links_insert ON parent_link_requests;
CREATE POLICY p_parent_links_insert ON parent_link_requests FOR INSERT WITH CHECK (
    parent_id = auth.uid()
);

DROP POLICY IF EXISTS p_parent_links_update ON parent_link_requests;
CREATE POLICY p_parent_links_update ON parent_link_requests FOR UPDATE USING (
    auth_is_manager_of_school(school_id) OR approver_id = auth.uid() OR auth_is_super_admin()
);

-- Leave requests: Parent inserts, approved by ANY authorized recipient (manager or teacher)
DROP POLICY IF EXISTS p_leaves_select ON leave_requests;
CREATE POLICY p_leaves_select ON leave_requests FOR SELECT USING (
    parent_id = auth.uid()
    OR student_id = auth.uid()
    OR auth.uid() = ANY(recipient_ids)
    OR auth_is_manager_of_school(school_id)
    OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_leaves_insert ON leave_requests;
CREATE POLICY p_leaves_insert ON leave_requests FOR INSERT WITH CHECK (
    parent_id = auth.uid()
);

DROP POLICY IF EXISTS p_leaves_update ON leave_requests;
CREATE POLICY p_leaves_update ON leave_requests FOR UPDATE USING (
    auth.uid() = ANY(recipient_ids)
    OR auth_is_manager_of_school(school_id)
    OR auth_is_super_admin()
);

-- ------------------------------------------------------------------------------
-- 10. MESSAGING & CHAT (PARTICIPANTS ONLY)
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS p_convs_select ON conversations;
CREATE POLICY p_convs_select ON conversations FOR SELECT USING (
    auth.uid() = ANY(participant_ids) OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_convs_insert ON conversations;
CREATE POLICY p_convs_insert ON conversations FOR INSERT WITH CHECK (
    auth.uid() = ANY(participant_ids)
);

DROP POLICY IF EXISTS p_messages_select ON messages;
CREATE POLICY p_messages_select ON messages FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM conversations c 
        WHERE c.id = conversation_id AND auth.uid() = ANY(c.participant_ids)
    ) OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_messages_insert ON messages;
CREATE POLICY p_messages_insert ON messages FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND EXISTS (
        SELECT 1 FROM conversations c 
        WHERE c.id = conversation_id AND auth.uid() = ANY(c.participant_ids)
    )
);

-- ------------------------------------------------------------------------------
-- 11. ANNOUNCEMENTS & LIBRARY
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS p_announcements_select ON announcements;
CREATE POLICY p_announcements_select ON announcements FOR SELECT USING (
    school_id IS NULL -- Platform-wide
    OR auth_is_member_of_school(school_id)
    OR auth_is_manager_of_school(school_id)
    OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_announcements_insert ON announcements;
CREATE POLICY p_announcements_insert ON announcements FOR INSERT WITH CHECK (
    (school_id IS NOT NULL AND auth_is_manager_of_school(school_id))
    OR auth_is_super_admin()
);

-- Ministerial Exams: Public read
DROP POLICY IF EXISTS p_min_exams_select ON ministerial_exams;
CREATE POLICY p_min_exams_select ON ministerial_exams FOR SELECT USING (true);

-- Library Resources: Read public, write for verified teachers
DROP POLICY IF EXISTS p_library_select ON library_resources;
CREATE POLICY p_library_select ON library_resources FOR SELECT USING (
    removed_by_owner = FALSE OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_library_insert ON library_resources;
CREATE POLICY p_library_insert ON library_resources FOR INSERT WITH CHECK (
    author_teacher_id = auth.uid() AND auth_user_role() IN ('teacher', 'instructor')
);

-- ------------------------------------------------------------------------------
-- 12. SUBSCRIPTIONS & PAYMENTS
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS p_plans_select ON subscription_plans;
CREATE POLICY p_plans_select ON subscription_plans FOR SELECT USING (true);

DROP POLICY IF EXISTS p_subs_select ON subscriptions;
CREATE POLICY p_subs_select ON subscriptions FOR SELECT USING (
    user_id = auth.uid() OR auth_is_super_admin()
);

-- Payments: User views own payment history, inserts only via secure webhook/functions
DROP POLICY IF EXISTS p_payments_select ON payments;
CREATE POLICY p_payments_select ON payments FOR SELECT USING (
    user_id = auth.uid() OR auth_is_super_admin()
);

-- Device Sessions: User manages own devices
DROP POLICY IF EXISTS p_devices_select ON device_sessions;
CREATE POLICY p_devices_select ON device_sessions FOR SELECT USING (
    user_id = auth.uid() OR auth_is_super_admin()
);

DROP POLICY IF EXISTS p_devices_modify ON device_sessions;
CREATE POLICY p_devices_modify ON device_sessions FOR ALL USING (
    user_id = auth.uid()
);

