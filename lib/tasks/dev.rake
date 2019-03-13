# StrongMind Added
namespace :dev do
  task :admin_password_email_reset => :environment do
    user        = User.first
    admin_email = 'admin@example.com'
    password    = 'password'

    User.transaction do
      user.email = admin_email
      user.save!

      pseudonym = user.primary_pseudonym
      pseudonym.update! unique_id: admin_email, password: 'password', password_confirmation: 'password'
    end
  end
end