CREATE TABLE IF NOT EXISTS promos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    start_date DATE NULL,
    end_date DATE NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


