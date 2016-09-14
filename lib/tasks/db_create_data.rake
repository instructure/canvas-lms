namespace :db do
  desc "Create a new user"
  task :create_user => :environment do
    require 'highline/import'
    shard = nil
    account = nil

    choose do |menu|
      default = nil
      Shard.all.each do |e|
        default ||= e.name
        menu.choice(e.name) do
          shard = Shard.find(e.id)
          shard.activate!
        end
      end
      menu.default = default
      menu.prompt = "Select a Shard: |#{default}| "
    end

    choose do |menu|
      default = nil
      Account.all.each do |a|
        default = a.name if a.id == 1
        menu.choice(a.name) do
          account = Account.find(a.id)
        end
      end
      menu.default = default
      menu.prompt = "Select an Account: |#{default}| "
    end

    user_first_name = ask ( "User's first name: ")
    user_last_name = ask ("User's last name: ")
    user_login = ask ("User's login: ")
    user_password = ask ("User's password: ")  { |q| q.default = 'useruser' }

    puts %Q{

    Shard: #{shard.name}[#{shard.id}]
    Account: #{account.name}[#{account.id}]
    Admin User: #{user_first_name} #{user_last_name}
    Username: #{user_login}
    Password: #{user_password}

    }

    exit unless agree("Does this look correct?") { |q| q.default = 'yes' }

    ActiveRecord::Base.transaction do
      begin
        user = User.create!(
          name: user_first_name + " " + user_last_name,
          short_name: user_first_name,
          sortable_name: user_last_name + " " + user_first_name
        )

        pseudonym = Pseudonym.create!(
          :account => account,
          :unique_id => user_login,
          :user => user
        )

        user.register
        pseudonym.password = pseudonym.password_confirmation = user_password
        pseudonym.save!
        puts "User Created!"
      rescue => e
        puts e
        raise ActiveRecord::Rollback
      end
      puts "Failed to create User!" unless user.persisted?
    end
  end
end
