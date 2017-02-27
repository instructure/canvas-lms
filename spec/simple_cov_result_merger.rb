require "simplecov"
require "simplecov-rcov"

class SimpleCov::Formatter::MergedFormatter
  def format(result)
    SimpleCov::Formatter::HTMLFormatter.new.format(result)
    SimpleCov::Formatter::RcovFormatter.new.format(result)
  end
end

SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
SimpleCov.add_filter '/spec/'
SimpleCov.add_filter '/config/'
SimpleCov.add_filter '/db_imports/'
SimpleCov.add_filter '/distributed_ci/'
SimpleCov.add_filter '/spec_canvas/'
SimpleCov.add_filter '/db/'
SimpleCov.add_filter '._cache/'

SimpleCov.add_group 'Controllers', 'app/controllers'
SimpleCov.add_group 'Models', 'app/models'
SimpleCov.add_group 'Services', 'app/services'
SimpleCov.add_group 'App', 'app/'
SimpleCov.add_group 'Gems', 'gems/'
SimpleCov.add_group 'Helpers', 'app/helpers'
SimpleCov.add_group 'Libraries', 'lib/'
SimpleCov.add_group 'Plugins', 'vendor/plugins'

SimpleCov.add_group "Long files" do |src_file|
  src_file.lines.count > 500
end

SimpleCov.result.format!
