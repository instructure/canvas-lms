class AccessToken < ActiveRecord::Base
  attr_reader :full_token
  belongs_to :developer_key
  belongs_to :user
  attr_accessible :user, :purpose, :expires_at, :developer_key, :regenerate, :scopes, :remember_access

  serialize :scopes, Array
  validate :must_only_include_valid_scopes

  has_many :communication_channels, dependent: :destroy

  # For user-generated tokens, purpose can be manually set.
  # For app-generated tokens, this should be generated based
  # on the scope defined in the auth process (scope has not
  # yet been implemented)

  scope :active, -> { where("expires_at IS NULL OR expires_at>?", Time.zone.now) }

  TOKEN_SIZE = 64
  OAUTH2_SCOPE_NAMESPACE = '/auth/'
  ALLOWED_SCOPES = ["#{OAUTH2_SCOPE_NAMESPACE}userinfo"]

  before_create :generate_token

  def self.authenticate(token_string)
    token = self.where(:crypted_token => hashed_token(token_string)).first
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

  def record_last_used_threshold
    Setting.get('access_token_last_used_threshold', 10.minutes).to_i
  end

  def used!
    if !last_used_at || last_used_at < record_last_used_threshold.ago
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
    self.token_hint = new_token[0,5]
  end

  def clear_full_token!
    @full_token = nil
  end

  def generate_token(overwrite=false)
    if overwrite || !self.crypted_token
      self.token = CanvasUuid::Uuid.generate(nil, TOKEN_SIZE)
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

  #Scoped token convenience method
  def scoped_to?(req_scopes)
    self.class.scopes_match?(scopes, req_scopes)
  end

  def self.scopes_match?(scopes, req_scopes)
    return req_scopes.size == 0 if scopes.nil?

    scopes.size == req_scopes.size &&
      scopes.all? do |scope|
        req_scopes.any? {|req_scope| scope[/(^|\/)#{req_scope}$/]}
      end
  end

  def must_only_include_valid_scopes
    return true if scopes.nil?
    errors.add(:scopes, "must match accepted scopes") unless scopes.all? {|scope| ALLOWED_SCOPES.include?(scope)}
  end

  # It's encrypted, but end users still shouldn't see this.
  # The hint is only returned in visible_token, if protected_token is false.
  def self.serialization_excludes; [:crypted_token, :token_hint]; end
end
