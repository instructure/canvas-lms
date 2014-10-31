class BeyondZConfiguration
  @config = (ConfigFile.load("beyondz") || {}).symbolize_keys

  def self.base_url
    @config[:base_url]
  end
end
