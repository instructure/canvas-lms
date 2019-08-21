namespace :strongmind_defaults do
  desc "set api page limit"
  task :api_page_limit => :environment do
    Setting.set('api_max_per_page', '100')
    limit = Setting.get('api_max_per_page', 0)
    puts "Api page limit set to: #{limit}"
  end

  desc "set default api throttling"
  task :set_api_throttling_defaults => :environment do
    Setting.set('request_throttle.maximum', '8000')
    maximum = Setting.get('request_throttle.maximum', 0)
    puts "Api throttle maximum set to: #{maximum}"
    Setting.set('request_throttle.hwm', '6000')
    hwm = Setting.get('request_throttle.hwm', 0)
    puts "Api throttle HWM set to: #{maximum}"
  end

  desc "set default gradebook many_submissions_chunk_size"
  task :set_gradebook_submissions_chunk_size => :environment do
    Setting.set('gradebook2.many_submissions_chunk_size', '5')
    chunk_size = Setting.get('gradebook2.many_submissions_chunk_size', 0)
    puts "Gradebook submissions_chunk_size set to: #{chunk_size}"
  end

  desc "create dynamo db tables"
  task :create_dynamo_db_tables => :environment do
    ['assignment', 'user', 'enrollment', 'student_assignment', 'course', 'assignment'].each do |obj|
      begin
        SettingsService.update_settings(id: '1', setting: 'initialize', value: '1', object: obj)
      rescue
        sleep 10
        SettingsService.update_settings(id: '1', setting: 'initialize', value: '1', object: obj)
      end
      puts "Created default tables"
    end
  end

  desc "create school setting defaults"
  task :create_school_settings => :environment do
    SettingsService.update_settings(id: '1', setting: 'lti_keep_highest_score', value: true, object: "school")
    SettingsService.update_settings(id: '1', setting: 'pipeline_sqs_url', value: "https://sqs.us-west-2.amazonaws.com/448312246740/production-pipeline-queue", object: "school")
    SettingsService.update_settings(id: '1', setting: 'publish_page_views', value: true, object: "school")
    SettingsService.update_settings(
        id: '1',
        setting: 'allowed_filetypes',
        value: ".txt,.gif,.ppt,.pptx,.png,.zip,.m4v,.dot,.m4a,.csv,.jpeg,.jpg,.xlsx,.xls,.ods,.pdf,.mp4,.ogg,.rtf,.docx",
        object: "school"
      )
    SettingsService.update_settings(id: '1', setting: "ga_tracking_id", value: "UA-36373320-13", object: "school")
    settings =  SettingsService.get_settings(object: "school", id: 1);
    puts "set default school settings: #{settings}"
  end

  desc "Set site admin name"
  task :site_admin_name => :environment do
    site_admin = Account.site_admin
    site_admin.name = 'Courseware Admin'
    site_admin.save
    puts "Set site admin name to #{site_admin.name}"
  end

  desc "Set school name"
  task :school_name => :environment do
    return unless ENV['SCHOOL_NAME']
    school_account = Account.find(1)
    school_account.name = ENV['SCHOOL_NAME']
    school_account.save
    puts "Set school account name to #{school_account.name}"
  end

  desc "Set school time zone"
  task :school_tz => :environment do
    return unless ENV['SCHOOL_TZ']
    tz = ActiveSupport::TimeZone.create(ENV['SCHOOL_TZ'])
    school_account = Account.find(1)
    school_account.default_time_zone = tz
    school_account.save
    puts "Set school time zone to #{school_account.time_zone.name}"
  end


  desc "feature flags"
  task :feature_flags => :environment do
    school_account = Account.find(1)
    school_account.settings.update(:enable_profiles => true)
    school_account.save
    puts "Set enable_profiles to true"
  end
end
