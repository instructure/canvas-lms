class AccessToken < ActiveRecord::Base
  attr_reader :full_token
  belongs_to :developer_key
  belongs_to :user
  attr_accessible :user, :purpose, :expires_at, :developer_key, :regenerate
  # For user-generated tokens, purpose can be manually set.
  # For app-generated tokens, this should be generated based
  # on the scope defined in the auth process (scope has not
  # yet been implemented)

  TOKEN_SIZE = 64

  before_create :generate_token

  def self.authenticate(token_string)
    token = self.first(:conditions => ["crypted_token = ? OR (token = ? AND crypted_token IS NULL)", hashed_token(token_string), token_string])
    token = nil unless token.try(:usable?)
    token
  end

  def self.hashed_token(token)
    # This use of hmac is a bit odd, since we aren't really signing a message
    # other than the random token string itself.
    # However, what we're essentially looking for is a hash of the token
    # "signed" or concatenated with the secret encryption key, so this is perfect.
    Canvas::Security.hmac_sha1(token)
  end

  def usable?
    user_id && !expired?
  end

  def app_name
    developer_key.try(:name) || "No App"
  end

  def used!
    if !last_used_at || last_used_at < 5.minutes.ago
      self.last_used_at = Time.now
      self.save
    end
  end

  def expired?
    expires_at && expires_at < Time.now
  end

  def token=(new_token)
    self.crypted_token = AccessToken.hashed_token(new_token)
    @full_token = new_token
    write_attribute(:token, new_token)
    self.token_hint = new_token[0,5]
  end

  def generate_token(overwrite=false)
    if overwrite || !self.crypted_token
      self.token = AutoHandle.generate(nil, TOKEN_SIZE)
    end
  end

  def protected_token?
    developer_key != DeveloperKey.default
  end

  def regenerate=(val)
    if val == '1' && !protected_token?
      generate_token(true)
    end
  end

  def visible_token
    if protected_token?
      nil
    elsif full_token
      full_token
    else
      "#{token_hint}..."
    end
  end

  # Token is a protected attribute, since it's what applications
  # use when acting in behalf of a user.  If the user knew an app's
  # access token, they could pretend to be the app making calls 
  # on their behalf and cause mischief
  def self.serialization_excludes; [:token]; end
end
