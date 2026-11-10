-- ==============================================================================
-- MADRASI — Migration 006: membership invite and leave-request integrity
-- Review branch only. NOT executed against any database.
-- Requires migrations 001–005.
-- ==============================================================================

-- 1) Allow a school manager to create a membership invitation for another
--    account. The trigger from migration 005 remains the authority for role
--    matching and allowed initial states; this policy only opens the narrow
--    manager-owned-school path.
DROP POLICY IF EXISTS p_memberships_insert ON public.school_memberships;
CREATE POLICY p_memberships_insert ON public.school_memberships
FOR INSERT
WITH CHECK (
    (user_id = auth.uid() AND status = 'pending')
    OR public.auth_is_manager_of_school(school_id)
);

-- 2) Harden leave-request creation. The selected school must be the school
--    where this parent-child relationship was approved. Every recipient must
--    be the manager or an approved teacher/instructor/manager of that school.
CREATE OR REPLACE FUNCTION public.guard_leave_request()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_service boolean := coalesce(auth.role(), '') = 'service_role';
    v_invalid_recipient boolean;
BEGIN
    IF v_service OR public.auth_is_super_admin() THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.parent_id IS DISTINCT FROM auth.uid()
           OR NOT EXISTS (
                SELECT 1
                FROM public.profiles p
                WHERE p.id = NEW.parent_id AND p.role = 'parent'
           )
           OR NOT EXISTS (
                SELECT 1
                FROM public.profiles p
                WHERE p.id = NEW.student_id AND p.role = 'student'
           )
           OR NOT EXISTS (
                SELECT 1
                FROM public.parent_link_requests pl
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
            FROM unnest(NEW.recipient_ids) AS recipient_id
            WHERE NOT public.auth_is_school_workflow_staff(NEW.school_id, recipient_id)
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

        -- The parent who created the request may cancel it while pending,
        -- but cannot approve it or alter its contents.
        IF auth.uid() = OLD.parent_id THEN
            IF NEW.status <> 'cancelled' THEN
                RAISE EXCEPTION 'SECURITY_VIOLATION: parent may only cancel their own pending leave request';
            END IF;
            NEW.approved_by := NULL;
            RETURN NEW;
        END IF;

        -- Only an authorized listed recipient or the school manager may
        -- approve the request. A staff member cannot cancel on behalf of
        -- the parent through this path.
        IF NEW.status <> 'approved'
           OR NOT (
                (auth.uid() = ANY(OLD.recipient_ids)
                 AND public.auth_is_school_workflow_staff(OLD.school_id, auth.uid()))
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

DROP POLICY IF EXISTS p_leaves_insert ON public.leave_requests;
CREATE POLICY p_leaves_insert ON public.leave_requests
FOR INSERT
WITH CHECK (
    parent_id = auth.uid()
    AND EXISTS (
        SELECT 1
        FROM public.parent_link_requests pl
        WHERE pl.parent_id = auth.uid()
          AND pl.student_id = leave_requests.student_id
          AND pl.school_id = leave_requests.school_id
          AND pl.status = 'approved'
    )
);

DROP POLICY IF EXISTS p_leaves_update ON public.leave_requests;
CREATE POLICY p_leaves_update ON public.leave_requests
FOR UPDATE
USING (
    parent_id = auth.uid()
    OR (
        auth.uid() = ANY(recipient_ids)
        AND public.auth_is_school_workflow_staff(school_id, auth.uid())
    )
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
)
WITH CHECK (
    parent_id = auth.uid()
    OR (
        auth.uid() = ANY(recipient_ids)
        AND public.auth_is_school_workflow_staff(school_id, auth.uid())
    )
    OR public.auth_is_manager_of_school(school_id)
    OR public.auth_is_super_admin()
);

-- End migration 006. Static proposal only; test in a disposable database.
