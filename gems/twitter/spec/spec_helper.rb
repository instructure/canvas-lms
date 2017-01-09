require 'twitter'
require 'byebug'

I18n.load_path += Dir[File.join('spec','locales','*.yml')]

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'
end
