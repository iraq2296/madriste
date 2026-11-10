-- ==============================================================================
-- MADRASI — مَدرَستي
-- Development Seed Script (STRICTLY FOR DEVELOPMENT / QA / INTEGRATION TESTS)
-- DO NOT RUN IN PRODUCTION!
-- ==============================================================================

-- 1. SUBSCRIPTION PLANS
INSERT INTO subscription_plans (id, role, price_iqd, duration_days, trial_days, effective_from, active) VALUES
  ('plan-dev-mgr', 'manager', 25000, 30, 7, '2026-01-01', TRUE),
  ('plan-dev-tch', 'teacher', 15000, 30, 7, '2026-01-01', TRUE),
  ('plan-dev-ins', 'instructor', 15000, 30, 7, '2026-01-01', TRUE)
ON CONFLICT (id) DO UPDATE SET price_iqd = EXCLUDED.price_iqd;

-- 2. SUBJECTS
INSERT INTO subjects (id, name_ar, name_en, name_ku, icon_key, color_index) VALUES
  ('sub-math', 'الرياضيات', 'Mathematics', 'بیرکاری', 'math', 0),
  ('sub-phys', 'الفيزياء', 'Physics', 'فیزیا', 'physics', 1),
  ('sub-chem', 'الكيمياء', 'Chemistry', 'کیمیا', 'chemistry', 2),
  ('sub-arab', 'اللغة العربية', 'Arabic', 'زمانی عەرەبی', 'arabic', 3),
  ('sub-engl', 'اللغة الإنكليزية', 'English', 'زمانی ئینگلیزی', 'english', 4)
ON CONFLICT (id) DO NOTHING;

-- 3. TEST PROFILES (MOCK AUTHENTICATED UUIDs)
-- In real Supabase Auth, profiles.id matches auth.users.id
INSERT INTO profiles (id, phone, full_name, role, status, verification, badge_verified, governorate) VALUES
  ('11111111-1111-1111-1111-111111111111', '+9647701111111', 'د. سعد كاظم (مدير مدرسة 1)', 'manager', 'active', 'verified', TRUE, 'بغداد'),
  ('22222222-2222-2222-2222-222222222222', '+9647802222222', 'أ. هدى جاسم (مديرة مدرسة 2)', 'manager', 'active', 'verified', TRUE, 'البصرة'),
  ('33333333-3333-3333-3333-333333333333', '+9647703333333', 'أ. علي حسين (مدرس مدرستين 1 و 2)', 'teacher', 'active', 'verified', TRUE, 'بغداد'),
  ('44444444-4444-4444-4444-444444444444', '+9647704444444', 'أ. زينب خفاجي (مدرسة مدرسة 1 فقط)', 'teacher', 'active', 'verified', TRUE, 'بغداد'),
  ('55555555-5555-5555-5555-555555555555', '+9647705555555', 'أحمد علي (طالب مدرسة 1)', 'student', 'active', 'verified', FALSE, 'بغداد'),
  ('66666666-6666-6666-6666-666666666666', '+9647806666666', 'حسين كريم (طالب مدرسة 2)', 'student', 'active', 'verified', FALSE, 'البصرة'),
  ('77777777-7777-7777-7777-777777777777', '+9647707777777', 'علي عبد الله (ولي أمر أحمد - مرتبط)', 'parent', 'active', 'verified', FALSE, 'بغداد'),
  ('88888888-8888-8888-8888-888888888888', '+9647808888888', 'قاسم جواد (ولي أمر أجنبي - غير مرتبط)', 'parent', 'active', 'verified', FALSE, 'بغداد'),
  ('99999999-9999-9999-9999-999999999999', '+9647709999999', 'م. وليد خالد (سوبر أدمن المنصة)', 'superAdmin', 'active', 'verified', TRUE, 'بغداد')
ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;

-- 4. TWO DISTINCT SCHOOLS (SCHOOL 1 & SCHOOL 2)
INSERT INTO schools (id, name, governorate, district, stages, manager_id, verified, status) VALUES
  ('a1111111-aaaa-1111-aaaa-111111111111', 'ثانوية بغداد التجريبية', 'بغداد', 'المنصور', '{preparatory}', '11111111-1111-1111-1111-111111111111', TRUE, 'active'),
  ('b2222222-bbbb-2222-bbbb-222222222222', 'مدرسة البصرة التجريبية', 'البصرة', 'العشار', '{primary}', '22222222-2222-2222-2222-222222222222', TRUE, 'active')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

