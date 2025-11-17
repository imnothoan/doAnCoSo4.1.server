# Stripe Payment Integration Guide

## Overview

This server now supports Stripe payment integration for Pro subscription payments. The implementation allows for both real Stripe payments (in test mode) and quick test mode activation.

## Features

- **Stripe Payment Intent Creation**: Create payment intents for secure payment processing
- **Payment Verification**: Server-side validation of successful payments
- **Dual Payment Modes**: Support for both Stripe and test mode payments
- **Fraud Prevention**: Prevents reuse of payment intents
- **Database Tracking**: All transactions are logged with payment intent IDs

---

## Setup Instructions

### 1. Get Stripe API Keys

1. Sign up for a free Stripe account at [stripe.com](https://stripe.com)
2. Navigate to [Stripe Dashboard - API Keys](https://dashboard.stripe.com/test/apikeys)
3. Copy your **Secret key** (starts with `sk_test_`)
4. **Important**: Use test mode keys for development (they start with `sk_test_`)

### 2. Configure Environment Variables

Add your Stripe secret key to your `.env` file:

```env
STRIPE_SECRET_KEY=sk_test_your_actual_stripe_secret_key_here
```

**Security Note**: Never commit your actual Stripe keys to version control. The `.env` file is gitignored.

### 3. Run Database Migration

Execute the migration to add the `payment_intent_id` column to the `payment_transactions` table:

```sql
-- Run this SQL in your Supabase SQL editor or migration tool
ALTER TABLE payment_transactions 
ADD COLUMN IF NOT EXISTS payment_intent_id TEXT UNIQUE;

CREATE INDEX IF NOT EXISTS idx_payment_transactions_payment_intent_id 
ON payment_transactions(payment_intent_id) 
WHERE payment_intent_id IS NOT NULL;
```

Or use the migration file:
```bash
# Execute the migration SQL file
psql $DATABASE_URL -f db/migrations/add_stripe_payment_intent_id.sql
```

### 4. Install Dependencies

```bash
npm install
```

This will install the `stripe` package (already added to package.json).

---

## API Endpoints

### 1. Create Payment Intent

**Endpoint**: `POST /payments/create-payment-intent`

**Description**: Creates a Stripe PaymentIntent for processing payment.

**Request Body**:
```json
{
  "username": "johndoe",
  "amount": 1  // Optional, default 1 (= $0.01 USD)
}
```

**Response**:
```json
{
  "clientSecret": "pi_xxx_secret_xxx",
  "paymentIntentId": "pi_xxxxxxxxxxxxx"
}
```

**Usage**:
- Client calls this endpoint first to get a payment intent
- The `clientSecret` is used by the client to confirm payment with Stripe
- The `paymentIntentId` is used to verify payment on subscription activation

**Example**:
```javascript
const response = await fetch('http://localhost:3000/payments/create-payment-intent', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    username: 'johndoe',
    amount: 1  // $0.01 USD
  })
});
const { clientSecret, paymentIntentId } = await response.json();
```

---

### 2. Subscribe to Pro Plan (Updated)

**Endpoint**: `POST /payments/subscribe`

**Description**: Activates Pro subscription. Now supports both Stripe and test mode.

**Request Body (Stripe Payment)**:
```json
{
  "username": "johndoe",
  "plan_type": "pro",
  "payment_method": "stripe",
  "payment_intent_id": "pi_xxxxxxxxxxxxx"
}
```

**Request Body (Test Mode)**:
```json
{
  "username": "johndoe",
  "plan_type": "pro",
  "payment_method": "test"
}
```

**Response**:
```json
{
  "subscription": {
    "username": "johndoe",
    "plan_type": "pro",
    "status": "active",
    "start_date": "2024-01-15T10:00:00.000Z",
    "end_date": "2024-02-15T10:00:00.000Z"
  },
  "transaction": {
    "id": 123,
    "username": "johndoe",
    "amount": 0.01,
    "currency": "USD",
    "plan_type": "pro",
    "status": "completed",
    "payment_method": "stripe",
    "payment_intent_id": "pi_xxxxxxxxxxxxx",
    "transaction_date": "2024-01-15T10:00:00.000Z"
  },
  "message": "Successfully subscribed to Pro plan!"
}
```

**Payment Verification**:
- For Stripe payments, the server:
  1. Retrieves the PaymentIntent from Stripe using the ID
  2. Verifies the payment status is "succeeded"
  3. Checks the payment intent hasn't been used before
  4. Only then activates the subscription

**Example (Stripe Payment)**:
```javascript
// Step 1: Create payment intent
const { clientSecret, paymentIntentId } = await createPaymentIntent('johndoe', 1);

// Step 2: Client confirms payment with Stripe SDK (handled by client)
// const { paymentIntent } = await stripe.confirmPayment(clientSecret, {...});

// Step 3: Activate subscription with verified payment
const response = await fetch('http://localhost:3000/payments/subscribe', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    username: 'johndoe',
    plan_type: 'pro',
    payment_method: 'stripe',
    payment_intent_id: paymentIntentId
  })
});
```

**Example (Test Mode)**:
```javascript
const response = await fetch('http://localhost:3000/payments/subscribe', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    username: 'johndoe',
    plan_type: 'pro',
    payment_method: 'test'
  })
});
```

---

## Payment Flow

### Stripe Payment Flow

```
Client                          Server                          Stripe
  |                               |                               |
  |-- POST /create-payment-intent-→|                               |
  |                               |-- Create PaymentIntent ------→|
  |                               |←------ PaymentIntent ---------|
  |←--- clientSecret, intentId ---|                               |
  |                               |                               |
  |-- Confirm Payment (SDK) -------------------------------→|
  |←----------------------- Payment Succeeded ------------------|
  |                               |                               |
  |-- POST /subscribe -----------→|                               |
  |   (with payment_intent_id)    |                               |
  |                               |-- Retrieve PaymentIntent ---→|
  |                               |←------ Verify Status ---------|
  |                               |                               |
  |                               |-- Create Transaction          |
  |                               |-- Activate Subscription       |
  |                               |-- Update User Premium Status  |
  |←--- Success Response ---------|                               |
```

### Test Mode Flow

```
Client                          Server
  |                               |
  |-- POST /subscribe -----------→|
  |   (payment_method: "test")    |
  |                               |
  |                               |-- Create Transaction
  |                               |-- Activate Subscription
  |                               |-- Update User Premium Status
  |←--- Success Response ---------|
```

---

## Security Features

### 1. Payment Verification
- Server validates PaymentIntent status with Stripe before activation
- Client cannot fake successful payments

### 2. Duplicate Payment Prevention
- Each PaymentIntent can only be used once
- Database constraint ensures uniqueness

### 3. Server-Side Processing
- All payment logic happens on the server
- Client only provides the PaymentIntent ID

### 4. Environment Variables
- Stripe secret key is stored in environment variables
- Never exposed to the client

---

## Testing

### Using Stripe Test Cards

When using Stripe in test mode, use these test card numbers:

- **Success**: `4242 4242 4242 4242`
- **Declined**: `4000 0000 0000 0002`
- **Requires Authentication**: `4000 0025 0000 3155`

**Card Details**:
- **Expiry**: Any future date (e.g., 12/25)
- **CVC**: Any 3 digits (e.g., 123)
- **ZIP**: Any 5 digits (e.g., 12345)

More test cards: [Stripe Testing Documentation](https://stripe.com/docs/testing)

### Running the Test Script

```bash
# Make sure server is running
npm start

# In another terminal, run the test script
node test-payment-flow.js
```

Update `BASE_URL` and `TEST_USERNAME` in the script before running.

---

## Pricing

### Current Configuration

- **Test Mode Price**: $0.01 USD (1 cent)
- **Currency**: USD for Stripe, VND for test mode
- **Duration**: 1 month
- **Stripe Minimum**: Stripe requires a minimum of $0.50 USD for real transactions

### Changing the Price

To change the price, update the `create-payment-intent` endpoint:

```javascript
// In routes/payment.routes.js
const amountInCents = Math.max(1, Math.floor(amount * 100));
// Change the default amount parameter in the endpoint
```

---

## Database Schema

### Updated `payment_transactions` Table

```sql
CREATE TABLE payment_transactions (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL REFERENCES users(username) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL,
  currency TEXT DEFAULT 'VND',
  plan_type TEXT NOT NULL CHECK (plan_type IN ('pro')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  payment_method TEXT DEFAULT 'test',
  payment_intent_id TEXT UNIQUE,  -- NEW: Stripe PaymentIntent ID
  transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## Troubleshooting

### Common Issues

**1. "Stripe is not defined" Error**
- Make sure `STRIPE_SECRET_KEY` is set in `.env`
- Restart the server after adding the key

**2. "Payment not completed" Error**
- The PaymentIntent status must be "succeeded"
- Check if the client successfully confirmed the payment

**3. "This payment has already been used" Error**
- Each PaymentIntent can only be used once
- Create a new PaymentIntent for a new payment

**4. Database Error on payment_intent_id**
- Run the database migration to add the column
- See "Setup Instructions" section above

---

## Going to Production

### Checklist

Before going live with real payments:

1. **Switch to Production Keys**
   - Replace test keys (`sk_test_`) with production keys (`sk_live_`)
   - Get production keys from [Stripe Dashboard - Live Mode](https://dashboard.stripe.com/apikeys)

2. **Update Pricing**
   - Change from test price ($0.01) to real price (e.g., $9.99)
   - Update client to show correct price

3. **Remove Test Mode Option**
   - Remove the "Quick Test Mode" button from client
   - Only allow Stripe payments in production

4. **Security Audit**
   - Ensure all Stripe keys are in environment variables
   - Verify RLS (Row Level Security) policies on Supabase
   - Enable HTTPS for all API calls

5. **Testing**
   - Test the full payment flow in production mode
   - Use Stripe test cards in test mode first
   - Verify webhooks (if implemented)

---

## Additional Resources

- [Stripe API Documentation](https://stripe.com/docs/api)
- [Stripe React Native SDK](https://stripe.dev/stripe-react-native/)
- [Stripe Testing Guide](https://stripe.com/docs/testing)
- [Stripe Dashboard](https://dashboard.stripe.com)

---

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review Stripe logs in [Stripe Dashboard - Logs](https://dashboard.stripe.com/test/logs)
3. Check server logs for error messages
4. Consult Stripe documentation

---

## License

This implementation is part of the ConnectSphere server project.
