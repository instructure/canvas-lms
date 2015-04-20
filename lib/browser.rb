require 'user_agent'

class Browser < Struct.new(:browser, :version)
  def self.supported?(user_agent)
    user_agent = UserAgent.parse(user_agent)
    return false if minimum_browsers.any?{ |browser| user_agent < browser }
    true # if we don't recognize it (e.g. Android), be nice
  end

  def self.configuration
    @configuration ||= YAML.load_file(File.expand_path('../../config/browsers.yml', __FILE__))
  end

  def self.minimum_browsers
    @minimum_browsers ||= (configuration['minimums'] || []).
      map{ |browser, version| new(browser, version.to_s) }
  end
end

