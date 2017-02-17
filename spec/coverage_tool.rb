require 'simplecov'

class CoverageTool
  def self.start(command_name)
    SimpleCov.merge_timeout(3600)
    SimpleCov.command_name(command_name)
    SimpleCov.start do
      SimpleCov.coverage_dir("#{ENV['WORKSPACE']}/coverage") if ENV['WORKSPACE']
      # no formatting by default, just get the json
      SimpleCov.at_exit { SimpleCov.result }
    end
  end
end
