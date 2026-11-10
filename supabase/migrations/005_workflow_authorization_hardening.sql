-- ==============================================================================
-- MADRASI — Security hardening migration 005
-- Additive, review branch only. NOT executed against any database.
-- Requires migrations 001–004.
-- ==============================================================================
-- 1. Verify that a proposed approver is genuinely authorized for this school.
CREATE OR REPLACE FUNCTION public.auth_is_school_workflow_staff(
    p_school_id uuid,
    p_user_id uuid
) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.schools s
        WHERE s.id = p_school_id AND s.manager_id = p_user_id
    ) OR EXISTS (
        SELECT 1 FROM public.school_memberships sm
        WHERE sm.school_id = p_school_id
          AND sm.user_id = p_user_id
          AND sm.status = 'approved'
          AND sm.role IN ('teacher', 'instructor', 'manager')
    );
$$;
REVOKE ALL ON FUNCTION public.auth_is_school_workflow_staff(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.auth_is_school_workflow_staff(uuid, uuid) TO authenticated;

-- 2. Parent-link requests: clients cannot forge OCR outcomes, identity fields,
--    or approve their own request. Only the named, currently authorized staff
--    member (or school manager / super admin) can decide it.
CREATE OR REPLACE FUNCTION public.guard_parent_link_request()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_service boolean := coalesce(auth.role(), '') = 'service_role';
BEGIN
    IF v_service OR public.auth_is_super_admin() THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.parent_id IS DISTINCT FROM auth.uid()
           OR NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = NEW.parent_id AND p.role = 'parent')
           OR NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = NEW.student_id AND p.role = 'student')
           OR NOT public.auth_is_school_workflow_staff(NEW.school_id, NEW.approver_id) THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: invalid parent link request or approver';
        END IF;
        NEW.status := 'pending';
        NEW.ocr_extracted_name := NULL;
        NEW.ocr_match := NULL;
        NEW.decision_note := NULL;
        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF NEW.parent_id IS DISTINCT FROM OLD.parent_id
           OR NEW.student_id IS DISTINCT FROM OLD.student_id
           OR NEW.school_id IS DISTINCT FROM OLD.school_id
           OR NEW.approver_id IS DISTINCT FROM OLD.approver_id
           OR NEW.approver_role IS DISTINCT FROM OLD.approver_role
           OR NEW.id_document_name IS DISTINCT FROM OLD.id_document_name
           OR NEW.created_at IS DISTINCT FROM OLD.created_at
           OR OLD.status <> 'pending'
           OR NEW.status NOT IN ('approved', 'rejected') THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: immutable request fields or invalid decision transition';
        END IF;
        IF auth.uid() IS DISTINCT FROM OLD.approver_id
           AND NOT public.auth_is_manager_of_school(OLD.school_id) THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: only the assigned approver or school manager may decide';
        END IF;
        RETURN NEW;
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.guard_parent_link_request() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS trg_guard_parent_link_request ON public.parent_link_requests;
CREATE TRIGGER trg_guard_parent_link_request
BEFORE INSERT OR UPDATE ON public.parent_link_requests
FOR EACH ROW EXECUTE FUNCTION public.guard_parent_link_request();

DROP POLICY IF EXISTS p_parent_links_insert ON public.parent_link_requests;
CREATE POLICY p_parent_links_insert ON public.parent_link_requests
FOR INSERT WITH CHECK (
    parent_id = auth.uid()
    AND public.auth_is_school_workflow_staff(school_id, approver_id)
);
DROP POLICY IF EXISTS p_parent_links_update ON public.parent_link_requests;
CREATE POLICY p_parent_links_update ON public.parent_link_requests
FOR UPDATE
USING (
    (approver_id = auth.uid() AND public.auth_is_school_workflow_staff(school_id, auth.uid()))
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
)
WITH CHECK (
    (approver_id = auth.uid() AND public.auth_is_school_workflow_staff(school_id, auth.uid()))
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
);

-- 3. Leave requests: require an approved parent-child link to create a request.
--    A decision can only be made by a school manager or approved school staff
--    listed as a recipient; the trigger prevents changing request identity.
CREATE OR REPLACE FUNCTION public.guard_leave_request()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF coalesce(auth.role(), '') = 'service_role' OR public.auth_is_super_admin() THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.parent_id IS DISTINCT FROM auth.uid()
           OR NOT public.auth_is_linked_parent_of(NEW.student_id)
           OR NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = NEW.parent_id AND p.role = 'parent')
           OR NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = NEW.student_id AND p.role = 'student') THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: leave request requires an approved parent-child link';
        END IF;
        NEW.status := 'pending';
        NEW.approved_by := NULL;
        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF NEW.parent_id IS DISTINCT FROM OLD.parent_id
           OR NEW.student_id IS DISTINCT FROM OLD.student_id
           OR NEW.school_id IS DISTINCT FROM OLD.school_id
           OR NEW.date IS DISTINCT FROM OLD.date
           OR NEW.end_date IS DISTINCT FROM OLD.end_date
           OR NEW.reason IS DISTINCT FROM OLD.reason
           OR NEW.recipient_ids IS DISTINCT FROM OLD.recipient_ids
           OR NEW.created_at IS DISTINCT FROM OLD.created_at
           OR OLD.status <> 'pending'
           OR NEW.status NOT IN ('approved', 'cancelled') THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: immutable leave request fields or invalid transition';
        END IF;
        IF NOT (auth.uid() = ANY(OLD.recipient_ids)
                AND public.auth_is_school_workflow_staff(OLD.school_id, auth.uid())) THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: only authorized recipients may decide leave requests';
        END IF;
        IF NEW.status = 'approved' THEN
            NEW.approved_by := auth.uid();
        ELSE
            NEW.approved_by := NULL;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.guard_leave_request() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS trg_guard_leave_request ON public.leave_requests;
