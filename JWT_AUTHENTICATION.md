# JWT Authentication Guide

## Overview
This CRM uses JWT (JSON Web Tokens) for stateless authentication. Tokens are signed using HS256 algorithm.

## Token Types

### Access Token
- **Lifetime:** 24 hours
- **Purpose:** Authenticate API requests
- **Usage:** Include in Authorization header

### Refresh Token
- **Lifetime:** 7 days
- **Purpose:** Obtain new access token without re-login
- **Usage:** Send to refresh endpoint

---

## Authentication Flow

### 1. User Registration

**Endpoint:** `POST /api/v1/auth/signup`

**Request:**
```json
{
  "user": {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePass123!",
    "password_confirmation": "SecurePass123!"
  },
  "account_name": "My Company" // Optional
}
```

**Response:**
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "display_name": null,
    "created_at": "2025-11-12T10:00:00Z"
  },
  "account": {
    "id": 1,
    "name": "My Company",
    "created_at": "2025-11-12T10:00:00Z"
  },
  "tokens": {
    "access_token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9...",
    "token_type": "Bearer",
    "expires_in": 86400
  },
  "message": "Registration successful"
}
```

---

### 2. User Login

**Endpoint:** `POST /api/v1/auth/login`

**Request:**
```json
{
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Response:**
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "display_name": "John",
    "avatar_url": null,
    "created_at": "2025-11-12T10:00:00Z"
  },
  "accounts": [
    {
      "id": 1,
      "name": "My Company",
      "role": "administrator",
      "availability": "online"
    }
  ],
  "tokens": {
    "access_token": "eyJhbGciOiJIUzI1NiJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9...",
    "token_type": "Bearer",
    "expires_in": 86400
  },
  "message": "Login successful"
}
```

---

### 3. Making Authenticated Requests

Include the access token in the Authorization header:

```http
GET /api/v1/accounts/1/conversations
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

**Example with curl:**
```bash
curl -X GET "http://localhost:3000/api/v1/accounts/1/conversations" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json"
```

**Example with JavaScript:**
```javascript
fetch('http://localhost:3000/api/v1/accounts/1/conversations', {
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
  }
})
```

---

### 4. Refreshing Access Token

When access token expires (after 24 hours), use refresh token to get new access token:

**Endpoint:** `POST /api/v1/auth/refresh`

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

**Response:**
```json
{
  "tokens": {
    "access_token": "eyJhbGciOiJIUzI1NiJ9...",
    "token_type": "Bearer",
    "expires_in": 86400
  },
  "message": "Token refreshed successfully"
}
```

---

### 5. Logout

**Endpoint:** `DELETE /api/v1/auth/logout`

**Request:**
```http
DELETE /api/v1/auth/logout
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

**Response:**
```json
{
  "message": "Logout successful. Please remove the token from client storage."
}
```

**Note:** JWT is stateless, so logout is handled client-side by removing tokens from storage.

---

## Error Responses

### Invalid Credentials (401)
```json
{
  "error": "Invalid credentials",
  "message": "The email or password you entered is incorrect"
}
```

### Missing Token (401)
```json
{
  "error": "Unauthorized",
  "message": "Missing token"
}
```

### Expired Token (401)
```json
{
  "error": "Token Expired",
  "message": "Your session has expired. Please login again."
}
```

### Invalid Token (401)
```json
{
  "error": "Unauthorized",
  "message": "Invalid token"
}
```

### Validation Errors (422)
```json
{
  "error": "Registration failed",
  "errors": [
    "Email has already been taken",
    "Password is too short (minimum is 6 characters)"
  ]
}
```

---

## Security Configuration

### Environment Variables

Create `.env` file:

```bash
# JWT Secret Key (use a strong, random string in production)
JWT_SECRET_KEY=your_super_secret_key_here_min_32_characters

# Generate a secure key:
# ruby -e "require 'securerandom'; puts SecureRandom.hex(32)"
```

### Production Configuration

In `config/credentials.yml.enc`:

```yaml
jwt:
  secret_key: your_production_secret_key_here
```

Access in code:
```ruby
Rails.application.credentials.jwt[:secret_key]
```

---

## Client-Side Token Storage

### Best Practices

1. **Store tokens securely:**
   - **Web:** Use httpOnly cookies or sessionStorage (not localStorage for sensitive data)
   - **Mobile:** Use secure storage (Keychain/Keystore)

2. **Implement token refresh:**
   ```javascript
   // Check if token is about to expire
   const isTokenExpiringSoon = (token) => {
     const decoded = JSON.parse(atob(token.split('.')[1]));
     const expiresIn = decoded.exp * 1000 - Date.now();
     return expiresIn < 5 * 60 * 1000; // 5 minutes
   };

   // Auto-refresh if needed
   if (isTokenExpiringSoon(accessToken)) {
     const newToken = await refreshAccessToken(refreshToken);
     setAccessToken(newToken);
   }
   ```

3. **Handle token expiration:**
   ```javascript
   axios.interceptors.response.use(
     response => response,
     async error => {
       if (error.response?.status === 401) {
         // Try to refresh token
         try {
           const newToken = await refreshAccessToken();
           // Retry original request
           error.config.headers.Authorization = `Bearer ${newToken}`;
           return axios(error.config);
         } catch {
           // Refresh failed, redirect to login
           window.location.href = '/login';
         }
       }
       return Promise.reject(error);
     }
   );
   ```

---

## Testing Authentication

### Using Postman

1. **Login:**
   - Method: POST
   - URL: `http://localhost:3000/api/v1/auth/login`
   - Body (JSON):
     ```json
     {
       "email": "admin@example.com",
       "password": "password123"
     }
     ```

2. **Copy access_token from response**

3. **Set Authorization for other requests:**
   - Type: Bearer Token
   - Token: [paste access_token]

### Using curl

```bash
# 1. Login and save response
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password123"}' \
  > login_response.json

# 2. Extract token (using jq)
TOKEN=$(cat login_response.json | jq -r '.tokens.access_token')

# 3. Make authenticated request
curl -X GET http://localhost:3000/api/v1/accounts/1/conversations \
  -H "Authorization: Bearer $TOKEN"
```

---

## Advanced Features

### Token Blacklist (Optional)

For enhanced security, implement token revocation using Redis:

```ruby
# app/services/token_blacklist.rb
class TokenBlacklist
  def self.add(token)
    decoded = JsonWebToken.decode(token)
    exp = decoded[:exp]
    ttl = exp - Time.now.to_i

    $redis.setex("blacklist:#{token}", ttl, "revoked") if ttl > 0
  end

  def self.blacklisted?(token)
    $redis.exists?("blacklist:#{token}")
  end
end
```

Update logout controller:
```ruby
def destroy
  token = request_token
  TokenBlacklist.add(token) if token
  render json: { message: 'Logout successful' }
end
```

---

## Troubleshooting

### "Missing token" error
- Ensure Authorization header is included
- Format: `Authorization: Bearer YOUR_TOKEN`

### "Token expired" error
- Use refresh token to get new access token
- Implement auto-refresh in frontend

### "Invalid token" error
- Token might be malformed or tampered
- Check if secret key matches between generation and validation

### CORS issues
- Ensure `rack-cors` is configured in `config/application.rb`
- Allow Authorization header in CORS config

---

## Summary

- ✅ **Access Token:** 24 hours, use for all API requests
- ✅ **Refresh Token:** 7 days, use to get new access token
- ✅ **Stateless:** No server-side session storage
- ✅ **Secure:** HS256 algorithm with secret key
- ✅ **Automatic:** Token validation on every request
- ✅ **Flexible:** Easy to implement token blacklist if needed
