-- ==============================================================================
-- MADRASI — Security hardening follow-up (additive migration 004)
-- Review branch only. NOT executed against any database.
-- PostgreSQL 15+ / Supabase.
-- ==============================================================================
-- This migration is intentionally additive: it does not drop tables or data.
-- Apply only after review, in a disposable test database first.

-- 1) Fail closed for self-service profile creation. Self-registration may create
--    student/parent profiles only. Staff/admin profiles must be provisioned by
--    a trusted service role or an existing superAdmin.
CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_caller_role public.user_role;
    v_is_service_role boolean := coalesce(auth.role(), '') = 'service_role';
BEGIN
    SELECT p.role INTO v_caller_role
    FROM public.profiles AS p
    WHERE p.id = auth.uid();

    IF TG_OP = 'INSERT' THEN
        IF v_is_service_role OR v_caller_role = 'superAdmin' THEN
            RETURN NEW;
        END IF;

        IF NEW.id IS DISTINCT FROM auth.uid() THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: profile id must match authenticated user';
        END IF;

        IF NEW.role NOT IN ('student', 'parent') THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: staff and administrative roles require trusted provisioning';
        END IF;

        NEW.badge_verified := FALSE;
        NEW.verification := 'pending';
        NEW.status := 'active';
        NEW.status_reason := NULL;
        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF v_is_service_role OR v_caller_role = 'superAdmin' THEN
            RETURN NEW;
        END IF;

        IF NEW.id IS DISTINCT FROM OLD.id
           OR NEW.role IS DISTINCT FROM OLD.role
           OR NEW.badge_verified IS DISTINCT FROM OLD.badge_verified
           OR NEW.verification IS DISTINCT FROM OLD.verification
           OR NEW.status IS DISTINCT FROM OLD.status
           OR NEW.status_reason IS DISTINCT FROM OLD.status_reason THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: protected profile fields cannot be changed by this caller';
        END IF;
        RETURN NEW;
    END IF;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.protect_profile_sensitive_fields() FROM PUBLIC, anon, authenticated;

-- 2) Membership invariants: a self-join is always pending and cannot select a
--    role. Managers can manage memberships only within the same school and
--    cannot move a membership between schools or change its subject identity.
CREATE OR REPLACE FUNCTION public.enforce_membership_initial_state()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_caller_role public.user_role;
    v_manager_of_old boolean := false;
BEGIN
    SELECT p.role INTO v_caller_role
    FROM public.profiles AS p
    WHERE p.id = auth.uid();

    IF TG_OP = 'INSERT' THEN
        IF v_caller_role = 'superAdmin' OR coalesce(auth.role(), '') = 'service_role' THEN
            IF NEW.role = 'superAdmin' THEN
                RAISE EXCEPTION 'SECURITY_VIOLATION: superAdmin cannot be assigned through memberships';
            END IF;
            RETURN NEW;
        END IF;

        IF public.auth_is_manager_of_school(NEW.school_id) THEN
            IF NEW.role NOT IN ('teacher', 'instructor', 'student', 'parent')
               OR NEW.status NOT IN ('pending', 'invited') THEN
                RAISE EXCEPTION 'SECURITY_VIOLATION: invalid manager-created membership';
            END IF;
            RETURN NEW;
        END IF;

        NEW.user_id := auth.uid();
        NEW.status := 'pending';
        SELECT p.role INTO NEW.role
        FROM public.profiles AS p
        WHERE p.id = auth.uid();
        NEW.class_group_ids := ARRAY[]::uuid[];
        NEW.subject_ids := ARRAY[]::text[];
        NEW.via_invite := FALSE;
        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF v_caller_role = 'superAdmin' OR coalesce(auth.role(), '') = 'service_role' THEN
            RETURN NEW;
        END IF;

        v_manager_of_old := public.auth_is_manager_of_school(OLD.school_id);
        IF NOT v_manager_of_old
           OR NEW.school_id IS DISTINCT FROM OLD.school_id
           OR NEW.user_id IS DISTINCT FROM OLD.user_id THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: membership identity and school are immutable to this caller';
        END IF;

        IF NEW.role NOT IN ('teacher', 'instructor', 'student', 'parent')
           OR NEW.status NOT IN ('pending', 'invited', 'approved', 'rejected', 'left') THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: invalid membership role or status';
        END IF;
        RETURN NEW;
    END IF;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_membership_initial_state() FROM PUBLIC, anon, authenticated;

