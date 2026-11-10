-- ==============================================================================
-- MADRASI — مَدرَستي
-- Supabase Database Seed Script (Iraqi Educational Data)
-- ==============================================================================

-- 1. STAGES & GRADES
INSERT INTO stages_grades (stage, grade_number, name_ar, name_en) VALUES
  ('primary', 1, 'الصف الأول الابتدائي', '1st Primary'),
  ('primary', 2, 'الصف الثاني الابتدائي', '2nd Primary'),
  ('primary', 3, 'الصف الثالث الابتدائي', '3rd Primary'),
  ('primary', 4, 'الصف الرابع الابتدائي', '4th Primary'),
  ('primary', 5, 'الصف الخامس الابتدائي', '5th Primary'),
  ('primary', 6, 'الصف السادس الابتدائي (وزاري)', '6th Primary (Ministerial)'),
  ('intermediate', 1, 'الصف الأول المتوسط', '1st Intermediate'),
  ('intermediate', 2, 'الصف الثاني المتوسط', '2nd Intermediate'),
  ('intermediate', 3, 'الصف الثالث المتوسط (وزاري)', '3rd Intermediate (Ministerial)'),
  ('preparatory', 4, 'الصف الرابع الإعدادي (علمي / أدبي)', '4th Preparatory'),
  ('preparatory', 5, 'الصف الخامس الإعدادي (علمي / أدبي)', '5th Preparatory'),
  ('preparatory', 6, 'الصف السادس الإعدادي (وزاري)', '6th Preparatory (Ministerial)')
ON CONFLICT DO NOTHING;

-- 2. SAMPLE SCHOOLS (BAGHDAD, BASRA, NINEVEH)
INSERT INTO schools (id, name, stage, directorate, governorate, address, is_verified, subscription_status) VALUES
  ('sch-bgd-01', 'ثانوية المتفوقين للبنين', 'preparatory', 'مديرية تربية الكرخ الأولى', 'بغداد', 'المنصور - حي دراغ', TRUE, 'active'),
  ('sch-bgd-02', 'ثانوية المتميزين المختلطة', 'preparatory', 'مديرية تربية الرصافة الأولى', 'بغداد', 'شارع فلسطين', TRUE, 'active'),
  ('sch-bsr-01', 'مدرسة النخبة الابتدائية النموذجية', 'primary', 'مديرية تربية البصرة', 'البصرة', 'حي الجزائر', TRUE, 'active'),
  ('sch-nnv-01', 'ثانوية الحدباء للبنات', 'intermediate', 'مديرية تربية نينوى', 'نينوى', 'الموصل - الجانب الأيمن', TRUE, 'active')
ON CONFLICT (id) DO NOTHING;

