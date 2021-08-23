# frozen_string_literal: true

Rake::Task['db:drop'].enhance do
  GuardRail.activate(:deploy) { Canvas.redis.flushdb }
end

# enhancing these _after_ switchman conveniently means it will execute only once,
# not once per shard, and after the migrations have run
%w{db:migrate db:migrate:predeploy db:migrate:up db:migrate:down db:rollback}.each do |task_name|
  Rake::Task[task_name].enhance do
    MultiCache.delete("schema_cache")
  end
end
