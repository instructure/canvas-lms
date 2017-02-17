class AccessToken < ActiveRecord::Base
  attr_reader :full_token
  attr_reader :plaintext_refresh_token
  belongs_to :developer_key
  belongs_to :user
  has_one :account, through: :developer_key

  serialize :scopes, Array
  validate :must_only_include_valid_scopes

  has_many :notification_endpoints, dependent: :destroy

  before_validation -> { self.developer_key ||= DeveloperKey.default }

  # For user-generated tokens, purpose can be manually set.
  # For app-generated tokens, this should be generated based
  # on the scope defined in the auth process (scope has not
  # yet been implemented)

  scope :active, -> { where("expires_at IS NULL OR expires_at>?", DateTime.now.utc) }

  TOKEN_SIZE = 64
  OAUTH2_SCOPE_NAMESPACE = '/auth/'
  ALLOWED_SCOPES = ["#{OAUTH2_SCOPE_NAMESPACE}userinfo"]

  before_create :generate_token
  before_create :generate_refresh_token

  def self.authenticate(token_string, token_key = :crypted_token)
    # hash the user supplied token with all of our known keys
    # attempt to find a token that matches one of the hashes
    hashed_tokens = all_hashed_tokens(token_string)
    token = self.where(token_key => hashed_tokens).first
    if token && token.send(token_key) != hashed_tokens.first
      # we found the token but, its hashed using an old key. save the updated hash
      token.send("#{token_key}=", hashed_tokens.first)
      token.save!
    end
    token = nil unless token.try(:usable?, token_key)
    token
  end

  def self.authenticate_refresh_token(token_string)
    self.authenticate(token_string, :crypted_refresh_token)
  end

  def self.hashed_token(token)
    # This use of hmac is a bit odd, since we aren't really signing a message
    # other than the random token string itself.
    # However, what we're essentially looking for is a hash of the token
    # "signed" or concatenated with the secret encryption key, so this is perfect.
    Canvas::Security.hmac_sha1(token)
  end

  def self.all_hashed_tokens(token)
    Canvas::Security.encryption_keys.map { |key| Canvas::Security.hmac_sha1(token, key) }
  end

  def usable?(token_key = :crypted_token)
    # true if
    # developer key is active AND
    # there is a user id AND
    # its not expired OR Its a refresh token
    # since you need a refresh token to
    # refresh expired tokens

    if !developer_key_id || cached_developer_key.try(:active?)
      # we are a stand alone token, or a token with an active developer key
      # make sure we
      #   - have a user id
      #   - its a refresh token
      #     - If we aren't a refresh token. make sure we aren't expired
      return true if user_id && (token_key == :crypted_refresh_token || !expired?)
    end
    false
  end

  def app_name
    cached_developer_key.try(:name) || "No App"
  end

  def authorized_for_account?(target_account)
    return true unless cached_developer_key
    cached_developer_key.authorized_for_account?(target_account)
  end

  def record_last_used_threshold
    Setting.get('access_token_last_used_threshold', 10.minutes).to_i
  end

  def used!
    if !last_used_at || last_used_at < record_last_used_threshold.seconds.ago
      self.last_used_at = DateTime.now.utc
      self.save
    end
  end

  def expired?
    (slaved_developer_key == DeveloperKey.default || slaved_developer_key.try(:auto_expire_tokens)) && expires_at && expires_at < DateTime.now.utc
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
      self.token = CanvasSlug.generate(nil, TOKEN_SIZE)

      if slaved_developer_key != DeveloperKey.default && !self.expires_at_changed? && slaved_developer_key.try(:auto_expire_tokens)
        self.expires_at = DateTime.now.utc + 1.hour
      end
    end
  end

  def refresh_token=(new_token)
    self.crypted_refresh_token = AccessToken.hashed_token(new_token)
    @plaintext_refresh_token = new_token
  end

  def generate_refresh_token(overwrite=false)
    if overwrite || !self.crypted_refresh_token
      self.refresh_token = CanvasSlug.generate(nil, TOKEN_SIZE)
    end
  end

  def regenerate_refresh_token=(val)
    if val == '1' && !protected_token?
      generate_refresh_token(true)
    end
  end

  def clear_plaintext_refresh_token!
    @plaintext_refresh_token = nil
  end

  def protected_token?
    slaved_developer_key != DeveloperKey.default
  end

  def regenerate=(val)
    if val == '1' && !protected_token?
      generate_token(true)
    end
  end

  def regenerate_access_token
    generate_token(true)
    save
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
  def self.serialization_excludes
    [:crypted_token, :token_hint, :crypted_refresh_token]
  end

  private
  def cached_developer_key
    return nil unless developer_key_id
    @developer_key ||= DeveloperKey.find_cached(developer_key_id)
  end

  def slaved_developer_key
    Shackles.activate(:slave){ return developer_key }
  end
end