-- 3. ACADEMIC YEARS
INSERT INTO academic_years (id, school_id, year_label, is_current) VALUES
  ('ay-2025-2026-bgd01', 'sch-bgd-01', '2025–2026', TRUE),
  ('ay-2024-2025-bgd01', 'sch-bgd-01', '2024–2025', FALSE),
  ('ay-2025-2026-bgd02', 'sch-bgd-02', '2025–2026', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 4. SECTIONS
INSERT INTO sections (id, school_id, grade_number, name) VALUES
  ('sec-bgd01-5-a', 'sch-bgd-01', 5, 'أ - علمي'),
  ('sec-bgd01-5-b', 'sch-bgd-01', 5, 'ب - علمي'),
  ('sec-bgd01-6-a', 'sch-bgd-01', 6, 'أ - وزاري علمي')
ON CONFLICT (id) DO NOTHING;

-- 5. DEMO SYSTEM USERS
INSERT INTO users (id, phone, full_name, role, status, is_verified) VALUES
  ('usr-manager-01', '+9647701234567', 'د. عمر فاروق السعدي', 'school_manager', 'active', TRUE),
  ('usr-teacher-01', '+9647802345678', 'أ. علي حسين الشمري', 'teacher', 'active', TRUE),
  ('usr-instructor-01', '+9647713456789', 'أ. سيف عماد الدين', 'instructor', 'active', TRUE),
  ('usr-student-01', '+9647724567890', 'أحمد علي عبد الله', 'student', 'active', FALSE),
  ('usr-student-02', '+9647735678901', 'مريم علي عبد الله', 'student', 'active', FALSE),
  ('usr-parent-01', '+9647815678901', 'سارة جاسم محمد', 'parent', 'active', FALSE),
  ('usr-owner-01', '+9647700000000', 'م. وليد خالد', 'super_admin', 'active', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 6. SCHOOL MEMBERSHIPS
INSERT INTO school_memberships (school_id, user_id, role, status) VALUES
  ('sch-bgd-01', 'usr-manager-01', 'school_manager', 'approved'),
  ('sch-bgd-01', 'usr-teacher-01', 'teacher', 'approved'),
  ('sch-bgd-02', 'usr-teacher-01', 'teacher', 'approved'),
  ('sch-bgd-01', 'usr-student-01', 'student', 'approved')
ON CONFLICT DO NOTHING;

-- 7. SUBJECTS
INSERT INTO subjects (id, school_id, name_ar, name_en, grade_number) VALUES
  ('sub-phys-5', 'sch-bgd-01', 'الفيزياء', 'Physics', 5),
  ('sub-chem-5', 'sch-bgd-01', 'الكيمياء', 'Chemistry', 5),
  ('sub-math-5', 'sch-bgd-01', 'الرياضيات', 'Mathematics', 5),
  ('sub-arab-5', 'sch-bgd-01', 'اللغة العربية', 'Arabic Language', 5),
  ('sub-engl-5', 'sch-bgd-01', 'اللغة الإنكليزية', 'English Language', 5),
  ('sub-cs-5',   'sch-bgd-01', 'الحاسوب والبرمجة', 'Computer Science', 5)
ON CONFLICT (id) DO NOTHING;

-- 8. MINISTERIAL EXAMS (ROUNDS 1, 2, 3)
INSERT INTO ministerial_exams (id, title, stage, grade_number, year, round, has_model_answer, file_url) VALUES
  ('min-01', 'أسئلة الفيزياء الوزارية — السادس العلمي 2024', 'preparatory', 6, 2024, 1, TRUE, 'https://storage.madrasi.iq/exams/physics_2024_r1.pdf'),
  ('min-02', 'أسئلة الرياضيات الوزارية — السادس العلمي 2024 (الدور الثاني)', 'preparatory', 6, 2024, 2, TRUE, 'https://storage.madrasi.iq/exams/math_2024_r2.pdf'),
  ('min-03', 'أسئلة الكيمياء الوزارية — الثالث المتوسط 2024 (الدور الأول)', 'intermediate', 3, 2024, 1, TRUE, 'https://storage.madrasi.iq/exams/chem_3int_2024_r1.pdf'),
  ('min-04', 'أسئلة اللغة العربية الوزارية — السادس الإعدادي 2023 (الدور الثالث)', 'preparatory', 6, 2023, 3, TRUE, 'https://storage.madrasi.iq/exams/arabic_2023_r3.pdf')
ON CONFLICT (id) DO NOTHING;

-- 9. GENERAL EDUCATIONAL LIBRARY
INSERT INTO library_resources (id, title, stage, grade_number, subject_id, author_teacher_name, author_teacher_id, resource_type, file_url, extracted_text) VALUES
  ('lib-01', 'ملزمة الفيزياء الحديثة وشرح القوانين بالتفصيل', 'preparatory', 5, 'sub-phys-5', 'أ. علي حسين الشمري', 'usr-teacher-01', 'summary', 'https://storage.madrasi.iq/library/physics_ch1_summary.pdf', 'شرح المتجهات والحركة في بعدين وقوانين نيوتن في الحركة الخطية والدائرية مع حلول أسئلة الفصل.'),
  ('lib-02', 'كتاب الرياضيات المنهجي المعتمد من وزارة التربية', 'preparatory', 5, 'sub-math-5', 'وزارة التربية العراقية', NULL, 'curriculum_book', 'https://storage.madrasi.iq/library/math_grade5_iq.pdf', 'كتاب الرياضيات الرسمي للصف الخامس الإعدادي الفرع العلمي الطبعة المعتمدة.'),
  ('lib-03', 'دليل التجارب الكيميائية المعملية السريعة', 'preparatory', 5, 'sub-chem-5', 'أ. رائد الحمداني', 'usr-teacher-01', 'summary', 'https://storage.madrasi.iq/library/chem_experiments.pdf', 'تجارب التفاعلات الكيميائية والحسابات المولية لطلبة الخامس العلمي.')
ON CONFLICT (id) DO NOTHING;

-- 10. STUDENT GRADES (WITH REALISTIC RATIOS)
INSERT INTO student_grades (id, school_id, student_id, subject_id, exam_type, score, max_score, recorded_by_teacher_id) VALUES
  ('grd-01', 'sch-bgd-01', 'usr-student-01', 'sub-phys-5', 'شهر أول', 96, 100, 'usr-teacher-01'),
  ('grd-02', 'sch-bgd-01', 'usr-student-01', 'sub-math-5', 'شهر أول', 94, 100, 'usr-teacher-01'),
  ('grd-03', 'sch-bgd-01', 'usr-student-01', 'sub-chem-5', 'شهر أول', 95, 100, 'usr-teacher-01')
ON CONFLICT (id) DO NOTHING;

-- 11. ANNOUNCEMENTS
INSERT INTO announcements (id, school_id, title, body, author_name, audience) VALUES
  ('ann-01', 'sch-bgd-01', 'جدول الامتحانات الشهرية للفصل الدراسي الأول', 'يرجى من جميع الطلبة الالتزام بالحضور بالزي المدرسي الموحد والاطلاع على جدول الامتحانات المرفق.', 'د. عمر فاروق السعدي', 'all'),
  ('ann-02', 'sch-bgd-01', 'توزيع بطاقات درجات الشهر الأول لأولياء الأمور', 'ندعو أولياء الأمور الكرام لمراجعة المنصة والاطلاع على نتائج أبنائهم ومتابعة الملاحظات الأكاديمية.', 'إدارة ثانوية المتفوقين', 'parents')
ON CONFLICT (id) DO NOTHING;
