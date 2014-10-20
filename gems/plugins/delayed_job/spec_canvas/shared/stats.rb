shared_examples_for 'Delayed::Stats' do
if Canvas.redis_enabled?
  before do
    Setting.set('delayed_jobs_store_stats', 'redis')
  end

  it "should store stats for jobs" do
    "ohai".send_later(:reverse)
    job = Delayed::Job.get_and_lock_next_available('stub worker')
    job.should be_present
    worker = mock('Delayed::Worker')
    worker.stubs(:name).returns("stub worker")
    Delayed::Stats.job_complete(job, worker)
    Canvas.redis.hget("job_stats:id:#{job.id}", "worker").should == 'stub worker'
    Canvas.redis.hget("job_stats:id:#{job.id}", "id").should == job.id.to_s
  end

  it "should completely clean up after stats" do
    "ohai".send_later(:reverse)
    job = Delayed::Job.get_and_lock_next_available('stub worker')
    job.should be_present
    worker = mock('Delayed::Worker')
    worker.stubs(:name).returns("stub worker")

    Canvas.redis.keys("job_stats:*").should be_empty
    Delayed::Stats.job_complete(job, worker)
    Canvas.redis.keys("job_stats:*").should_not be_empty
    Canvas.redis.type('job_stats:id').should == 'list'

    # delete the job, ensuring that there's nothing left after cleanup
    Canvas.redis.del("job_stats:id:#{job.id}")
    Delayed::Stats.cleanup
    # these 2 keys remain forever, they don't grow without bound
    Canvas.redis.keys("job_stats:*").sort.should == ['job_stats:tag', 'job_stats:tag:counts']
  end
end
end
