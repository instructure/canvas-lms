class AccessToken < ActiveRecord::Base
  belongs_to :developer_key
  belongs_to :user
  attr_accessible :purpose, :expires_at, :developer_key, :regenerate
  # For user-generated tokens, purpose can be manually set.
  # For app-generated tokens, this should be generated based
  # on the scope defined in the auth process (scope has not
  # yet been implemented)
  
  before_create :generate_token
  
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
  
  def generate_token(overwrite=false)
    if overwrite || !self.token
      @token_just_generated = true
      self.token = AutoHandle.generate(nil, 64) 
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
    elsif @token_just_generated
      self.token
    else
      "#{self.token[0,5]}..."
    end
  end
  
  # Token is a protected attribute, since it's what applications
  # use when acting in behalf of a user.  If the user knew an app's
  # access token, they could pretend to be the app making calls 
  # on their behalf and cause mischief
  def self.serialization_excludes; [:token]; end
end
