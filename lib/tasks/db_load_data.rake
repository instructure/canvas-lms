require 'securerandom'

def ping
  STDOUT.sync = true
  print '.'
end
  
def create_notification(values = {})
  ping
  Canvas::MessageHelper.create_notification(values)
end

def create_scribd_mime_type(ext, name)
  ScribdMimeType.find_or_create_by_extension_and_name(ext, name)
end

namespace :db do
  desc "Generate security.yml key"
  task :generate_security_key do
    security_conf_path = Rails.root.join('config', 'security.yml')
    security_conf = YAML.load_file(security_conf_path)
    if security_conf[Rails.env]["encryption_key"].to_s.length < 20
      security_conf[Rails.env]["encryption_key"] = SecureRandom.hex(64)
      File.open(security_conf_path, 'w') { |f| YAML.dump(security_conf, f) }
    end
  end

  desc "Load environment"
  task :load_environment => [:generate_security_key, :environment] do
    raise "Please configure domain.yml" unless HostUrl.default_host
  end

  desc "Resets the encryption_key hash in the database. Needed if you change the encryption_key"
  task :reset_encryption_key_hash do
    ENV['UPDATE_ENCRYPTION_KEY_HASH'] = "1"
    Rake::Task['db:load_environment'].invoke
  end

  desc "Make sure all scribd mime types are set up correctly"
  task :ensure_scribd_mime_types => :load_environment do
    ping
    create_scribd_mime_type('doc', 'application/msword')
    ping
    create_scribd_mime_type('ppt', 'application/vnd.ms-powerpoint')
    ping
    create_scribd_mime_type('pdf', 'application/pdf')
    ping
    create_scribd_mime_type('xls', 'application/vnd.ms-excel')
    ping
    create_scribd_mime_type('ps', 'application/postscript')
    ping
    create_scribd_mime_type('rtf', 'application/rtf')
    ping
    create_scribd_mime_type('rtf', 'text/rtf')
    ping
    create_scribd_mime_type('docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    ping
    create_scribd_mime_type('pptx', 'application/vnd.openxmlformats-officedocument.presentationml.presentation')
    ping
    create_scribd_mime_type('xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    ping
    create_scribd_mime_type('ppt', 'application/mspowerpoint')
    ping
    create_scribd_mime_type('xls', 'application/excel')
    ping
    create_scribd_mime_type('txt', 'text/plain')
    ping
    create_scribd_mime_type('odt', 'application/vnd.oasis.opendocument.text')
    ping
    create_scribd_mime_type('odp', 'application/vnd.oasis.opendocument.presentation')
    ping
    create_scribd_mime_type('ods', 'application/vnd.oasis.opendocument.spreadsheet')
    ping
    create_scribd_mime_type('sxw', 'application/vnd.sun.xml.writer')
    ping
    create_scribd_mime_type('sxi', 'application/vnd.sun.xml.impress')
    ping
    create_scribd_mime_type('sxc', 'application/vnd.sun.xml.calc')
    ping
    create_scribd_mime_type('xltx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.template')
    ping
    create_scribd_mime_type('ppsx', 'application/vnd.openxmlformats-officedocument.presentationml.slideshow')
    ping
    create_scribd_mime_type('potx', 'application/vnd.openxmlformats-officedocument.presentationml.template')
    ping
    create_scribd_mime_type('dotx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.template')
    ping
    puts 'Scribd Mime Types added'
  end
  desc "Make sure all message templates have notifications in the db"
  task :evaluate_notification_templates => :load_environment do
    Dir.glob(Rails.root.join('app', 'messages', '*.erb')) do |filename|
      filename = File.split(filename)[1]
      name = filename.split(".")[0]
      unless name[0,1] == "_"
        titled = name.titleize.gsub(/Sms/, 'SMS')
        puts "No notification found in db for #{name}" unless Notification.find_by_name(titled)
      end
    end
    Notification.all.each do |n|
      puts "No notification files found for #{n.name}" if Dir.glob(Rails.root.join('app', 'messages', "#{n.name.downcase.gsub(/\s/, '_')}.*.erb")).empty?
    end
  end
  
  desc "Find or create the notifications"
  task :load_notifications => :load_environment do
    # Load the "notification_types.yml" file that provides initial values for the notifications.
    categories = YAML.load(ERB.new(File.read(Canvas::MessageHelper.find_message_path('notification_types.yml'))).result)
    categories.each do |category|
      category['notifications'].each do |notification|
        create_notification({:name => notification['name'],
                             :delay_for => notification['delay_for'],
                             :category => category['category']})
      end
    end
    puts "\nNotifications Loaded"
  end
  
  desc "Create an administrator account"
  task :configure_admin => :load_environment do

    def create_admin(email, password)
      begin
        pseudonym = Account.site_admin.pseudonyms.active.custom_find_by_unique_id(email)
        pseudonym ||= Account.default.pseudonyms.active.custom_find_by_unique_id(email)
        user = pseudonym ? pseudonym.user : User.create!
        user.register! unless user.registered?
        unless pseudonym
          # don't pass the password in the create call, because that way is extra
          # picky. the admin should know what they're doing, and we'd rather not
          # fail here.
          pseudonym = user.pseudonyms.create!(:unique_id => email,
              :password => "validpassword", :password_confirmation => "validpassword", :account => Account.site_admin)
          user.communication_channels.create!(:path => email) { |cc| cc.workflow_state = 'active' }
        end
        # set the password later.
        pseudonym.password = pseudonym.password_confirmation = password
        unless pseudonym.save
          raise pseudonym.errors.full_messages.first if pseudonym.errors.size > 0
          raise "unknown error saving password"
        end
        Account.site_admin.account_users.where(user_id: user, membership_type: 'AccountAdmin').first_or_create!
        Account.default.account_users.where(user_id: user, membership_type: 'AccountAdmin').first_or_create!
        user
      rescue => e
        STDERR.puts "Problem creating administrative account, please try again: #{e}"
        nil
      end
    end

    user = nil
    if !(ENV['CANVAS_LMS_ADMIN_EMAIL'] || "").empty? && !(ENV['CANVAS_LMS_ADMIN_PASSWORD'] || "").empty?
      user = create_admin(ENV['CANVAS_LMS_ADMIN_EMAIL'], ENV['CANVAS_LMS_ADMIN_PASSWORD'])
    end

    unless user
      require 'highline/import'

      while !Rails.env.test? do

        while true do
          email = ask("What email address will the site administrator account use? > ") { |q| q.echo = true }
          email_confirm = ask("Please confirm > ") { |q| q.echo = true }
          break if email == email_confirm
        end

        while true do
          password = ask("What password will the site administrator use? > ") { |q| q.echo = "*" }
          password_confirm = ask("Please confirm > ") { |q| q.echo = "*" }
          break if password == password_confirm
        end

        break if create_admin(email, password)
      end
    end
  end
  
  desc "Configure usage statistics collection"
  task :configure_statistics_collection => [:load_environment] do
    gather_data = ENV["CANVAS_LMS_STATS_COLLECTION"] || ""
    gather_data = "opt_out" if gather_data.empty?

    if !Rails.env.test? && (ENV["CANVAS_LMS_STATS_COLLECTION"] || "").empty?
      require 'highline/import'
      choose do |menu|
        menu.header = "To help our developers better serve you, Instructure would like to collect some usage data about your Canvas installation. You can change this setting at any time."
        menu.prompt = "> "
        menu.choice("Opt in") {
          gather_data = "opt_in"
          puts "Thank you for participating!"
        }
        menu.choice("Only send anonymized data") {
          gather_data = "anonymized"
          puts "Thank you for participating in anonymous usage collection."
        }
        menu.choice("Opt out completely") {
          gather_data = "opt_out"
          puts "You have opted out."
        }
      end
    
      puts "You can change this feature at any time by running the rake task 'rake db:configure_statistics_collection'"
    end
    
    Setting.set("usage_statistics_collection", gather_data)
    Reporting::CountsReport.process
  end
  
  desc "Configure default settings"
  task :configure_default_settings => :load_environment do
    Setting.set("support_multiple_account_types", "false")
    Setting.set("show_opensource_linkback", "true")
  end
  
  desc "generate data"
  task :generate_data => [:configure_default_settings, :load_notifications, :ensure_scribd_mime_types,
      :evaluate_notification_templates] do
  end
  
  desc "Configure Default Account Name"
  task :configure_account_name => :load_environment do
    if (ENV['CANVAS_LMS_ACCOUNT_NAME'] || "").empty?
      require 'highline/import'

      if !Rails.env.test?
        name = ask("What do you want users to see as the account name? This should probably be the name of your organization. > ") { |q| q.echo = true }

        a = Account.default.reload
        a.name = name
        a.save!
      end
    else
      a = Account.default.reload
      a.name = ENV['CANVAS_LMS_ACCOUNT_NAME']
      a.save!
    end
  end
  
  desc "Create all the initial data, including notifications and admin account"
  task :load_initial_data => [:configure_admin, :configure_account_name, :configure_statistics_collection, :generate_data] do
   
    puts "\nInitial data loaded"
    
  end # Task: load_initial_data
  
  desc "Useful initial setup task"
  task :initial_setup => [:generate_security_key, :migrate] do
    load 'app/models/pseudonym.rb'
    ActiveRecord::Base.connection.schema_cache.clear! unless CANVAS_RAILS2
    ActiveRecord::Base.all_models.reject{ |m| m == Shard }.each(&:reset_column_information)
    Rake::Task['db:load_initial_data'].invoke
  end
  
end # Namespace: db


