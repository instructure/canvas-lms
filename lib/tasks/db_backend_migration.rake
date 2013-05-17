namespace :db do
  desc "migrate the page views in the database to cassandra"
  task :migrate_pageviews_to_cassandra, [:shard_id] => :environment do |t,args|
    shard = Shard.default
    if args[:shard_id]
      shard = Shard.find(args[:shard_id])
    end

    shard.activate do
      logger = ActiveSupport::BufferedLogger.new(STDERR)
      migrator = PageView::CassandraMigrator.new
      migrator.logger = logger
      migrator.run()
    end
  end
end
