-- ==============================================================================
-- MADRASI — Migration 008: conversation participant and message integrity
-- Review branch proposal only. NOT executed against any database.
-- Requires migrations 001–007.
-- ==============================================================================

-- A participant is eligible for a school conversation only if they are:
--  * the school's manager; or
--  * an approved student/teacher/instructor/manager member; or
--  * a parent with an approved parent-child link to a student in that school.
-- The predicate is private: clients cannot probe arbitrary users with it.
CREATE OR REPLACE FUNCTION public.private_can_participate_in_school_chat(
    p_school_id uuid,
    p_user_id uuid
) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.schools s
        WHERE s.id = p_school_id
          AND s.status = 'active'
          AND s.manager_id = p_user_id
    )
    OR EXISTS (
        SELECT 1
        FROM public.school_memberships sm
        JOIN public.profiles p ON p.id = sm.user_id
        JOIN public.schools s ON s.id = sm.school_id
        WHERE sm.school_id = p_school_id
          AND sm.user_id = p_user_id
          AND sm.status = 'approved'
          AND sm.role IN ('student', 'teacher', 'instructor', 'manager')
          AND p.status = 'active'
          AND s.status = 'active'
    )
    OR EXISTS (
        SELECT 1
        FROM public.parent_link_requests pl
        JOIN public.profiles p ON p.id = pl.parent_id
        JOIN public.schools s ON s.id = pl.school_id
        WHERE pl.parent_id = p_user_id
          AND pl.school_id = p_school_id
          AND pl.status = 'approved'
          AND p.role = 'parent'
          AND p.status = 'active'
          AND s.status = 'active'
    );
$$;
REVOKE ALL ON FUNCTION public.private_can_participate_in_school_chat(uuid, uuid)
FROM PUBLIC, anon, authenticated;

-- Safe RLS wrapper: it can only evaluate the caller's own eligibility.
CREATE OR REPLACE FUNCTION public.auth_can_current_user_participate_in_school_chat(
    p_school_id uuid
) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $
    SELECT public.private_can_participate_in_school_chat(p_school_id, auth.uid());
$;
REVOKE ALL ON FUNCTION public.auth_can_current_user_participate_in_school_chat(uuid)
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.auth_can_current_user_participate_in_school_chat(uuid)
TO authenticated;

-- Validate the full participant list, not merely the caller's presence.
CREATE OR REPLACE FUNCTION public.guard_conversation_participants()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_count integer;
    v_distinct_count integer;
    v_user_id uuid;
BEGIN
    IF coalesce(auth.role(), '') = 'service_role' OR public.auth_is_super_admin() THEN
        RETURN NEW;
    END IF;

    IF TG_OP <> 'INSERT' THEN
        RAISE EXCEPTION 'SECURITY_VIOLATION: conversations are immutable from client sessions';
    END IF;

    IF NEW.school_id IS NULL
       OR auth.uid() IS NULL
       OR NOT (auth.uid() = ANY(NEW.participant_ids))
       OR coalesce(cardinality(NEW.participant_ids), 0) < 2 THEN
        RAISE EXCEPTION 'SECURITY_VIOLATION: a school conversation needs at least two participants including the caller';
    END IF;

    SELECT count(*), count(DISTINCT x)
      INTO v_count, v_distinct_count
    FROM unnest(NEW.participant_ids) AS participants(x);

    IF v_count <> v_distinct_count THEN
        RAISE EXCEPTION 'SECURITY_VIOLATION: duplicate conversation participants are not allowed';
    END IF;

    FOREACH v_user_id IN ARRAY NEW.participant_ids LOOP
        IF NOT public.private_can_participate_in_school_chat(NEW.school_id, v_user_id) THEN
            RAISE EXCEPTION 'SECURITY_VIOLATION: every participant must have an active relationship with this school';
        END IF;
    END LOOP;

    NEW.created_at := now();
    NEW.last_message_at := now();
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.guard_conversation_participants()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_guard_conversation_participants ON public.conversations;
CREATE TRIGGER trg_guard_conversation_participants
BEFORE INSERT OR UPDATE ON public.conversations
FOR EACH ROW EXECUTE FUNCTION public.guard_conversation_participants();

