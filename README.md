# Forgot Password API Documentation

This document describes the forgot password flow using OTP (One-Time Password) sent via SMS.

## Overview

The forgot password flow consists of 3 steps:
1. **Request OTP** - Send OTP to employee's phone number
2. **Verify OTP** - Verify the OTP code and get reset token
3. **Reset Password** - Set new password using reset token

---

## Endpoints

### 1. Request OTP

**Endpoint:** `POST /forgot-password`

**Description:** Sends a 6-digit OTP code to the employee's phone number (`utas` field).

**Request Body:**
```json
{
  "utas": "99112233"
}
```

**Phone Number Format:**
- Accepts phone numbers with or without country code
- Automatically formats to `+976xxxxxxxx` format
- Supports formats like: `99112233`, `099112233`, `97699112233`, `+97699112233`

**Response (Success):**
```json
{
  "success": true,
  "message": "OTP код таны утас руу илгээгдлээ",
  "expiresAt": "2026-03-03T10:15:00.000Z"
}
```

**Response (Development/Testing):**
In non-production environments, the OTP code is also returned for testing:
```json
{
  "success": true,
  "message": "OTP код таны утас руу илгээгдлээ",
  "expiresAt": "2026-03-03T10:15:00.000Z",
  "otp": "123456"
}
```

**Error Responses:**
- `400` - Missing phone number
- `404` - Employee not found with that phone number

**OTP Details:**
- **Length:** 6 digits
- **Validity:** 10 minutes
- **Max Attempts:** 5 verification attempts per OTP
- **Auto-cleanup:** Expired OTPs are automatically deleted

---

### 2. Verify OTP

**Endpoint:** `POST /verify-otp`

**Description:** Verifies the OTP code and returns a reset token for password reset.

**Request Body:**
```json
{
  "utas": "99112233",
  "otp": "123456"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "OTP код баталгаажлаа",
  "resetToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Responses:**
- `400` - Missing phone number or OTP
- `400` - OTP not found or already used
- `400` - OTP expired
- `400` - Wrong OTP code
- `400` - Too many verification attempts (max 5)

**Reset Token Details:**
- **Validity:** 15 minutes
- **One-time use:** Token can only be used once
- **Purpose:** Only valid for password reset

---

### 3. Reset Password

**Endpoint:** `POST /reset-password`

**Description:** Sets a new password using the reset token from OTP verification.

**Request Body:**
```json
{
  "resetToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "newPassword": "newSecurePassword123"
}
```

**Password Requirements:**
- Minimum length: 6 characters
- No maximum length (but recommended to keep it reasonable)

**Response (Success):**
```json
{
  "success": true,
  "message": "Нууц үг амжилттай солигдлоо"
}
```

**Error Responses:**
- `400` - Missing reset token or new password
- `400` - Password too short (less than 6 characters)
- `400` - Invalid or expired reset token
- `400` - OTP not verified

---

## Complete Flow Example

### Step 1: Request OTP
```bash
curl -X POST http://localhost:8000/forgot-password \
  -H "Content-Type: application/json" \
  -d '{
    "utas": "99112233"
  }'
```

### Step 2: Verify OTP
```bash
curl -X POST http://localhost:8000/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "utas": "99112233",
    "otp": "123456"
  }'
```

### Step 3: Reset Password
```bash
curl -X POST http://localhost:8000/reset-password \
  -H "Content-Type: application/json" \
  -d '{
    "resetToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "newPassword": "myNewPassword123"
  }'
```

---

## Frontend Implementation Example

```typescript
// Step 1: Request OTP
const requestOTP = async (phoneNumber: string) => {
  const response = await axios.post('/forgot-password', {
    utas: phoneNumber
  });
  return response.data;
};

// Step 2: Verify OTP
const verifyOTP = async (phoneNumber: string, otp: string) => {
  const response = await axios.post('/verify-otp', {
    utas: phoneNumber,
    otp: otp
  });
  return response.data.resetToken;
};

