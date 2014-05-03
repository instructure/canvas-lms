require File.expand_path("../spec_helper", __FILE__)

describe 'Delayed::Backed::ActiveRecord::Job' do
  before :all do
    @job_spec_backend = Delayed::Job
    Delayed.send(:remove_const, :Job)
    Delayed::Job = Delayed::Backend::ActiveRecord::Job
  end

  after :all do
    Delayed.send(:remove_const, :Job)
    Delayed::Job = @job_spec_backend
  end

  before do
    Delayed::Job.delete_all
    Delayed::Job::Failed.delete_all
  end

  include_examples 'a delayed_jobs implementation'

  it "should recover as well as possible from a failure failing a job" do
    Delayed::Job::Failed.stubs(:create).raises(RuntimeError)
    job = "test".send_later_enqueue_args :reverse, no_delay: true
    job_id = job.id
    proc { job.fail! }.should raise_error
    proc { Delayed::Job.find(job_id) }.should raise_error(ActiveRecord::RecordNotFound)
    Delayed::Job.count.should == 0
  end

  context "when another worker has worked on a task since the job was found to be available, it" do
    before :each do
      @job = Delayed::Job.create :payload_object => SimpleJob.new
      @job_copy_for_worker_2 = Delayed::Job.find(@job.id)
    end

    it "should not allow a second worker to get exclusive access if already successfully processed by worker1" do
      @job.destroy
      @job_copy_for_worker_2.lock_exclusively!('worker2').should == false
    end

    it "should not allow a second worker to get exclusive access if failed to be processed by worker1 and run_at time is now in future (due to backing off behaviour)" do
      @job.update_attributes(:attempts => 1, :run_at => 1.day.from_now)
      @job_copy_for_worker_2.lock_exclusively!('worker2').should == false
    end

    it "should select the next job at random if enabled" do
      begin
        Delayed::Job.select_random = true
        15.times { "test".send_later :length }
        founds = []
        15.times do
          job = Delayed::Job.get_and_lock_next_available('tester')
          founds << job
          job.unlock
          job.save!
        end
        founds.uniq.size.should > 1
      ensure
        Delayed::Job.select_random = false
      end
    end
  end
end
