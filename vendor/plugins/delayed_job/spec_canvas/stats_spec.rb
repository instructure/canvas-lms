if Canvas.redis_enabled?
shared_examples_for 'Delayed::Stats' do
  before do
    Setting.set('delayed_jobs_store_stats', 'redis')
  end

  it "should store stats for jobs" do
    job = "ohai".send_later(:reverse)
    job.lock_exclusively!('stub worker').should be_true
    worker = mock('Delayed::Worker')
    worker.stubs(:name).returns("stub worker")
    Delayed::Stats.job_complete(job, worker)
    Canvas.redis.hget("job:id:#{job.id}", "worker").should == 'stub worker'
    Canvas.redis.hget("job:id:#{job.id}", "id").should == job.id.to_s
  end

  it "should completely clean up after stats" do
    job = "ohai".send_later(:reverse)
    job.lock_exclusively!('stub worker').should be_true
    worker = mock('Delayed::Worker')
    worker.stubs(:name).returns("stub worker")

    Canvas.redis.keys("job:*").should be_empty
    Delayed::Stats.job_complete(job, worker)
    Canvas.redis.keys("job:*").should_not be_empty
    Canvas.redis.type('job:id').should == 'list'

    # delete the job, ensuring that there's nothing left after cleanup
    Canvas.redis.del("job:id:#{job.id}")
    Delayed::Stats.cleanup
    # these 2 keys remain forever, they don't grow without bound
    Canvas.redis.keys("job:*").sort.should == ['job:tag', 'job:tag:counts']
  end
end
end
