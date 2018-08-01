namespace :strongmind_defaults do
  desc "set api page limit"
  task :api_page_limit => :environment do
    Setting.set('api_max_per_page', '100')
    limit = Setting.get('api_max_per_page', 0)
    puts "Api page limit set to: #{limit}"
  end
end
