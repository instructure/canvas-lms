require 'bookmarked_collection'

require 'support/active_record'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.color = true
  config.order = 'random'

  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

end
