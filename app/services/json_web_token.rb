# JWT Token Service for encoding and decoding tokens
class JsonWebToken
  # Secret key for encoding/decoding tokens
  # In production, this should come from ENV variable
  SECRET_KEY = Rails.application.credentials.secret_key_base || ENV.fetch('JWT_SECRET_KEY', 'development_secret_key')

  # Encode a payload into a JWT token
  # @param payload [Hash] Data to encode (usually user_id, exp)
  # @param exp [Integer] Expiration time in hours (default: 24 hours)
  # @return [String] JWT token
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  # Decode a JWT token
  # @param token [String] JWT token to decode
  # @return [HashWithIndifferentAccess] Decoded payload
  # @raise [JWT::DecodeError] If token is invalid or expired
  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY, true, { algorithm: 'HS256' })[0]
    HashWithIndifferentAccess.new(body)
  rescue JWT::ExpiredSignature, JWT::VerificationError => e
    raise ExceptionHandler::ExpiredSignature, e.message
  rescue JWT::DecodeError, JWT::VerificationError => e
    raise ExceptionHandler::InvalidToken, e.message
  end

  # Generate access token (24 hours)
  def self.access_token(user_id)
    encode({ user_id: user_id }, 24.hours.from_now)
  end

  # Generate refresh token (7 days)
  def self.refresh_token(user_id)
    encode({ user_id: user_id, type: 'refresh' }, 7.days.from_now)
  end
end
