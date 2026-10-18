-- ==============================================================================
-- 10_class_serial_numbers.sql
-- G.R. BOOK Class-Scoped Serial Numbers & Re-indexing Migration
-- ==============================================================================

-- 1. Function to re-index all active students in a school or class sequentially (1 to N)
CREATE OR REPLACE FUNCTION public.reindex_class_serial_numbers(p_school_id UUID, p_class_id UUID DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    WITH numbered AS (
        SELECT id, ROW_NUMBER() OVER (
            PARTITION BY school_id, class_id
            ORDER BY serial_number ASC, date_of_admission ASC, created_at ASC
        ) AS new_serial
        FROM public.students
        WHERE school_id = p_school_id
          AND (p_class_id IS NULL OR class_id = p_class_id)
          AND is_deleted = false
          AND (status = 'ACTIVE' OR status = 'active')
    )
    UPDATE public.students s
    SET serial_number = n.new_serial
    FROM numbered n
    WHERE s.id = n.id
      AND s.serial_number IS DISTINCT FROM n.new_serial;
END;
$$;

-- 2. Function to allocate the next serial number for a specific class
CREATE OR REPLACE FUNCTION public.next_class_serial_number(p_school_id UUID, p_class_id UUID)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_max BIGINT;
BEGIN
    SELECT COALESCE(MAX(serial_number), 0) INTO v_max
    FROM public.students
    WHERE school_id = p_school_id
      AND class_id = p_class_id
      AND is_deleted = false
      AND (status = 'ACTIVE' OR status = 'active');

    RETURN v_max + 1;
END;
$$;

-- 3. Execute re-indexing for all existing active students across all classes & schools
WITH numbered_all AS (
    SELECT id, ROW_NUMBER() OVER (
        PARTITION BY school_id, class_id
        ORDER BY serial_number ASC, date_of_admission ASC, created_at ASC
    ) AS new_serial
    FROM public.students
    WHERE is_deleted = false
      AND (status = 'ACTIVE' OR status = 'active')
)
UPDATE public.students s
SET serial_number = n.new_serial
FROM numbered_all n
WHERE s.id = n.id
  AND s.serial_number IS DISTINCT FROM n.new_serial;
