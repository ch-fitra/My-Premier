-- Migration: 003_normalize_requests_table.sql
-- Description: Normalize requests table to use user_id and product_id with foreign keys
-- Removes user_email and product_name columns

-- Step 1: Add new columns (nullable first)
ALTER TABLE requests
    ADD COLUMN IF NOT EXISTS user_id UUID,
    ADD COLUMN IF NOT EXISTS product_id UUID;

-- Step 2: Migrate existing data if any (uncomment and adjust if needed)
-- IMPORTANT: If you have existing data, uncomment these lines and run them before proceeding:
-- UPDATE requests SET user_id = (SELECT id FROM users WHERE email = requests.user_email LIMIT 1);
-- UPDATE requests SET product_id = (SELECT id FROM products WHERE name = requests.product_name LIMIT 1);
-- DELETE FROM requests WHERE user_id IS NULL OR product_id IS NULL; -- Remove orphaned records

-- Step 3: Make columns NOT NULL
-- This will fail if there are NULL values, so ensure data is migrated first (see Step 2)
ALTER TABLE requests
    ALTER COLUMN user_id SET NOT NULL,
    ALTER COLUMN product_id SET NOT NULL;

-- Step 4: Add foreign key constraints (must be after NOT NULL constraint)
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

-- Step 6: Ensure status column exists with default 'pending' (if not already present)
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

