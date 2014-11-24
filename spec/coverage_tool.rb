require 'simplecov'

class CoverageTool
  def self.start(command_name)
    SimpleCov.use_merging
    SimpleCov.merge_timeout(10000)
    SimpleCov.command_name(command_name)
    SimpleCov.start('test_frameworks') do
      SimpleCov.coverage_dir("#{ENV['WORKSPACE']}/coverage") if ENV['WORKSPACE']
      SimpleCov.at_exit {
        SimpleCov.result
        SimpleCov.result.format!
      }
    end
  end
end