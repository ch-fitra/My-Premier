-- Migration: 005_add_supports_status.sql
-- Description: Add status column to supports table
-- The backend expects a status column with default value 'open'

-- Add status column if it doesn't exist (idempotent)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'supports' AND column_name = 'status'
    ) THEN
        ALTER TABLE supports
        ADD COLUMN status varchar NOT NULL DEFAULT 'open';
    END IF;
END $$;

