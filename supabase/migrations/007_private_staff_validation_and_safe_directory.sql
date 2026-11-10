-- ==============================================================================
-- MADRASI — Migration 007: remove staff-membership oracle; safe profile directory
-- Review branch only. NOT executed against any database.
-- Requires migrations 001–006.
-- ==============================================================================

-- 1) Private predicate for validating a proposed approver/recipient.
-- It is intentionally NOT executable by anon/authenticated clients.
CREATE OR REPLACE FUNCTION public.private_is_school_workflow_staff(
    p_school_id uuid,
    p_user_id uuid
) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.schools s
        WHERE s.id = p_school_id AND s.manager_id = p_user_id
    )
    OR EXISTS (
        SELECT 1
        FROM public.school_memberships sm
        WHERE sm.school_id = p_school_id
          AND sm.user_id = p_user_id
          AND sm.status = 'approved'
          AND sm.role IN ('teacher', 'instructor', 'manager')
    );
$$;
REVOKE ALL ON FUNCTION public.private_is_school_workflow_staff(uuid, uuid)
FROM PUBLIC, anon, authenticated;

-- 2) Publicly callable policy helper only answers for auth.uid(), never an
-- arbitrary supplied user ID. This avoids exposing a user-membership oracle.
CREATE OR REPLACE FUNCTION public.auth_is_current_user_school_workflow_staff(
    p_school_id uuid
) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT public.private_is_school_workflow_staff(p_school_id, auth.uid());
$$;
REVOKE ALL ON FUNCTION public.auth_is_current_user_school_workflow_staff(uuid)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.auth_is_current_user_school_workflow_staff(uuid)
TO authenticated;

-- 3) Replace the workflow trigger guards to use the private predicate when
-- validating a client-selected approver or recipient.
CREATE OR REPLACE FUNCTION public.guard_parent_link_request()
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
           OR NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = NEW.parent_id AND p.role = 'parent')
           OR NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = NEW.student_id AND p.role = 'student')
           OR NOT public.private_is_school_workflow_staff(NEW.school_id, NEW.approver_id) THEN
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
REVOKE ALL ON FUNCTION public.guard_parent_link_request()
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.guard_leave_request()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_invalid_recipient boolean;
BEGIN
    IF coalesce(auth.role(), '') = 'service_role' OR public.auth_is_super_admin() THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.parent_id IS DISTINCT FROM auth.uid()
           OR NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = NEW.parent_id AND p.role = 'parent')
           OR NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = NEW.student_id AND p.role = 'student')
           OR NOT EXISTS (
                SELECT 1 FROM public.parent_link_requests pl
                WHERE pl.parent_id = NEW.parent_id
                  AND pl.student_id = NEW.student_id
                  AND pl.school_id = NEW.school_id
                  AND pl.status = 'approved'
           )
           OR coalesce(cardinality(NEW.recipient_ids), 0) = 0 THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: invalid parent-child-school relationship or empty recipients';
        END IF;

        SELECT EXISTS (
            SELECT 1
            FROM unnest(NEW.recipient_ids) AS recipients(user_id)
            WHERE NOT public.private_is_school_workflow_staff(NEW.school_id, recipients.user_id)
        ) INTO v_invalid_recipient;

        IF v_invalid_recipient THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: every leave recipient must be authorized staff of the selected school';
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
           OR NEW.attachment_name IS DISTINCT FROM OLD.attachment_name
           OR NEW.recipient_ids IS DISTINCT FROM OLD.recipient_ids
           OR NEW.created_at IS DISTINCT FROM OLD.created_at
           OR OLD.status <> 'pending'
           OR NEW.status NOT IN ('approved', 'cancelled') THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: immutable leave request fields or invalid transition';
        END IF;

        IF auth.uid() = OLD.parent_id THEN
            IF NEW.status <> 'cancelled' THEN
                RAISE EXCEPTION 'SECURITY_VIOLATION: parent may only cancel their own pending leave request';
            END IF;
            NEW.approved_by := NULL;
            RETURN NEW;
        END IF;

        IF NEW.status <> 'approved'
           OR NOT (
                (auth.uid() = ANY(OLD.recipient_ids)
                 AND public.private_is_school_workflow_staff(OLD.school_id, auth.uid()))
                OR public.auth_is_manager_of_school(OLD.school_id)
           ) THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: only authorized school staff may approve leave requests';
        END IF;
        NEW.approved_by := auth.uid();
        RETURN NEW;
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.guard_leave_request()
FROM PUBLIC, anon, authenticated;

-- Replace client-facing policies so they never call the arbitrary-user helper.
DROP POLICY IF EXISTS p_parent_links_insert ON public.parent_link_requests;
CREATE POLICY p_parent_links_insert ON public.parent_link_requests
FOR INSERT WITH CHECK (parent_id = auth.uid());

DROP POLICY IF EXISTS p_parent_links_update ON public.parent_link_requests;
CREATE POLICY p_parent_links_update ON public.parent_link_requests
FOR UPDATE
USING (
    (approver_id = auth.uid()
     AND public.auth_is_current_user_school_workflow_staff(school_id))
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
)
WITH CHECK (
    (approver_id = auth.uid()
     AND public.auth_is_current_user_school_workflow_staff(school_id))
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
);

DROP POLICY IF EXISTS p_leaves_update ON public.leave_requests;
CREATE POLICY p_leaves_update ON public.leave_requests
FOR UPDATE
USING (
    parent_id = auth.uid()
    OR (
        auth.uid() = ANY(recipient_ids)
        AND public.auth_is_current_user_school_workflow_staff(school_id)
    )
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
)
WITH CHECK (
    parent_id = auth.uid()
    OR (
        auth.uid() = ANY(recipient_ids)
        AND public.auth_is_current_user_school_workflow_staff(school_id)
    )
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
);

-- 4) Safe directory RPC. It exposes only deliberate directory fields and
-- never phone, status_reason, verification metadata, or private account data.
-- SECURITY DEFINER is constrained by a fixed search_path and explicit output.
CREATE OR REPLACE FUNCTION public.get_public_profile_directory(
    p_search text DEFAULT NULL,
    p_role public.user_role DEFAULT NULL,
    p_limit integer DEFAULT 50
)
RETURNS TABLE (
    id uuid,
    full_name text,
    role public.user_role,
    photo_url text,
    badge_verified boolean,
    governorate text,
    specialization text,
    subject_ids text[],
    teacher_code text
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT
        p.id,
        p.full_name,
        p.role,
        p.photo_url,
        p.badge_verified,
        p.governorate,
        p.specialization,
        p.subject_ids,
        p.teacher_code
    FROM public.profiles p
    WHERE p.status = 'active'
      AND auth.uid() IS NOT NULL
      AND (p_role IS NULL OR p.role = p_role)
      AND (
          nullif(btrim(p_search), '') IS NULL
          OR p.full_name ILIKE '%' || btrim(p_search) || '%'
          OR p.teacher_code ILIKE '%' || btrim(p_search) || '%'
      )
    ORDER BY p.full_name
    LIMIT least(greatest(coalesce(p_limit, 50), 1), 100);
$$;
REVOKE ALL ON FUNCTION public.get_public_profile_directory(text, public.user_role, integer)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_public_profile_directory(text, public.user_role, integer)
TO authenticated;

COMMENT ON FUNCTION public.get_public_profile_directory(text, public.user_role, integer)
IS 'Authenticated safe profile directory. Returns explicit public fields only; never use as a source of private profile data.';

-- Keep public_profiles view as security_invoker from migration 004; app clients
-- should migrate directory reads to this RPC after integration tests.
-- End migration 007. Static proposal only; not executed.
