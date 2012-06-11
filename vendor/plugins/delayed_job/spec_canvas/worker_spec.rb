shared_examples_for 'Delayed::Worker' do
  def job_create(opts = {})
    Delayed::Job.create({:payload_object => SimpleJob.new, :queue => Delayed::Worker.queue}.merge(opts))
  end
  def worker_create(opts = {})
    Delayed::Worker.new(opts.merge(:max_priority => nil, :min_priority => nil, :quiet => true))
  end
  def adjust_max_run_time(new_time)
    old_max_run_time = Delayed::Worker.max_run_time
    Delayed::Worker.max_run_time = new_time
    yield
  ensure
    Delayed::Worker.max_run_time = old_max_run_time
  end

  before(:each) do
    @worker = worker_create
    Delayed::Job.delete_all
    Delayed::Job::Failed.delete_all
    SimpleJob.runs = 0
    Delayed::Worker.on_max_failures = nil
    Setting.set('delayed_jobs_sleep_delay', '0.01')
  end

  describe "running a job" do
    it "should fail after Worker.max_run_time" do
      adjust_max_run_time 0.01 do
        @job = Delayed::Job.create :payload_object => LongRunningJob.new
        @worker.perform(@job)
        @job.reload.last_error.should =~ /expired/
        @job.attempts.should == 1
      end
    end

    it "should not fail when running a job with a % in the name" do
      User.send_later(:name_parts, "Some % Name")
      @job = Delayed::Job.last
      @worker.perform(@job)
    end
  end

  describe "running a batch" do
    context "serially" do
      it "should run each job in order" do
        bar = "bar"
        seq = sequence("bar")
        bar.expects(:scan).with("b").in_sequence(seq)
        bar.expects(:scan).with("a").in_sequence(seq)
        bar.expects(:scan).with("r").in_sequence(seq)
        batch = Delayed::Batch::PerformableBatch.new(:serial, [
          { :payload_object => Delayed::PerformableMethod.new(bar, :scan, ["b"]) },
          { :payload_object => Delayed::PerformableMethod.new(bar, :scan, ["a"]) },
          { :payload_object => Delayed::PerformableMethod.new(bar, :scan, ["r"]) },
        ])

        batch_job = Delayed::Job.create :payload_object => batch 
        Delayed::Stats.expects(:job_complete).times(4) # batch, plus all jobs
        @worker.perform(batch_job).should == 3
      end
    
      it "should succeed regardless of the success/failure of its component jobs" do
        batch = Delayed::Batch::PerformableBatch.new(:serial, [
          { :payload_object => Delayed::PerformableMethod.new("foo", :reverse, []) },
          { :payload_object => Delayed::PerformableMethod.new(1, :/, [0]) },
          { :payload_object => Delayed::PerformableMethod.new("bar", :scan, ["r"]) },
        ])
        batch_job = Delayed::Job.create :payload_object => batch

        Delayed::Stats.expects(:job_complete).times(3) # batch, plus two successful jobs
        @worker.perform(batch_job).should == 3

        failed_jobs = Delayed::Job.all
        failed_jobs.size.should eql 1
        failed_jobs[0].payload_object.method.should eql :/
        failed_jobs[0].last_error.should =~ /divided by 0/
        failed_jobs[0].attempts.should == 1
      end

      it "should fail an individual job after Worker.max_run_time, but not the batch itself" do
        adjust_max_run_time 0.01 do
          foo = "foo"
          foo.expects(:reverse).once
          bar = "bar"
          bar.expects(:scan).once
  
          batch = Delayed::Batch::PerformableBatch.new(:serial, [
            { :payload_object => Delayed::PerformableMethod.new(foo, :reverse, []) },
            { :payload_object => Delayed::PerformableMethod.new(Kernel, :sleep, [250]) },
            { :payload_object => Delayed::PerformableMethod.new(bar, :scan, ["r"]) },
          ])
          batch_job = Delayed::Job.create :payload_object => batch
          
          Delayed::Stats.expects(:job_complete).times(3) # batch, plus two successful jobs
          @worker.perform(batch_job).should == 3
  
          failed_jobs = Delayed::Job.all
          failed_jobs.size.should eql 1
          failed_jobs[0].last_error.should =~ /expired/
          failed_jobs[0].attempts.should == 1
        end
      end
  
      it "should retry a failed individual job" do
        batch = Delayed::Batch::PerformableBatch.new(:serial, [
          { :payload_object => Delayed::PerformableMethod.new(1, :/, [0]) },
        ])
        batch_job = Delayed::Job.create :payload_object => batch

        @worker.expects(:reschedule).once
        Delayed::Stats.expects(:job_complete).times(1) # just the batch
        @worker.perform(batch_job).should == 1
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
      @worker.run

      SimpleJob.runs.should == 1
    end

    it "should only run jobs that are <= max_priority" do
      SimpleJob.runs.should == 0

      job_create(:priority => 10)
      job_create(:priority => 0)

      @worker.run

      SimpleJob.runs.should == 1
    end
  end

  context "while running with locked and expired jobs" do
    before(:each) do
      @worker.name = 'worker1'
    end
    
    it "should not run jobs locked by another worker" do
      job_create(:locked_by => 'other_worker', :locked_at => (Delayed::Job.db_time_now - 1.minutes))
      lambda { @worker.run }.should_not change { SimpleJob.runs }
      Delayed::Job.unlock_expired_jobs
      lambda { @worker.run }.should_not change { SimpleJob.runs }
    end
    
    it "should run open jobs" do
      job_create
      lambda { @worker.run }.should change { SimpleJob.runs }.from(0).to(1)
    end
    
    it "should run expired jobs" do
      expired_time = Delayed::Job.db_time_now - (1.minutes + Delayed::Worker.max_run_time)
      job_create(:locked_by => 'other_worker', :locked_at => expired_time)
      Delayed::Job.unlock_expired_jobs
      lambda { @worker.run }.should change { SimpleJob.runs }.from(0).to(1)
    end
  end
  
  describe "failed jobs" do
    before do
      # reset defaults
      Delayed::Worker.max_attempts = 25
      @job = Delayed::Job.enqueue ErrorJob.new
    end

    it "should record last_error when destroy_failed_jobs = false, max_attempts = 1" do
      Delayed::Worker.on_max_failures = proc { false }
      @job.update_attribute(:max_attempts, 1)
      @job.lock_exclusively!(@worker.name).should == true
      @worker.perform(@job)
      old_id = @job.id
      @job = Delayed::Job::Failed.first
      @job.original_id.should == old_id
      @job.last_error.should =~ /did not work/
      @job.last_error.should =~ /worker_spec.rb/
      @job.attempts.should == 1
      @job.failed_at.should_not be_nil
      @job.run_at.should > Delayed::Job.db_time_now - 10.minutes
      @job.run_at.should < Delayed::Job.db_time_now + 10.minutes
      # job stays locked after failing, for record keeping of time/worker
      @job.should be_locked

      all_jobs = Delayed::Job.all_available(@job.queue)
      all_jobs.find_by_id(@job.id).should be_nil
    end
    
    it "should re-schedule jobs after failing" do
      @worker.perform(@job)
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
      it "should be destroyed if it failed more than Worker.max_attempts times" do
        @job.expects(:destroy)
        Delayed::Worker.max_attempts.times { @worker.reschedule(@job) }
      end
      
      it "should not be destroyed if failed fewer than Worker.max_attempts times" do
        @job.expects(:destroy).never
        (Delayed::Worker.max_attempts - 1).times { @worker.reschedule(@job) }
      end

      it "should be destroyed if failed more than Job#max_attempts times" do
        Delayed::Worker.max_attempts = 25
        @job.expects(:destroy)
        @job.update_attribute(:max_attempts, 2)
        2.times { @worker.reschedule(@job) }
      end
    end
    
    context "and we don't want to destroy jobs" do
      before do
        Delayed::Worker.on_max_failures = proc { false }
      end

      after do
        Delayed::Worker.on_max_failures = nil
      end

      it "should be failed if it failed more than Worker.max_attempts times" do
        @job.reload.failed_at.should == nil
        Delayed::Worker.max_attempts.times { @worker.reschedule(@job) }
        Delayed::Job::Failed.count.should == 1
      end

      it "should not be failed if it failed fewer than Worker.max_attempts times" do
        (Delayed::Worker.max_attempts - 1).times { @worker.reschedule(@job) }
        @job.reload.failed_at.should == nil
      end
      
    end

    context "and we give an on_max_failures callback" do
      it "should be failed max_attempts times and cb is false" do
        Delayed::Worker.on_max_failures = proc do |job, ex|
          job.should == @job
          false
        end
        @job.expects(:fail!)
        Delayed::Worker.max_attempts.times { @worker.reschedule(@job) }
      end

      it "should be destroyed if it failed max_attempts times and cb is true" do
        Delayed::Worker.on_max_failures = proc do |job, ex|
          job.should == @job
          true
        end
        @job.expects(:destroy)
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
      worker.run
      SimpleJob.runs.should == 1
      
      SimpleJob.runs = 0

      worker = worker_create(:queue=>'queue2')
      SimpleJob.runs.should == 0
      worker.run
      SimpleJob.runs.should == 1
    end

    it "should not work off jobs not assigned to themselves" do
      worker = worker_create(:queue=>'queue3')

      SimpleJob.runs.should == 0
      worker.run
      SimpleJob.runs.should == 0
    end

    it "should run non-named queue jobs when the queue has no name set" do
      worker = worker_create(:queue=>nil)
      SimpleJob.runs.should == 0
      worker.run
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