-- 5. ACADEMIC YEARS
INSERT INTO academic_years (id, school_id, label, starts_on, ends_on, is_current) VALUES
  ('c1111111-cccc-1111-cccc-111111111111', 'a1111111-aaaa-1111-aaaa-111111111111', '2026–2027', '2026-09-20', '2027-06-30', TRUE),
  ('c2222222-cccc-2222-cccc-222222222222', 'b2222222-bbbb-2222-bbbb-222222222222', '2026–2027', '2026-09-20', '2027-06-30', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 6. CLASS GROUPS
INSERT INTO class_groups (id, school_id, stage, grade, track, section) VALUES
  ('d1111111-dddd-1111-dddd-111111111111', 'a1111111-aaaa-1111-aaaa-111111111111', 'preparatory', 5, 'scientific', 'A'),
  ('d2222222-dddd-2222-dddd-222222222222', 'b2222222-bbbb-2222-bbbb-222222222222', 'primary', 4, 'none', 'A')
ON CONFLICT (id) DO NOTHING;

-- 7. SCHOOL MEMBERSHIPS (MULTI-TENANCY ASSIGNMENTS)
INSERT INTO school_memberships (user_id, school_id, role, status, class_group_ids, subject_ids) VALUES
  -- School 1 Manager & Teachers & Student
  ('11111111-1111-1111-1111-111111111111', 'a1111111-aaaa-1111-aaaa-111111111111', 'manager', 'approved', '{}', '{}'),
  ('33333333-3333-3333-3333-333333333333', 'a1111111-aaaa-1111-aaaa-111111111111', 'teacher', 'approved', '{d1111111-dddd-1111-dddd-111111111111}', '{sub-math}'),
  ('44444444-4444-4444-4444-444444444444', 'a1111111-aaaa-1111-aaaa-111111111111', 'teacher', 'approved', '{d1111111-dddd-1111-dddd-111111111111}', '{sub-phys}'),
  ('55555555-5555-5555-5555-555555555555', 'a1111111-aaaa-1111-aaaa-111111111111', 'student', 'approved', '{d1111111-dddd-1111-dddd-111111111111}', '{}'),

  -- School 2 Manager & Teachers & Student
  ('22222222-2222-2222-2222-222222222222', 'b2222222-bbbb-2222-bbbb-222222222222', 'manager', 'approved', '{}', '{}'),
  ('33333333-3333-3333-3333-333333333333', 'b2222222-bbbb-2222-bbbb-222222222222', 'teacher', 'approved', '{d2222222-dddd-2222-dddd-222222222222}', '{sub-math}'),
  ('66666666-6666-6666-6666-666666666666', 'b2222222-bbbb-2222-bbbb-222222222222', 'student', 'approved', '{d2222222-dddd-2222-dddd-222222222222}', '{}')
ON CONFLICT (user_id, school_id) DO UPDATE SET status = EXCLUDED.status;

-- 8. PARENT-CHILD APPROVED LINK (NATIONAL ID APPROVED)
INSERT INTO parent_link_requests (id, parent_id, student_id, school_id, approver_id, approver_role, id_document_name, ocr_extracted_name, ocr_match, status) VALUES
  ('e1111111-eeee-1111-eeee-111111111111', '77777777-7777-7777-7777-777777777777', '55555555-5555-5555-5555-555555555555', 'a1111111-aaaa-1111-aaaa-111111111111', '11111111-1111-1111-1111-111111111111', 'manager', 'iraq_national_id_dev.jpg', 'علي عبد الله محمود', TRUE, 'approved')
ON CONFLICT (id) DO NOTHING;

-- 9. ACTIVE SUBSCRIPTIONS (MONTHLY AFTER 7 DAYS TRIAL)
INSERT INTO subscriptions (user_id, plan_id, status, started_at, ends_at, locked_price_iqd) VALUES
  ('11111111-1111-1111-1111-111111111111', 'plan-dev-mgr', 'active', NOW() - INTERVAL '10 days', NOW() + INTERVAL '20 days', 25000),
  ('22222222-2222-2222-2222-222222222222', 'plan-dev-mgr', 'trial',  NOW() - INTERVAL '2 days',  NOW() + INTERVAL '5 days',  25000),
  ('33333333-3333-3333-3333-333333333333', 'plan-dev-tch', 'active', NOW() - INTERVAL '5 days',  NOW() + INTERVAL '25 days', 15000),
  ('44444444-4444-4444-4444-444444444444', 'plan-dev-tch', 'active', NOW() - INTERVAL '15 days', NOW() + INTERVAL '15 days', 15000)
ON CONFLICT DO NOTHING;

-- 10. GRADES IN SCHOOL 1
INSERT INTO grade_entries (id, student_id, school_id, subject_id, teacher_id, year_id, exam_type, title, score, max_score) VALUES
  ('f1111111-ffff-1111-ffff-111111111111', '55555555-5555-5555-5555-555555555555', 'a1111111-aaaa-1111-aaaa-111111111111', 'sub-math', '33333333-3333-3333-3333-333333333333', 'c1111111-cccc-1111-cccc-111111111111', 'monthly', 'امتحان الشهر الأول - رياضيات', 94.0, 100.0)
ON CONFLICT (id) DO NOTHING;

-- 11. GRADES IN SCHOOL 2
INSERT INTO grade_entries (id, student_id, school_id, subject_id, teacher_id, year_id, exam_type, title, score, max_score) VALUES
  ('f2222222-ffff-2222-ffff-222222222222', '66666666-6666-6666-6666-666666666666', 'b2222222-bbbb-2222-bbbb-222222222222', 'sub-math', '33333333-3333-3333-3333-333333333333', 'c2222222-cccc-2222-cccc-222222222222', 'monthly', 'امتحان الشهر الأول - حساب', 88.0, 100.0)
ON CONFLICT (id) DO NOTHING;

