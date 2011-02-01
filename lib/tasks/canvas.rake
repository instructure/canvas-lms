namespace :canvas do
  desc "Compresses static assets"
  task :compress_assets do
    assets = FileList.new('public/**/*.js', 'public/**/*.css')
    before_bytes = 0
    after_bytes = 0
    processed = 0
    assets.each do |asset|
      asset_compressed = "#{asset}.gz"
      unless File.exists?(asset_compressed)
        `gzip --best --stdout "#{asset}" > "#{asset_compressed}"`
        before_bytes += File::Stat.new(asset).size
        after_bytes += File::Stat.new(asset_compressed).size
        processed += 1
      end
    end
    puts "Compressed #{processed} assets, #{before_bytes} -> #{after_bytes} bytes (#{"%.0f" % ((before_bytes.to_f - after_bytes.to_f) / before_bytes * 100)}% reduction)"
  end
  
  desc "Compile javascript and css assets."
  task :compile_assets do
    puts "--> Compiling static assets [compass -s compressed --force]"
    output = `bundle exec compass -s compressed --force 2>&1`
    raise "Error running compass: \n#{output}\nABORTING" if $?.exitstatus != 0
    
    puts "--> Compiling static assets [jammit]"
    output = `bundle exec jammit 2>&1`
    raise "Error running jammit: \n#{output}\nABORTING" if $?.exitstatus != 0
  end
end

namespace :db do
  desc "Shows pending db migrations."
  task :pending_migrations => :environment do
    pending_migrations = ActiveRecord::Migrator.new(:up, 'db/migrate').pending_migrations
    pending_migrations.each do |pending_migration|
      puts '  %4d %s' % [pending_migration.version, pending_migration.name]
    end
  end

  namespace :test do
    task :reset => [:environment, :load_config] do
      raise "Run with RAILS_ENV=test" unless Rails.env.test?
      config = ActiveRecord::Base.configurations['test']
      queue = config['queue']
      drop_database(queue) if queue rescue nil
      drop_database(config) rescue nil
      create_database(queue) if queue
      create_database(config)
      Rake::Task['db:migrate'].invoke
    end
  end
end
