# Re-definitions are appended to existing tasks
task :environment
task :merb_env

namespace :jobs do
  desc "Clear the delayed_job queue. You can specify a queue with this: rake jobs:clear[queue_name] If no queue is specified, all jobs from all queues will be cleared."
  task :clear, [:queue] => [:merb_env, :environment] do |t, args|
    if args.queue
      Delayed::Job.delete_all :queue => args.queue
    else
      Delayed::Job.delete_all
    end
  end

  desc "Start a delayed_job worker. You can specify which queue to process from, for example: rake jobs:work[my_queue], or: QUEUE=my_queue rake jobs:work"
  task :work, [:queue] => [:merb_env, :environment] do |t,args|
    queue = args.queue || ENV['QUEUE']
    Delayed::Worker.new(:min_priority => ENV['MIN_PRIORITY'], :max_priority => ENV['MAX_PRIORITY'], :queue => queue).start
  end
end
