class Browser < Struct.new(:browser, :version)
  def self.supported?(user_agent)
    user_agent = UserAgent.parse(user_agent)
    supported_browsers.any?{ |browser| user_agent >= browser }
  end

  def self.configuration
    @configuration ||= YAML.load_file(Rails.root.join("config/browsers.yml"))
  end

  def self.supported_browsers
    @supported_browsers ||= (configuration['supported'] || []).
      map{ |browser, version| new(browser, version.to_s) }
  end
end

