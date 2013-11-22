$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '..'))
require "parallelized_specs"

namespace :parallel do

  desc "create test databases via db:create --> parallel:create[num_cpus]"
  task :create, :count do |t, args|
    ParallelizedSpecs.execute_parallel_db('rake db:create RAILS_ENV=test', args)
  end

  desc "drop test databases via db:drop --> parallel:drop[num_cpus]"
  task :drop, :count do |t, args|
    ParallelizedSpecs.execute_parallel_db('rake db:drop RAILS_ENV=test', args)
  end

  desc "run tasks in parallel"
  task :optional_task, :count, :task_name do |t, args|

    puts "these are all the args#{args}"
    puts "count = #{args[:count]} \n tasknames = #{args[:task_name]}"

    tasks = args[:task_name].to_s.split('*')
    tasks.each do |task|
     puts task
    end

    if tasks.length == 1
      ParallelizedSpecs.execute_parallel_db("rake #{tasks} RAILS_ENV=test", args)
    else
      tasks.each do |task|
        ParallelizedSpecs.execute_parallel_db("rake #{task} RAILS_ENV=test", args)
      end
    end
  end


  desc "update test databases by dumping and loading --> parallel:dump_load[num_cpus]"
  task(:dump_load, [:count] => 'db:abort_if_pending_migrations') do |t, args|
    if defined?(ActiveRecord) && ActiveRecord::Base.schema_format == :ruby
      # dump then load in parallel
      Rake::Task['db:schema:dump'].invoke
      Rake::Task['parallel:load_schema'].invoke
    else
      # there is no separate dump / load for s(args[:count])chema_format :sql -> do it safe and slow
      args = args.to_hash.merge(:non_parallel => true) # normal merge returns nil
      ParallelizedSpecs.execute_parallel_db('rake db:test:dump_load', args)
    end
  end

  desc "drop, create, migrate all in one --> parallel:prepare[num_cpus]"
  task :prepare, :count do |t, args|
    ParallelizedSpecs.execute_parallel_db('rake db:drop db:create db:migrate RAILS_ENV=test', args)
  end

# when dumping/resetting takes too long
  desc "update test databases via db:migrate --> parallel:migrate[num_cpus]"
  task :migrate, :count do |t, args|
    ParallelizedSpecs.execute_parallel_db('rake db:migrate RAILS_ENV=test', args)
  end

# just load the schema (good for integration server <-> no development db)
  desc "load dumped schema for test databases via db:schema:load --> parallel:load_schema[num_cpus]"
  task :load_schema, :count do |t, args|
    ParallelizedSpecs.execute_parallel_db('rake db:test:load', args)
  end

  desc "run spec in parallel with parallel:spec[num_cpus]"
  task 'spec', :count, :pattern, :options, :arguments do |t, args|
    count, pattern = ParallelizedSpecs.parse_rake_args(args)
    opts = {:count => count, :pattern => pattern, :root => Rails.root, :files => args[:arguments]}
    ParallelizedSpecs.execute_parallel_specs(opts)
  end
end
