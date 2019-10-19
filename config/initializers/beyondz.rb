class BeyondZConfiguration
  @config = (ConfigFile.load("beyondz") || {}).symbolize_keys

  # Returns the URL of the configured public facing beyondz.org server with the
  # specified path_symbol concatenated.
  def self.url(path_symbol)
    path = @config[path_symbol]
    path = path[1 .. -1] if path.starts_with?('/')
    "#{@config[:base_url]}#{path}"
  end

  # Returns the Google Analytics token if configured or nil if not.  Example token: UA-XXXXXXXX-1 
  def self.google_analytics_account
    @config[:google_analytics_account]
  end

  def self.bitly_access_token
    @config[:bitly_access_token]
  end
  
  # True if it's safe to show UI tools that are dangerous and only
  # safe to be exposed in a dev or testing environment.
  def self.dev_tools_enabled
    @config[:dev_tools_enabled]
  end

  def self.docusign_host
    @config[:docusign_host]
  end

  def self.docusign_api_key
    @config[:docusign_api_key]
  end

  def self.docusign_api_secret
    @config[:docusign_api_secret]
  end

  def self.docusign_return_url
    @config[:docusign_return_url]
  end

  def self.qualtrics_library_id
    @config[:qualtrics_library_id]
  end

  def self.qualtrics_api_token
    @config[:qualtrics_api_token]
  end

  def self.qualtrics_host
    @config[:qualtrics_host]
  end

  def self.production?
    # This is the value of a setting we set on production
    # remember to edit this if we ever rebrand again so this
    # setting always matches
    @config[:base_url] == 'https://join.bebraven.org/'
  end

  def self.safe_to_email?(email)
    return false if email.nil? || email.empty?
    # If we are on production, we can email anybody, but on staging or dev,
    # we should only email staff members or Adam's local domain test accounts.
    return self.production? || email.include?('@bebraven.org') || email.include?('@arsdnet.net')
  end

  # Returns the URL of the Braven Help site.  e.g. https://help.bebraven.org
  def self.help_url
    @config[:help_url]
  end

  # Returns the URL of the join server. Necessary for shared login on Champions page.  e.g. https://join.bebraven.org
  def self.join_url
    @config[:base_url]
  end
end
