module Canvas

class CoffeeScript
  def self.coffee_script_binary_is_available?
    return @is_available if instance_variable_defined?(:@is_available)
    # patch up the path to make sure we get node_modules bin, which should ensure the proper
    # pinned coffee-script
    ENV['PATH'] = 'node_modules/.bin:' + ENV['PATH']
    coffee_is_installed = `which coffee` && $?.success?
    if coffee_is_installed
      coffee_version = `coffee -v`.strip
      coffee_is_correct_version = coffee_version.match(::CoffeeScript.version)
      unless coffee_is_correct_version
        puts "--> WARNING #{coffee_version} != pinned coffee-script-source: #{::CoffeeScript.version}"
      end
    end
    @is_available = coffee_is_installed && coffee_is_correct_version
  end
end

end
