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

  # This returns an array of user IDs who are allowed to post anything to the html
  # boxes - including scripts and anything else that would normally be filtered out.
  #
  # Should only be trusted admin editors who need to add custom interactivity, etc.
  def self.unrestricted_html_users
    @config[:unrestricted_html_users]
  end

end
