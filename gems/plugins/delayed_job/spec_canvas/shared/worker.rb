shared_examples_for 'Delayed::Worker' do
  def job_create(opts = {})
    Delayed::Job.create({:payload_object => SimpleJob.new, :queue => Delayed::Worker.queue}.merge(opts))
  end
  def worker_create(opts = {})
    Delayed::Worker.new(opts.merge(:max_priority => nil, :min_priority => nil, :quiet => true))
  end

  before(:each) do
    @worker = worker_create
    SimpleJob.runs = 0
    Delayed::Worker.on_max_failures = nil
    Setting.set('delayed_jobs_sleep_delay', '0.01')
  end

  describe "running a job" do
    it "should not fail when running a job with a % in the name" do
      @job = User.send_later_enqueue_args(:name_parts, { no_delay: true }, "Some % Name")
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

        to_retry = Delayed::Job.list_jobs(:future, 100)
        to_retry.size.should eql 1
        to_retry[0].payload_object.method.should eql :/
        to_retry[0].last_error.should =~ /divided by 0/
        to_retry[0].attempts.should == 1
      end
  
      it "should retry a failed individual job" do
        batch = Delayed::Batch::PerformableBatch.new(:serial, [
          { :payload_object => Delayed::PerformableMethod.new(1, :/, [0]) },
        ])
        batch_job = Delayed::Job.create :payload_object => batch

        Delayed::Job.any_instance.expects(:reschedule).once
        Delayed::Stats.expects(:job_complete).times(1) # just the batch
        @worker.perform(batch_job).should == 1
      end
    end
  end

  context "worker prioritization" do
    before(:each) do
      @worker = Delayed::Worker.new(:max_priority => 5, :min_priority => 2, :quiet => true)
    end

    it "should only run jobs that are >= min_priority" do
      SimpleJob.runs.should == 0

      job_create(:priority => 1)
      job_create(:priority => 3)
      @worker.run

      SimpleJob.runs.should == 1
    end

    it "should only run jobs that are <= max_priority" do
      SimpleJob.runs.should == 0

      job_create(:priority => 10)
      job_create(:priority => 4)

      @worker.run

      SimpleJob.runs.should == 1
    end
  end

  context "while running with locked jobs" do
    before(:each) do
      @worker.name = 'worker1'
    end
    
    it "should not run jobs locked by another worker" do
      job_create(:locked_by => 'other_worker', :locked_at => (Delayed::Job.db_time_now - 1.minutes))
      lambda { @worker.run }.should_not change { SimpleJob.runs }
    end
    
    it "should run open jobs" do
      job_create
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
      @job.max_attempts = 1
      @job.save!
      (job = Delayed::Job.get_and_lock_next_available('w1')).should == @job
      @worker.perform(job)
      old_id = @job.id
      @job = Delayed::Job.list_jobs(:failed, 1).first
      @job.original_job_id.should == old_id
      @job.last_error.should =~ /did not work/
      @job.last_error.should =~ /shared\/worker.rb/
      @job.attempts.should == 1
      @job.failed_at.should_not be_nil
      @job.run_at.should > Delayed::Job.db_time_now - 10.minutes
      @job.run_at.should < Delayed::Job.db_time_now + 10.minutes
      # job stays locked after failing, for record keeping of time/worker
      @job.should be_locked

      Delayed::Job.find_available(100, @job.queue).should == []
    end
    
    it "should re-schedule jobs after failing" do
      @worker.perform(@job)
      @job = Delayed::Job.find(@job.id)
      @job.last_error.should =~ /did not work/
      @job.last_error.should =~ /sample_jobs.rb:8:in `perform'/
      @job.attempts.should == 1
      @job.run_at.should > Delayed::Job.db_time_now - 10.minutes
      @job.run_at.should < Delayed::Job.db_time_now + 10.minutes
    end

    it "should notify jobs on failure" do
      ErrorJob.failure_runs = 0
      @worker.perform(@job)
      ErrorJob.failure_runs.should == 1
    end

    it "should notify jobs on permanent failure" do
      (Delayed::Worker.max_attempts - 1).times { @job.reschedule }
      ErrorJob.permanent_failure_runs = 0
      @worker.perform(@job)
      ErrorJob.permanent_failure_runs.should == 1
    end
  end
  
  context "reschedule" do
    before do
      @job = Delayed::Job.create :payload_object => SimpleJob.new
    end
    
    context "and we want to destroy jobs" do
      it "should be destroyed if it failed more than Worker.max_attempts times" do
        @job.expects(:destroy)
        Delayed::Worker.max_attempts.times { @job.reschedule }
      end
      
      it "should not be destroyed if failed fewer than Worker.max_attempts times" do
        @job.expects(:destroy).never
        (Delayed::Worker.max_attempts - 1).times { @job.reschedule }
      end

      it "should be destroyed if failed more than Job#max_attempts times" do
        Delayed::Worker.max_attempts = 25
        @job.expects(:destroy)
        @job.max_attempts = 2
        @job.save!
        2.times { @job.reschedule }
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
        @job.failed_at.should == nil
        Delayed::Worker.max_attempts.times { @job.reschedule }
        Delayed::Job.list_jobs(:failed, 100).size.should == 1
      end

      it "should not be failed if it failed fewer than Worker.max_attempts times" do
        (Delayed::Worker.max_attempts - 1).times { @job.reschedule }
        @job = Delayed::Job.find(@job.id)
        @job.failed_at.should == nil
      end
      
    end

    context "and we give an on_max_failures callback" do
      it "should be failed max_attempts times and cb is false" do
        Delayed::Worker.on_max_failures = proc do |job, ex|
          job.should == @job
          false
        end
        @job.expects(:fail!)
        Delayed::Worker.max_attempts.times { @job.reschedule }
      end

      it "should be destroyed if it failed max_attempts times and cb is true" do
        Delayed::Worker.on_max_failures = proc do |job, ex|
          job.should == @job
          true
        end
        @job.expects(:destroy)
        Delayed::Worker.max_attempts.times { @job.reschedule }
      end
    end
  end


  context "Queue workers" do
    before :each do
      Delayed::Worker.queue = "Queue workers test"
      job_create(:queue => 'queue1')
      job_create(:queue => 'queue2')
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
  end
end
