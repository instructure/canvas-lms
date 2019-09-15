namespace :db do

  desc "Loads the database dump at db/dev_db.sql.gz"
  task :load_dev => :environment do
    cmd = nil
    with_config do |app, host, db, user|
      cmd = "gunzip -c #{Rails.root}/db/dev_db.sql.gz | psql -h #{host} -U #{user} -w -d #{db}"
    end
    #puts 'Resetting encryption key hash'
    #Rake::Task['db:reset_encryption_key_hash'].invoke
    puts 'Dropping DB'
    Rake::Task["db:drop"].invoke
    puts 'Creating DB'
    Rake::Task["db:create"].invoke
    #Rake::Task["db:migrate"].invoke
    puts cmd
    exec cmd
    puts 'Development DB loaded'
  end

  private

  def with_config
    yield Rails.application.class.parent_name.underscore,
      ActiveRecord::Base.connection_config[:host],
      ActiveRecord::Base.connection_config[:database],
      ActiveRecord::Base.connection_config[:username]
  end

end # Namespace: db

