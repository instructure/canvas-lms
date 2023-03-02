# frozen_string_literal: true

Rake::Task["db:drop"].enhance do
  GuardRail.activate(:deploy) { Canvas.redis.flushdb }
end

# enhancing these _after_ switchman conveniently means it will execute only once,
# not once per shard, and after the migrations have run
%w[db:migrate db:migrate:predeploy db:migrate:up db:migrate:down db:rollback].each do |task_name|
  Rake::Task[task_name].enhance do
    MultiCache.delete("schema_cache")
  end
end

namespace :db do
  desc "Clear columns to be ignored for each model"
  task :clear_ignored_columns, [:table_name] => :environment do |_t, args|
    Diplomat::Kv.delete(
      "store/canvas/#{DynamicSettings.environment}/activerecord/ignored_columns/#{args[:table_name]}"
    )

    MultiCache.delete("schema_cache")
  end

  desc "Get columns to be ignored for each model"
  task :get_ignored_columns, [:table_name] => :environment do |_t, args|
    ignored_columns = Diplomat::Kv.get(
      "store/canvas/#{DynamicSettings.environment}/activerecord/ignored_columns/#{args[:table_name]}"
    )

    puts "Ignored Columns: #{ignored_columns}"
  rescue Diplomat::KeyNotFound
    puts "Ignored Columns: -"
  end

  desc "Set columns to be ignored for each model"
  task :set_ignored_columns, [:table_name, :columns] => :environment do |_t, args|
    Diplomat::Kv.put(
      "store/canvas/#{DynamicSettings.environment}/activerecord/ignored_columns/#{args[:table_name]}",
      args[:columns]
    )

    MultiCache.delete("schema_cache")
  end
end