// Step 3: Reset Password
const resetPassword = async (resetToken: string, newPassword: string) => {
  const response = await axios.post('/reset-password', {
    resetToken: resetToken,
    newPassword: newPassword
  });
  return response.data;
};

// Complete flow
const handleForgotPassword = async (phoneNumber: string) => {
  try {
    // Step 1: Request OTP
    await requestOTP(phoneNumber);
    alert('OTP код таны утас руу илгээгдлээ');
    
    // Step 2: Get OTP from user
    const otp = prompt('OTP код оруулна уу:');
    const resetToken = await verifyOTP(phoneNumber, otp);
    
    // Step 3: Get new password from user
    const newPassword = prompt('Шинэ нууц үг оруулна уу:');
    await resetPassword(resetToken, newPassword);
    
    alert('Нууц үг амжилттай солигдлоо!');
  } catch (error: any) {
    alert(error.response?.data?.message || 'Алдаа гарлаа');
  }
};
```

---

## SMS Integration (CallPro API)

The SMS service (`src/services/smsService.ts`) is integrated with **CallPro API** using the `msgIlgeeye` function pattern.

### How It Works

1. **CallPro Credentials:** The system automatically retrieves CallPro credentials (`msgIlgeekhKey`, `msgIlgeekhDugaar`) from `baiguullaga.tokhirgoo` based on the employee's `baiguullagiinId`.

2. **Fallback:** If `baiguullagiinId` is not provided, the system falls back to environment variables:
   - `MSG_ILGEEKH_KEY` - CallPro API key
   - `MSG_ILGEEKH_DUGAAR` - CallPro sender number

3. **Message Server:** The system uses `MSG_SERVER` environment variable for the CallPro API endpoint.

### Environment Variables

Add to your `.env` file:

```env
# CallPro API Configuration
MSG_SERVER=http://your-callpro-server.com
MSG_ILGEEKH_KEY=your_callpro_key
MSG_ILGEEKH_DUGAAR=72002002
```

### Database Configuration

The system automatically uses CallPro credentials from `baiguullaga` collection:

```javascript
{
  _id: ObjectId("..."),
  tokhirgoo: {
    msgIlgeekhKey: "aa8e588459fdd9b7ac0b809fc29cfae3",
    msgIlgeekhDugaar: "72002002"
  }
}
```

### API Call Format

The system sends SMS using the following CallPro API format:

```
GET {MSG_SERVER}/send?key={msgIlgeekhKey}&from={msgIlgeekhDugaar}&to={phone}&text={message}
```

### Testing

In development, you can test the SMS functionality. The system will:
- Log SMS sending attempts to console
- Return OTP codes in API response (non-production only)
- Use actual CallPro API if properly configured

---

## Security Features

1. **OTP Expiration:** OTPs expire after 10 minutes
2. **Attempt Limiting:** Maximum 5 verification attempts per OTP
3. **One-time Use:** Each OTP can only be verified once
4. **Auto-cleanup:** Expired OTPs are automatically deleted from database
5. **Reset Token Expiration:** Reset tokens expire after 15 minutes
6. **Password Hashing:** Passwords are hashed using bcrypt before storage
7. **Phone Number Formatting:** Automatic phone number validation and formatting

---

## Database Schema

The OTP model stores:
- `utas`: Phone number
- `ajiltniiId`: Employee ID
- `otp`: 6-digit OTP code
- `purpose`: Purpose (e.g., "forgot_password")
- `verified`: Whether OTP has been verified
- `expiresAt`: Expiration timestamp
- `attempts`: Number of verification attempts
- `maxAttempts`: Maximum allowed attempts (default: 5)

---

## Notes

- **Development Mode:** In non-production environments, OTP codes are returned in the API response for testing
- **Production Mode:** In production, OTP codes are only sent via SMS
- **Phone Number Lookup:** The system tries both formatted and original phone number formats for flexibility
- **Error Messages:** All error messages are in Mongolian for user-friendly experience