-- 3) Prevent cross-school row relocation and require a currently approved
--    teaching membership for teacher edits, not merely a matching teacher_id.
DROP POLICY IF EXISTS p_grades_update ON public.grade_entries;
CREATE POLICY p_grades_update ON public.grade_entries
FOR UPDATE
USING (
    (teacher_id = auth.uid()
     AND public.auth_is_member_of_school(school_id)
     AND public.auth_user_school_role(school_id) IN ('teacher', 'instructor')
     AND public.auth_has_active_subscription())
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
)
WITH CHECK (
    (teacher_id = auth.uid()
     AND public.auth_is_member_of_school(school_id)
     AND public.auth_user_school_role(school_id) IN ('teacher', 'instructor')
     AND public.auth_has_active_subscription())
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
);

DROP POLICY IF EXISTS p_grades_delete ON public.grade_entries;
CREATE POLICY p_grades_delete ON public.grade_entries
FOR DELETE USING (
    (teacher_id = auth.uid()
     AND public.auth_is_member_of_school(school_id)
     AND public.auth_user_school_role(school_id) IN ('teacher', 'instructor')
     AND public.auth_has_active_subscription())
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
);

DROP POLICY IF EXISTS p_attendance_update ON public.class_attendance;
CREATE POLICY p_attendance_update ON public.class_attendance
FOR UPDATE
USING (
    (teacher_id = auth.uid()
     AND public.auth_is_member_of_school(school_id)
     AND public.auth_user_school_role(school_id) IN ('teacher', 'instructor')
     AND public.auth_has_active_subscription())
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
)
WITH CHECK (
    (teacher_id = auth.uid()
     AND public.auth_is_member_of_school(school_id)
     AND public.auth_user_school_role(school_id) IN ('teacher', 'instructor')
     AND public.auth_has_active_subscription())
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
);

DROP POLICY IF EXISTS p_lessons_update ON public.lessons;
CREATE POLICY p_lessons_update ON public.lessons
FOR UPDATE
USING (
    (teacher_id = auth.uid()
     AND public.auth_is_member_of_school(school_id)
     AND public.auth_user_school_role(school_id) IN ('teacher', 'instructor')
     AND public.auth_has_active_subscription())
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
)
WITH CHECK (
    (teacher_id = auth.uid()
     AND public.auth_is_member_of_school(school_id)
     AND public.auth_user_school_role(school_id) IN ('teacher', 'instructor')
     AND public.auth_has_active_subscription())
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
);

DROP POLICY IF EXISTS p_lessons_delete ON public.lessons;
CREATE POLICY p_lessons_delete ON public.lessons
FOR DELETE USING (
    (teacher_id = auth.uid()
     AND public.auth_is_member_of_school(school_id)
     AND public.auth_user_school_role(school_id) IN ('teacher', 'instructor')
     AND public.auth_has_active_subscription())
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
);

-- 4) Make the public directory execute with the caller's privileges so it
--    cannot accidentally bypass profiles RLS through view-owner privileges.
CREATE OR REPLACE VIEW public.public_profiles
WITH (security_invoker = true)
AS
SELECT
    id, full_name, role, photo_url, badge_verified, governorate,
    specialization, subject_ids, teacher_code, created_at
FROM public.profiles
WHERE status = 'active';

GRANT SELECT ON public.public_profiles TO authenticated;

-- 5) Explicitly prevent direct client writes to payment records and audit logs.
--    Existing SELECT policies remain unchanged.
REVOKE INSERT, UPDATE, DELETE ON public.payments FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.audit_logs FROM anon, authenticated;

-- End of additive hardening migration. No statements here have been executed.
