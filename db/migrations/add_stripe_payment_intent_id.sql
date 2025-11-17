-- ============================================================================
-- Add Stripe payment_intent_id to payment_transactions table
-- This migration adds support for Stripe payment tracking
-- ============================================================================

-- Add payment_intent_id column to track Stripe payments
ALTER TABLE payment_transactions 
ADD COLUMN IF NOT EXISTS payment_intent_id TEXT UNIQUE;

-- Create index for faster lookups by payment_intent_id
CREATE INDEX IF NOT EXISTS idx_payment_transactions_payment_intent_id 
ON payment_transactions(payment_intent_id) 
WHERE payment_intent_id IS NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN payment_transactions.payment_intent_id IS 'Stripe PaymentIntent ID for verification and tracking';
