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

  def self.production?
    @config[:base_url] == 'https://join.bebraven.org/'
  end

  def self.safe_to_email?(email)
    # If we are on production, we can email anybody, but on staging or dev,
    # we should only email staff members or Adam's local domain test accounts.
    self.production? || email.include? '@bebraven.org' || email.include? '@arsdnet.net'

  # Returns the URL of teh Braven Help site.  e.g. https://help.bebraven.org
  def self.help_url
    @config[:help_url]
  end
end
