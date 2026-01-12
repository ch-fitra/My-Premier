-- Migration: 002_add_datasheet_url.sql
-- Description: Add datasheet_url column to products table

-- Add datasheet_url column to products table
ALTER TABLE products
ADD COLUMN IF NOT EXISTS datasheet_url TEXT;

-- Add updated_at column if it doesn't exist (for tracking updates)
ALTER TABLE products
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE;

