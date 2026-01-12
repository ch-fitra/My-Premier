-- Create engineer_reports table
CREATE TABLE IF NOT EXISTS engineer_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_email VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    notes TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'submitted',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index on user_email for faster queries
CREATE INDEX IF NOT EXISTS idx_engineer_reports_user_email ON engineer_reports(user_email);

-- Create index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_engineer_reports_created_at ON engineer_reports(created_at DESC);

