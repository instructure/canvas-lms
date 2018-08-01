namespace :strongmind_defaults do
  desc "set api page limit"
  task :api_page_limit => :environment do
    Setting.set('api_max_per_page', '100')
    limit = Setting.get('api_max_per_page', 0)
    puts "Api page limit set to: #{limit}"
  end

  desc "create dynomo db tables"
  task :create_dynamo_db_tables => :environment do
    ['assignment', 'user', 'enrollment', 'student_assignment'].each do |obj|
      begin
        SettingsService.update_settings(id: '1', setting: 'initialize', value: '1', object: obj)
      rescue
        sleep 10
        SettingsService.update_settings(id: '1', setting: 'initialize', value: '1', object: obj)
      end
    end
  end

end
