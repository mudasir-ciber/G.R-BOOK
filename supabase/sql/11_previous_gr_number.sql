-- Migration 11: Add previous_gr_number to students table
-- Allows recording previous school's GR number when a student is admitted from another school.

ALTER TABLE public.students 
ADD COLUMN IF NOT EXISTS previous_gr_number TEXT;

COMMENT ON COLUMN public.students.previous_gr_number IS 'G.R. number of the student from their previous/last attended school (سابقہ جی آر نمبر)';