-- Message author identity and read receipts are server-controlled on insert.
CREATE OR REPLACE FUNCTION public.guard_message_integrity()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_school_id uuid;
    v_participants uuid[];
BEGIN
    IF coalesce(auth.role(), '') = 'service_role' OR public.auth_is_super_admin() THEN
        RETURN NEW;
    END IF;

    IF TG_OP <> 'INSERT' THEN
        RAISE EXCEPTION 'SECURITY_VIOLATION: messages are immutable; read receipts require a dedicated workflow';
    END IF;

    IF auth.uid() IS NULL OR NEW.sender_id IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION 'SECURITY_VIOLATION: message sender must be the authenticated user';
    END IF;

    SELECT c.school_id, c.participant_ids
      INTO v_school_id, v_participants
    FROM public.conversations c
    WHERE c.id = NEW.conversation_id;

    IF v_school_id IS NULL
       OR NOT (auth.uid() = ANY(v_participants))
       OR NOT public.private_can_participate_in_school_chat(v_school_id, auth.uid()) THEN
        RAISE EXCEPTION 'SECURITY_VIOLATION: sender is not an eligible participant in this school conversation';
    END IF;

    NEW.sent_at := now();
    NEW.read_by := ARRAY[auth.uid()]::uuid[];
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.guard_message_integrity()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_guard_message_integrity ON public.messages;
CREATE TRIGGER trg_guard_message_integrity
BEFORE INSERT OR UPDATE ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.guard_message_integrity();

-- Tighten policies: caller must be a valid participant for the selected school.
DROP POLICY IF EXISTS p_convs_insert ON public.conversations;
CREATE POLICY p_convs_insert ON public.conversations
FOR INSERT WITH CHECK (
    school_id IS NOT NULL
    AND auth.uid() = ANY(participant_ids)
    AND public.auth_can_current_user_participate_in_school_chat(school_id)
);

DROP POLICY IF EXISTS p_convs_select ON public.conversations;
CREATE POLICY p_convs_select ON public.conversations
FOR SELECT USING (
    auth.uid() = ANY(participant_ids)
    OR public.auth_is_super_admin()
);

DROP POLICY IF EXISTS p_messages_insert ON public.messages;
CREATE POLICY p_messages_insert ON public.messages
FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
        SELECT 1
        FROM public.conversations c
        WHERE c.id = conversation_id
          AND auth.uid() = ANY(c.participant_ids)
          AND public.auth_can_current_user_participate_in_school_chat(c.school_id)
    )
);

DROP POLICY IF EXISTS p_messages_select ON public.messages;
CREATE POLICY p_messages_select ON public.messages
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id
          AND auth.uid() = ANY(c.participant_ids)
    )
    OR public.auth_is_super_admin()
);

-- Deliberately no client UPDATE/DELETE policy for conversations or messages.
-- This prevents participant-list edits, message edits/deletes, and forged read
-- receipts until a separately audited receipt workflow is implemented.

COMMENT ON FUNCTION public.private_can_participate_in_school_chat(uuid, uuid)
IS 'Private server-side eligibility check for school chat participants; no client EXECUTE grant.';
COMMENT ON FUNCTION public.guard_conversation_participants()
IS 'Validates every conversation participant against the same active school.';
COMMENT ON FUNCTION public.guard_message_integrity()
IS 'Enforces sender identity and initializes read_by to the sender only.';

-- End migration 008. Static proposal only; not executed.

COMMENT ON FUNCTION public.auth_can_current_user_participate_in_school_chat(uuid)
IS 'RLS-safe predicate limited to the authenticated caller; cannot query another user ID.';
