shared_examples_for 'Delayed::Stats' do
if Canvas.redis_enabled?
  before do
    Setting.set('delayed_jobs_store_stats', 'redis')
  end

  it "should store stats for jobs" do
    "ohai".send_later(:reverse)
    job = Delayed::Job.get_and_lock_next_available('stub worker')
    expect(job).to be_present
    worker = mock('Delayed::Worker')
    worker.stubs(:name).returns("stub worker")
    Delayed::Stats.job_complete(job, worker)
    expect(Canvas.redis.hget("job_stats:id:#{job.id}", "worker")).to eq 'stub worker'
    expect(Canvas.redis.hget("job_stats:id:#{job.id}", "id")).to eq job.id.to_s
  end

  it "should completely clean up after stats" do
    "ohai".send_later(:reverse)
    job = Delayed::Job.get_and_lock_next_available('stub worker')
    expect(job).to be_present
    worker = mock('Delayed::Worker')
    worker.stubs(:name).returns("stub worker")

    expect(Canvas.redis.keys("job_stats:*")).to be_empty
    Delayed::Stats.job_complete(job, worker)
    expect(Canvas.redis.keys("job_stats:*")).not_to be_empty
    expect(Canvas.redis.type('job_stats:id')).to eq 'list'

    # delete the job, ensuring that there's nothing left after cleanup
    Canvas.redis.del("job_stats:id:#{job.id}")
    Delayed::Stats.cleanup
    # these 2 keys remain forever, they don't grow without bound
    expect(Canvas.redis.keys("job_stats:*").sort).to eq ['job_stats:tag', 'job_stats:tag:counts']
  end
end
end
