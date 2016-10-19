namespace :dev do
  namespace :seed do
    desc 'Seed the database with a given number of users'
    task :users, [:user_count, :start_idx] => :environment do |t, args|
      users_to_create = args.fetch(:user_count, '0').to_i
      starting_idx = args.fetch(:start_idx, '0').to_i

      ActiveRecord::Base.transaction do
        (starting_idx...(starting_idx + users_to_create)).each do |user_idx|
          puts "Creating User ##{user_idx}"
          user_attrs = {
            name: "User ##{user_idx}",
            short_name: "user#{user_idx}",
            sortable_name: "User ##{user_idx}",
          }

          user = User.create!(user_attrs)

          pseudonym_attrs = {
            account: user.account,
            unique_id: "user-#{user_idx}",
          }

          pseudonym = user.pseudonyms.create!(pseudonym_attrs)

          user.register
          pseudonym.password = pseudonym.password_confirmation = 'password'
          pseudonym.save!
        end
      end
    end
  end
end