module Delayed
module Stats

  # store information about completed jobs in redis, if enabled
  # this is mostly just a data dump for now, there's no UI for consuming the data yet.
  # but as an example, here's a query to list the ids, runtimes and full commands of the
  # 20 longest-running jobs:
  #   Canvas.redis.sort 'job:id', :by => 'job:id:*->run_time', :get => ['#', 'job:id:*->run_time', 'job:id:*->full_command'], :limit => [0,20], :order => 'desc'
  def self.job_complete(job, worker)
    return unless enabled?
    redis = Canvas.redis
    # simple list of job ids... you can get this from redis directly with
    #   redis.keys("job:id:*")
    # but that requires walking the entire keyspace
    # (this is an index sorted by completion time)
    redis.lpush("job_stats:id", job.id)
    # set of tags ever seen
    # sorted set, but all weights are 0 so that we get a sorted-by-name set
    redis.zadd('job_stats:tag', 0, job.tag)
    # second sorted set, with weights as number of jobs of that type completed
    redis.zincrby("job_stats:tag:counts", 1, job.tag)
    # job details, stored in a redis hash
    data = job.attributes
    data['finished_at'] = job.class.db_time_now
    data['worker'] = worker.name
    data['full_command'] = job.full_name
    data['run_time'] = data['finished_at'] - data['locked_at']
    redis.hmset("job_stats:id:#{job.id}", *data.to_a.flatten)
    ttl = Setting.get('delayed_jobs_stats_ttl', 1.month.to_s).to_i.from_now
    redis.expireat("job_stats:id:#{job.id}", ttl.to_i)
  rescue
    Rails.logger.warn "Failed saving job stats: #{$!.inspect}"
  end

  def self.enabled?
    Setting.get('delayed_jobs_store_stats', 'false') == 'redis'
  end

  # remove deleted/expired keys from indexes
  def self.cleanup
    return unless enabled?
    redis = Canvas.redis
    # sort job:id, looking up the id in the individual job hash, and storing
    # back to the same key. the end result is that any job that's expired will
    # get its id in this list reset to the empty string
    redis.sort 'job_stats:id', :by => 'nosort', :get => 'job_stats:id:*->id', :store => 'job_stats:id'
    # now, remove all elements that match the empty string
    redis.lrem 'job_stats:id', 0, ''
    # we don't remove anything from job:tag or job:tag:counts -- we don't have
    # enough information stored to do so. in theory those sets could grow
    # without bound, which would be an issue, but really they are limited in
    # size to the number of unique job tags that canvas has.
  end

end
end
