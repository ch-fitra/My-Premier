-- Migration: 001_init.sql
-- Description: Initial schema creation for My Premier backend
-- Replaces Firestore collections with PostgreSQL tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Categories table
-- Supports hierarchical structure with parent_id
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index on parent_id for efficient hierarchical queries
CREATE INDEX idx_categories_parent_id ON categories(parent_id);

-- Products table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(255),
    series VARCHAR(255),
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    technical_overview TEXT,
    typical_application TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for products
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_is_active ON products(is_active);
CREATE INDEX idx_products_brand ON products(brand);

-- Product images table
-- Separate table for product images (one-to-many relationship)
CREATE TABLE product_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index on product_id for efficient lookups
CREATE INDEX idx_product_images_product_id ON product_images(product_id);

-- Requests table
-- Stores quotation/inquiry requests
CREATE TABLE requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    company VARCHAR(255),
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index on email and created_at for efficient queries
CREATE INDEX idx_requests_email ON requests(email);
CREATE INDEX idx_requests_created_at ON requests(created_at DESC);

-- Supports table
-- Stores support tickets/requests
CREATE TABLE supports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    issue_type VARCHAR(100),
    description TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for supports
CREATE INDEX idx_supports_email ON supports(email);
CREATE INDEX idx_supports_status ON supports(status);
CREATE INDEX idx_supports_created_at ON supports(created_at DESC);

-- Support messages table
-- Stores messages within support tickets (chat functionality)
CREATE TABLE support_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    support_id UUID NOT NULL REFERENCES supports(id) ON DELETE CASCADE,
    sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('client', 'admin')),
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for support_messages
CREATE INDEX idx_support_messages_support_id ON support_messages(support_id);
CREATE INDEX idx_support_messages_created_at ON support_messages(created_at);

-- Users table
-- Stores user information for PostgreSQL-based authentication
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    uid VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'client' CHECK (role IN ('admin', 'sales', 'client')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for users
CREATE INDEX idx_users_uid ON users(uid);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_is_active ON users(is_active);