CREATE TRIGGER trg_guard_leave_request
BEFORE INSERT OR UPDATE ON public.leave_requests
FOR EACH ROW EXECUTE FUNCTION public.guard_leave_request();

DROP POLICY IF EXISTS p_leaves_insert ON public.leave_requests;
CREATE POLICY p_leaves_insert ON public.leave_requests
FOR INSERT WITH CHECK (
    parent_id = auth.uid()
    AND public.auth_is_linked_parent_of(student_id)
);
DROP POLICY IF EXISTS p_leaves_update ON public.leave_requests;
CREATE POLICY p_leaves_update ON public.leave_requests
FOR UPDATE
USING (
    (auth.uid() = ANY(recipient_ids)
     AND public.auth_is_school_workflow_staff(school_id, auth.uid()))
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
)
WITH CHECK (
    (auth.uid() = ANY(recipient_ids)
     AND public.auth_is_school_workflow_staff(school_id, auth.uid()))
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
);

-- 4. Membership updates: the school-level role must always match the trusted
--    profile role. A manager cannot turn a student account into teaching staff.
CREATE OR REPLACE FUNCTION public.enforce_membership_initial_state()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_profile_role public.user_role;
BEGIN
    IF coalesce(auth.role(), '') = 'service_role' OR public.auth_is_super_admin() THEN
        IF NEW.role = 'superAdmin' THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: superAdmin is not a school membership role';
        END IF;
        RETURN NEW;
    END IF;

    SELECT p.role INTO v_profile_role
    FROM public.profiles p WHERE p.id = NEW.user_id;

    IF v_profile_role IS NULL OR v_profile_role NOT IN ('teacher', 'instructor', 'student', 'parent') THEN
        RAISE EXCEPTION 'SECURITY_VIOLATION: unsupported membership profile role';
    END IF;

    IF NEW.role IS DISTINCT FROM v_profile_role THEN
        RAISE EXCEPTION 'SECURITY_VIOLATION: membership role must match trusted profile role';
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF public.auth_is_manager_of_school(NEW.school_id) THEN
            IF NEW.status NOT IN ('pending', 'invited') THEN
                RAISE EXCEPTION 'SECURITY_VIOLATION: manager-created membership must start pending or invited';
            END IF;
            RETURN NEW;
        END IF;
        NEW.user_id := auth.uid();
        NEW.role := v_profile_role;
        NEW.status := 'pending';
        NEW.class_group_ids := ARRAY[]::uuid[];
        NEW.subject_ids := ARRAY[]::text[];
        NEW.via_invite := FALSE;
        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF NOT public.auth_is_manager_of_school(OLD.school_id)
           OR NEW.school_id IS DISTINCT FROM OLD.school_id
           OR NEW.user_id IS DISTINCT FROM OLD.user_id
           OR NEW.role IS DISTINCT FROM OLD.role THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: membership identity and role are immutable';
        END IF;
        RETURN NEW;
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.enforce_membership_initial_state() FROM PUBLIC, anon, authenticated;

DROP POLICY IF EXISTS p_memberships_update ON public.school_memberships;
CREATE POLICY p_memberships_update ON public.school_memberships
FOR UPDATE
USING (public.auth_is_manager_of_school(school_id) OR public.auth_is_super_admin())
WITH CHECK (public.auth_is_manager_of_school(school_id) OR public.auth_is_super_admin());

-- 5. Explicit UPDATE checks for school ownership; prevent moving a school to
--    another manager through a crafted UPDATE payload.
DROP POLICY IF EXISTS p_schools_update ON public.schools;
CREATE POLICY p_schools_update ON public.schools
FOR UPDATE
USING (manager_id = auth.uid() OR public.auth_is_super_admin())
WITH CHECK (manager_id = auth.uid() OR public.auth_is_super_admin());

-- 6. Explicitly keep tables with no reviewed client workflow closed. RLS is
--    already enabled in 002 and absence of policies is default-deny. This
--    comment records intentional default-deny until per-feature policies and
--    integration tests are added; do not add broad policies as a shortcut.
--    exam_schedules, student_notes, parent_meetings, teacher_follows,
--    class_schedules, library_favorites, discounts, manual_extensions, audit_logs.

-- End migration 005. Not executed.
