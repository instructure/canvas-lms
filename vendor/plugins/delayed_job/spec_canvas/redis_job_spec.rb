require File.expand_path("../spec_helper", __FILE__)

if Canvas.redis_enabled?

describe 'Delayed::Backend::Redis::Job' do
  before :all do
    @job_spec_backend = Delayed::Job
    Delayed.send(:remove_const, :Job)
    Delayed::Job = Delayed::Backend::Redis::Job
    Delayed::Job.redis ||= Canvas.redis
  end

  after :all do
    Delayed.send(:remove_const, :Job)
    Delayed::Job = @job_spec_backend
  end

  before do
    Delayed::Job.redis.flushdb
  end

  include_examples 'a delayed_jobs implementation'

  describe "tickle_strand" do
    it "should continue trying to tickle until the strand is empty" do
      jobs = []
      3.times { jobs << "test".send_later_enqueue_args(:to_s, :strand => "s1", :no_delay => true) }
      job = "test".send_later_enqueue_args(:to_s, :strand => "s1", :no_delay => true)
      # manually delete the first jobs, bypassing the strand book-keeping
      jobs.each { |j| Delayed::Job.redis.del(Delayed::Job::Keys::JOB[j.id]) }
      Delayed::Job.redis.llen(Delayed::Job::Keys::STRAND['s1']).should == 4
      job.destroy
      Delayed::Job.redis.llen(Delayed::Job::Keys::STRAND['s1']).should == 0
    end

    it "should tickle until it finds an existing job" do
      jobs = []
      3.times { jobs << "test".send_later_enqueue_args(:to_s, :strand => "s1", :no_delay => true) }
      job = "test".send_later_enqueue_args(:to_s, :strand => "s1", :no_delay => true)
      # manually delete the first jobs, bypassing the strand book-keeping
      jobs[0...-1].each { |j| Delayed::Job.redis.del(Delayed::Job::Keys::JOB[j.id]) }
      Delayed::Job.redis.llen(Delayed::Job::Keys::STRAND['s1']).should == 4
      jobs[-1].destroy
      Delayed::Job.redis.lrange(Delayed::Job::Keys::STRAND['s1'], 0, -1).should == [job.id]
      Delayed::Job.get_and_lock_next_available('test worker').should == nil
      Delayed::Job.get_and_lock_next_available('test worker').should == job
    end
  end

  describe "missing jobs in queues" do
    before do
      @job = "test".send_later_enqueue_args(:to_s, :no_delay => true)
      @job2 = "test".send_later_enqueue_args(:to_s, :no_delay => true)
      # manually delete the job from redis
      Delayed::Job.redis.del(Delayed::Job::Keys::JOB[@job.id])
    end

    it "should discard when trying to lock" do
      Delayed::Job.get_and_lock_next_available("test worker").should be_nil
      Delayed::Job.get_and_lock_next_available("test worker").should == @job2
    end

    it "should filter for find_available" do
      Delayed::Job.find_available(1).should == []
      Delayed::Job.find_available(1).should == [@job2]
    end
  end

  describe "send_later" do
    it "should schedule job on transaction commit" do
      Rails.env.stubs(:test?).returns(false)
      before_count = Delayed::Job.jobs_count(:current)
      job = "string".send_later :reverse
      job.should be_nil
      Delayed::Job.jobs_count(:current).should == before_count
      Delayed::Job.connection.run_transaction_commit_callbacks
      Delayed::Job.jobs_count(:current) == before_count + 1
    end
  end
end

end
