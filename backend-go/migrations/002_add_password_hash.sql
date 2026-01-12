-- Migration: 002_add_password_hash.sql
-- Description: Add password_hash column to users table for PostgreSQL-based authentication

-- Add password_hash column (nullable to support existing users)
-- Use TEXT instead of VARCHAR to support bcrypt hashes (60+ characters)
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Make email unique if not already (should be from init, but ensuring it)
-- Note: This will fail if email is not unique, which is expected
-- The unique constraint should already exist from 001_init.sql

