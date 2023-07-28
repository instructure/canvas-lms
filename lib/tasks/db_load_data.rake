# frozen_string_literal: true

def ping
  $stdout.sync = true
  print "."
end

def create_notification(values = {})
  ping
  Canvas::MessageHelper.create_notification(values)
end

def telemetry_enabled?
  (ENV["TELEMETRY_OPT_IN"] || "").present?
end

def obfuscate_input_or_echo(password = false)
  echo = password ? "*" : true
  telemetry_enabled? ? false : echo
end

namespace :db do
  desc "Generate security.yml key"
  task :generate_security_key do
    security_conf_path = Rails.root.join("config/security.yml")
    security_conf = YAML.load_file(security_conf_path)
    if security_conf[Rails.env]["encryption_key"].to_s.length < 20
      security_conf[Rails.env]["encryption_key"] = SecureRandom.hex(64)
      File.open(security_conf_path, "w") { |f| YAML.dump(security_conf, f) }
    end
  end

  desc "Load environment"
  task load_environment: [:generate_security_key, :environment] do
    raise "Please configure domain.yml" unless HostUrl.default_host
  end

  desc "Resets the encryption_key hash in the database. Needed if you change the encryption_key"
  task :reset_encryption_key_hash do
    ENV["UPDATE_ENCRYPTION_KEY_HASH"] = "1"
    Rake::Task["db:load_environment"].invoke
  end

  desc "Make sure all message templates have notifications in the db"
  task evaluate_notification_templates: :load_environment do
    Rails.root.glob("app/messages/*.erb") do |filename|
      filename = File.split(filename)[1]
      name = filename.split(".")[0]
      unless name[0, 1] == "_"
        titled = name.titleize.gsub("Sms", "SMS")
        puts "No notification found in db for #{name}" unless Notification.where(name: titled).first
      end
    end
    Notification.all_cached.each do |n|
      puts "No notification files found for #{n.name}" if Rails.root.glob("app/messages/#{n.name.downcase.gsub(/\s/, "_")}.*.erb").empty?
    end
  end

  desc "Find or create the notifications"
  task load_notifications: :load_environment do
    # Load the "notification_types.yml" file that provides initial values for the notifications.
    categories = YAML.safe_load(ERB.new(File.read(Canvas::MessageHelper.find_message_path("notification_types.yml"))).result)
    categories.each do |category|
      category["notifications"].each do |notification|
        create_notification({ name: notification["name"],
                              delay_for: notification["delay_for"],
                              category: category["category"] })
      end
    end
    puts "\nNotifications Loaded"
  end

  desc "Create default accounts"
  task create_default_accounts: :environment do
    Account.default(true)
    Account.site_admin(true)

    # This happens by default for all root accounts, but currently happens too
    # early in the migration run (in GrandfatherDefaultAccountInvitationPreviews)
    # to take effect.
    Account.default.enable_canvas_authentication
    Account.site_admin.enable_canvas_authentication
  end

  desc "Create an administrator user"
  task configure_admin: :load_environment do
    def create_admin(email, password)
      pseudonym = Account.site_admin.pseudonyms.active.by_unique_id(email).first
      pseudonym ||= Account.default.pseudonyms.active.by_unique_id(email).first
      user = pseudonym ? pseudonym.user : User.create!
      user.register! unless user.registered?
      unless pseudonym
        # don't pass the password in the create call, because that way is extra
        # picky. the admin should know what they're doing, and we'd rather not
        # fail here.
        pseudonym = user.pseudonyms.create!(unique_id: email,
                                            password: "validpassword",
                                            password_confirmation: "validpassword",
                                            account: Account.site_admin)
        user.communication_channels.create!(path: email) { |cc| cc.workflow_state = "active" }
      end
      # set the password later.
      pseudonym.password = pseudonym.password_confirmation = password
      unless pseudonym.save
        raise pseudonym.errors.full_messages.first unless pseudonym.errors.empty?

        raise "unknown error saving password"
      end
      Account.site_admin.account_users.where(user_id: user,
                                             role_id: Role.get_built_in_role("AccountAdmin", root_account_id: Account.site_admin.id)).first_or_create!
      Account.default.account_users.where(user_id: user,
                                          role_id: Role.get_built_in_role("AccountAdmin", root_account_id: Account.default.id)).first_or_create!
      user
    rescue => e
      warn "Problem creating administrative account, please try again: #{e}"
      nil
    end

    user = nil
    if !(ENV["CANVAS_LMS_ADMIN_EMAIL"] || "").empty? && !(ENV["CANVAS_LMS_ADMIN_PASSWORD"] || "").empty?
      user = create_admin(ENV["CANVAS_LMS_ADMIN_EMAIL"], ENV["CANVAS_LMS_ADMIN_PASSWORD"])
    end

    unless user
      require "highline/import"

      until Rails.env.test? do

        if telemetry_enabled?
          print "\e[33mInput fields will be hidden to ensure that entered data will not be sent to the telemetry service.\nWe do not recommend using sensitive data for development environments.\e[0m\n"
        end

        while true do
          email = ask("What email address will the site administrator account use? > ") { |q| q.echo = obfuscate_input_or_echo }
          email_confirm = ask("Please confirm > ") { |q| q.echo = obfuscate_input_or_echo }
          break if email == email_confirm
        end

        while true do
          password = ask("What password will the site administrator use? > ") { |q| q.echo = obfuscate_input_or_echo(true) }
          password_confirm = ask("Please confirm > ") { |q| q.echo = obfuscate_input_or_echo(true) }
          break if password == password_confirm
        end

        break if create_admin(email, password)
      end
    end
  end

  desc "Configure usage statistics collection"
  task configure_statistics_collection: [:load_environment] do
    gather_data = ENV["CANVAS_LMS_STATS_COLLECTION"] || ""
    gather_data = "opt_out" if gather_data.empty?

    if !Rails.env.test? && (ENV["CANVAS_LMS_STATS_COLLECTION"] || "").empty?
      require "highline/import"
      choose do |menu|
        menu.header = "To help our developers better serve you, Instructure would like to collect some usage data about your Canvas installation. You can change this setting at any time."
        menu.prompt = "> "
        menu.choice("Opt in") do
          gather_data = "opt_in"
          puts "Thank you for participating!"
        end
        menu.choice("Only send anonymized data") do
          gather_data = "anonymized"
          puts "Thank you for participating in anonymous usage collection."
        end
        menu.choice("Opt out completely") do
          gather_data = "opt_out"
          puts "You have opted out."
        end
      end

      puts "You can change this feature at any time by running the rake task 'rake db:configure_statistics_collection'"
    end

    Setting.set("usage_statistics_collection", gather_data)
    Reporting::CountsReport.process_shard
  end

  desc "Configure default settings"
  task configure_default_settings: :load_environment do
    Setting.set("support_multiple_account_types", "false")
    Setting.set("show_opensource_linkback", "true")
  end

  desc "generate data"
  task generate_data: %i[configure_default_settings
                         load_notifications
                         evaluate_notification_templates]

  desc "Configure Default Account Name"
  task configure_account_name: :load_environment do
    if (ENV["CANVAS_LMS_ACCOUNT_NAME"] || "").empty?
      require "highline/import"

      unless Rails.env.test?
        while true do
          name = ask("What do you want users to see as the account name? This should probably be the name of your organization. > ") { |q| q.echo = obfuscate_input_or_echo }
          break unless telemetry_enabled?

          name_confirm = ask("Please confirm > ") { |q| q.echo = obfuscate_input_or_echo }
          break if name == name_confirm
        end

        a = Account.default.reload
        a.name = name
        a.save!
      end
    else
      a = Account.default.reload
      a.name = ENV["CANVAS_LMS_ACCOUNT_NAME"]
      a.save!
    end
  end

  desc "Create all the initial data, including notifications and admin account"
  task load_initial_data: %i[create_default_accounts configure_admin configure_account_name configure_statistics_collection generate_data] do
    puts "\nInitial data loaded"
  end # Task: load_initial_data

  desc "Useful initial setup task"
  task initial_setup: [:environment, :generate_security_key] do
    Switchman::Shard.default(reload: true)
    Rake::Task["db:migrate"].invoke
    ActiveRecord::Base.connection.schema_cache.clear!
    ActiveRecord::Base.descendants.reject { |m| m == Shard }.each(&:reset_column_information)
    Account.clear_special_account_cache!(true)
    Rake::Task["db:load_initial_data"].invoke
  end
end # Namespace: db
