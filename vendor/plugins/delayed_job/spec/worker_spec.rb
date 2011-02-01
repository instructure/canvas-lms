require 'spec_helper'

describe Delayed::Worker do
  def job_create(opts = {})
    Delayed::Job.create(opts.merge(:payload_object => SimpleJob.new))
  end
  def worker_create(opts = {})
    Delayed::Worker.new(opts.merge(:max_priority => nil, :min_priority => nil, :quiet => true))
  end

  before(:each) do
    # Make sure backend is set to active record
    Delayed::Worker.backend = :active_record
    
    @worker = worker_create

    Delayed::Job.delete_all
    
    SimpleJob.runs = 0
  end
  
  describe "backend=" do
    it "should set the Delayed::Job constant to the backend" do
      @clazz = Class.new
      Delayed::Worker.backend = @clazz
      Delayed::Job.should == @clazz
    end
    
    it "should set backend with a symbol" do
      Delayed::Worker.backend = Class.new
      Delayed::Worker.backend = :active_record
      Delayed::Worker.backend.should == Delayed::Backend::ActiveRecord::Job
    end
  end
  
  describe "running a job" do
    it "should fail after Worker.max_run_time" do
      begin
        old_max_run_time = Delayed::Worker.max_run_time
        Delayed::Worker.max_run_time = 1.second
        @job = Delayed::Job.create :payload_object => LongRunningJob.new
        @worker.run(@job)
        @job.reload.last_error.should =~ /expired/
        @job.attempts.should == 1
      ensure
        Delayed::Worker.max_run_time = old_max_run_time
      end
    end
  end
  
  context "worker prioritization" do
    before(:each) do
      @worker = Delayed::Worker.new(:max_priority => 5, :min_priority => -5, :quiet => true)
    end

    it "should only run jobs that are >= min_priority" do
      SimpleJob.runs.should == 0

      job_create(:priority => -10)
      job_create(:priority => 0)
      @worker.start(true)

      SimpleJob.runs.should == 1
    end

    it "should only run jobs that are <= max_priority" do
      SimpleJob.runs.should == 0

      job_create(:priority => 10)
      job_create(:priority => 0)

      @worker.start(true)

      SimpleJob.runs.should == 1
    end
  end

  context "while running with locked and expired jobs" do
    before(:each) do
      @worker.name = 'worker1'
    end
    
    it "should not run jobs locked by another worker" do
      job_create(:locked_by => 'other_worker', :locked_at => (Delayed::Job.db_time_now - 1.minutes))
      lambda { @worker.start(true) }.should_not change { SimpleJob.runs }
    end
    
    it "should run open jobs" do
      job_create
      lambda { @worker.start(true) }.should change { SimpleJob.runs }.from(0).to(1)
    end
    
    it "should run expired jobs" do
      expired_time = Delayed::Job.db_time_now - (1.minutes + Delayed::Worker.max_run_time)
      job_create(:locked_by => 'other_worker', :locked_at => expired_time)
      lambda { @worker.start(true) }.should change { SimpleJob.runs }.from(0).to(1)
    end
    
    it "should run own jobs" do
      job_create(:locked_by => @worker.name, :locked_at => (Delayed::Job.db_time_now - 1.minutes))
      lambda { @worker.start(true) }.should change { SimpleJob.runs }.from(0).to(1)
    end
  end
  
  describe "failed jobs" do
    before do
      # reset defaults
      Delayed::Worker.destroy_failed_jobs = true
      Delayed::Worker.max_attempts = 25

      @job = Delayed::Job.enqueue ErrorJob.new
    end

    it "should record last_error when destroy_failed_jobs = false, max_attempts = 1" do
      Delayed::Worker.destroy_failed_jobs = false
      Delayed::Worker.max_attempts = 1
      @job.lock_exclusively!(Delayed::Worker.max_run_time, @worker.name).should == true
      @worker.run(@job)
      @job.reload
      @job.last_error.should =~ /did not work/
      @job.last_error.should =~ /worker_spec.rb/
      @job.attempts.should == 1
      @job.failed_at.should_not be_nil
      @job.run_at.should > Delayed::Job.db_time_now - 10.minutes
      @job.run_at.should < Delayed::Job.db_time_now + 10.minutes
      @job.should_not be_locked

      all_jobs = Delayed::Job.all_available(@worker.name,
                                 Delayed::Worker.max_run_time,
                                 @job.queue)
      all_jobs.find_by_id(@job.id).should be_nil
    end
    
    it "should re-schedule jobs after failing" do
      @worker.run(@job)
      @job.reload
      @job.last_error.should =~ /did not work/
      @job.last_error.should =~ /sample_jobs.rb:8:in `perform'/
      @job.attempts.should == 1
      @job.run_at.should > Delayed::Job.db_time_now - 10.minutes
      @job.run_at.should < Delayed::Job.db_time_now + 10.minutes
    end
  end
  
  context "reschedule" do
    before do
      @job = Delayed::Job.create :payload_object => SimpleJob.new
    end
    
    context "and we want to destroy jobs" do
      before do
        Delayed::Worker.destroy_failed_jobs = true
      end
      
      it "should be destroyed if it failed more than Worker.max_attempts times" do
        @job.should_receive(:destroy)
        Delayed::Worker.max_attempts.times { @worker.reschedule(@job) }
      end
      
      it "should not be destroyed if failed fewer than Worker.max_attempts times" do
        @job.should_not_receive(:destroy)
        (Delayed::Worker.max_attempts - 1).times { @worker.reschedule(@job) }
      end
    end
    
    context "and we don't want to destroy jobs" do
      before do
        Delayed::Worker.destroy_failed_jobs = false
      end
      
      it "should be failed if it failed more than Worker.max_attempts times" do
        @job.reload.failed_at.should == nil
        Delayed::Worker.max_attempts.times { @worker.reschedule(@job) }
        @job.reload.failed_at.should_not == nil
      end

      it "should not be failed if it failed fewer than Worker.max_attempts times" do
        (Delayed::Worker.max_attempts - 1).times { @worker.reschedule(@job) }
        @job.reload.failed_at.should == nil
      end
      
    end

    context "and we give an on_max_failures callback" do
      it "should not be destroyed if it failed max_attempts times and cb is false" do
        Delayed::Worker.destroy_failed_jobs = true
        Delayed::Worker.on_max_failures = proc do |job, ex|
          job.should == @job
          false
        end
        @job.should_not_receive(:destroy)
        Delayed::Worker.max_attempts.times { @worker.reschedule(@job) }
      end

      it "should be destroyed if it failed max_attempts times and cb is true" do
        Delayed::Worker.destroy_failed_jobs = true
        Delayed::Worker.on_max_failures = proc do |job, ex|
          job.should == @job
          true
        end
        @job.should_receive(:destroy)
        Delayed::Worker.max_attempts.times { @worker.reschedule(@job) }
      end
    end
  end


  context "Queue workers" do
    before :each do
      Delayed::Worker.queue = nil
      job_create(:queue => 'queue1')
      job_create(:queue => 'queue2')
      job_create(:queue => nil)
    end

    it "should only work off jobs assigned to themselves" do
      worker = worker_create(:queue=>'queue1')
      SimpleJob.runs.should == 0
      worker.start(true)
      SimpleJob.runs.should == 1
      
      SimpleJob.runs = 0

      worker = worker_create(:queue=>'queue2')
      SimpleJob.runs.should == 0
      worker.start(true)
      SimpleJob.runs.should == 1
    end

    it "should not work off jobs not assigned to themselves" do
      worker = worker_create(:queue=>'queue3')

      SimpleJob.runs.should == 0
      worker.start(true)
      SimpleJob.runs.should == 0
    end

    it "should run non-named queue jobs when the queue has no name set" do
      worker = worker_create(:queue=>nil)
      SimpleJob.runs.should == 0
      worker.start(true)
      SimpleJob.runs.should == 1
    end
    
    it "should get the default queue if none is set" do
      queue_name = "default_queue"
      Delayed::Worker.queue = queue_name
      worker = worker_create(:queue=>nil)
      worker.queue.should == queue_name
    end
    
    it "should override default queue name if specified in initialize" do
      queue_name = "my_queue"
      Delayed::Worker.queue = "default_queue"
      worker = worker_create(:queue=>queue_name)
      worker.queue.should == queue_name
    end
    
    it "shouldn't have a queue if none is set" do
      worker = worker_create(:queue=>nil)
      worker.queue.should == nil
    end
  end
end
