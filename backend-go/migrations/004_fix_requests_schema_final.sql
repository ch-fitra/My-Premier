-- Migration: 004_fix_requests_schema_final.sql
-- Description: FINAL fix for requests table schema mismatch
-- Adds user_id and product_id, removes user_email and product_name

-- Step 1: Add new columns (nullable first to allow migration of existing data)
ALTER TABLE requests
    ADD COLUMN IF NOT EXISTS user_id UUID,
    ADD COLUMN IF NOT EXISTS product_id UUID;

-- Step 2: Migrate existing data if any (only if old columns exist)
DO $$
BEGIN
    -- Check if user_email column exists and migrate data
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'requests' AND column_name = 'user_email'
    ) THEN
        UPDATE requests 
        SET user_id = (SELECT id FROM users WHERE email = requests.user_email LIMIT 1)
        WHERE user_id IS NULL AND user_email IS NOT NULL;
    END IF;

    -- Check if product_name column exists and migrate data
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'requests' AND column_name = 'product_name'
    ) THEN
        UPDATE requests 
        SET product_id = (SELECT id FROM products WHERE name = requests.product_name LIMIT 1)
        WHERE product_id IS NULL AND product_name IS NOT NULL;
    END IF;

    -- Delete any orphaned records that couldn't be migrated
    DELETE FROM requests WHERE user_id IS NULL OR product_id IS NULL;
END $$;

-- Step 3: Make columns NOT NULL (will fail if NULLs exist, but we cleaned them above)
ALTER TABLE requests
    ALTER COLUMN user_id SET NOT NULL,
    ALTER COLUMN product_id SET NOT NULL;

-- Step 4: Add foreign key constraints
-- Drop existing constraints if they exist (to avoid errors on re-run)
ALTER TABLE requests
    DROP CONSTRAINT IF EXISTS fk_requests_user_id,
    DROP CONSTRAINT IF EXISTS fk_requests_product_id;

ALTER TABLE requests
    ADD CONSTRAINT fk_requests_user_id 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE requests
    ADD CONSTRAINT fk_requests_product_id 
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;

-- Step 5: Remove old columns
ALTER TABLE requests
    DROP COLUMN IF EXISTS user_email,
    DROP COLUMN IF EXISTS product_name;

-- Step 6: Ensure status column exists with default 'pending'
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'requests' AND column_name = 'status'
    ) THEN
        ALTER TABLE requests ADD COLUMN status VARCHAR(50) NOT NULL DEFAULT 'pending';
    ELSE
        -- Ensure default is set
        ALTER TABLE requests ALTER COLUMN status SET DEFAULT 'pending';
    END IF;
END $$;

-- Step 7: Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_requests_user_id ON requests(user_id);
CREATE INDEX IF NOT EXISTS idx_requests_product_id ON requests(product_id);
CREATE INDEX IF NOT EXISTS idx_requests_status ON requests(status);

