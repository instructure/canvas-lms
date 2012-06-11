shared_examples_for 'a backend' do
  def create_job(opts = {})
    @backend.create(opts.merge(:payload_object => SimpleJob.new))
  end

  before do
    SimpleJob.runs = 0
  end
  
  it "should set run_at automatically if not set" do
    @backend.create(:payload_object => ErrorJob.new ).run_at.should_not be_nil
  end

  it "should not set run_at automatically if already set" do
    later = @backend.db_time_now + 5.minutes
    @backend.create(:payload_object => ErrorJob.new, :run_at => later).run_at.should be_close(later, 1)
  end

  it "should raise ArgumentError when handler doesn't respond_to :perform" do
    lambda { @backend.enqueue(Object.new) }.should raise_error(ArgumentError)
  end

  it "should increase count after enqueuing items" do
    @backend.enqueue SimpleJob.new
    @backend.count.should == 1
  end
  
  it "should be able to set priority when enqueuing items" do
    @job = @backend.enqueue SimpleJob.new, :priority => 5
    @job.priority.should == 5
  end

  it "should use the default priority when enqueuing items" do
    @backend.default_priority = 0
    @job = @backend.enqueue SimpleJob.new
    @job.priority.should == 0
    @backend.default_priority = 10
    @job = @backend.enqueue SimpleJob.new
    @job.priority.should == 10
    @backend.default_priority = 0
  end

  it "should be able to set run_at when enqueuing items" do
    later = @backend.db_time_now + 5.minutes
    @job = @backend.enqueue SimpleJob.new, :priority => 5, :run_at => later
    @job.run_at.should be_close(later, 1)
  end

  it "should work with jobs in modules" do
    M::ModuleJob.runs = 0
    job = @backend.enqueue M::ModuleJob.new
    lambda { job.invoke_job }.should change { M::ModuleJob.runs }.from(0).to(1)
  end
                   
  it "should raise an DeserializationError when the job class is totally unknown" do
    job = @backend.new :handler => "--- !ruby/object:JobThatDoesNotExist {}"
    lambda { job.payload_object.perform }.should raise_error(Delayed::Backend::DeserializationError)
  end

  it "should try to load the class when it is unknown at the time of the deserialization" do
    job = @backend.new :handler => "--- !ruby/object:JobThatDoesNotExist {}"
    lambda { job.payload_object.perform }.should raise_error(Delayed::Backend::DeserializationError)
  end

  it "should try include the namespace when loading unknown objects" do
    job = @backend.new :handler => "--- !ruby/object:Delayed::JobThatDoesNotExist {}"
    lambda { job.payload_object.perform }.should raise_error(Delayed::Backend::DeserializationError)
  end

  it "should also try to load structs when they are unknown (raises TypeError)" do
    job = @backend.new :handler => "--- !ruby/struct:JobThatDoesNotExist {}"
    lambda { job.payload_object.perform }.should raise_error(Delayed::Backend::DeserializationError)
  end

  it "should try include the namespace when loading unknown structs" do
    job = @backend.new :handler => "--- !ruby/struct:Delayed::JobThatDoesNotExist {}"
    lambda { job.payload_object.perform }.should raise_error(Delayed::Backend::DeserializationError)
  end
  
  describe "find_available" do
    it "should not find failed jobs" do
      @job = create_job :attempts => 50
      @job.fail!
      @backend.find_available('worker', 5, 1.second).should_not include(@job)
    end
    
    it "should not find jobs scheduled for the future" do
      @job = create_job :run_at => (@backend.db_time_now + 1.minute)
      @backend.find_available('worker', 5, 4.hours).should_not include(@job)
    end
    
    it "should not find jobs locked by another worker" do
      @job = create_job(:locked_by => 'other_worker', :locked_at => @backend.db_time_now - 1.minute)
      @backend.find_available('worker', 5, 4.hours).should_not include(@job)
    end
    
    it "should find open jobs" do
      @job = create_job
      @backend.find_available('worker', 5, 4.hours).should include(@job)
    end
    
    it "should find expired jobs" do
      @job = create_job(:locked_by => 'worker', :locked_at => @backend.db_time_now - 2.minutes)
      Delayed::Job.unlock_expired_jobs(1.minute)
      @backend.find_available('worker', 5, 1.minute).should include(@job)
    end
  end
  
  context "when another worker is already performing an task, it" do

    before :each do
      @job = @backend.create :payload_object => SimpleJob.new, :locked_by => 'worker1', :locked_at => @backend.db_time_now - 5.minutes
    end

    it "should not allow a second worker to get exclusive access" do
      @job.lock_exclusively!(4.hours, 'worker2').should == false
    end

    it "should allow a second worker to get exclusive access if the timeout has passed" do
      Delayed::Job.unlock_expired_jobs(1.minute)
      @job.lock_exclusively!(1.minute, 'worker2').should == true
    end

    it "should be able to get access to the task if it was started more then max_age ago" do
      @job.locked_at = 5.hours.ago
      @job.save

      Delayed::Job.unlock_expired_jobs(4.hours)
      @job.lock_exclusively! 4.hours, 'worker2'
      @job.reload
      @job.locked_by.should == 'worker2'
      @job.locked_at.should > 1.minute.ago
    end

    it "should not be found by another worker" do
      @backend.find_available('worker2', 1, 6.minutes).length.should == 0
    end

    it "should be found by another worker if the time has expired" do
      Delayed::Job.unlock_expired_jobs(4.minutes)
      @backend.find_available('worker2', 1, 4.minutes).length.should == 1
    end
  end
  
  context "when another worker has worked on a task since the job was found to be available, it" do

    before :each do
      @job = @backend.create :payload_object => SimpleJob.new
      @job_copy_for_worker_2 = @backend.find(@job.id)
    end

    it "should not allow a second worker to get exclusive access if already successfully processed by worker1" do
      @job.destroy
      @job_copy_for_worker_2.lock_exclusively!(4.hours, 'worker2').should == false
    end

    it "should not allow a second worker to get exclusive access if failed to be processed by worker1 and run_at time is now in future (due to backing off behaviour)" do
      @job.update_attributes(:attempts => 1, :run_at => 1.day.from_now)
      @job_copy_for_worker_2.lock_exclusively!(4.hours, 'worker2').should == false
    end
  end

  context "#name" do
    it "should be the class name of the job that was enqueued" do
      @backend.create(:payload_object => ErrorJob.new ).name.should == 'ErrorJob'
    end

    it "should be the method that will be called if its a performable method object" do
      @job = Story.send_later(:create)
      @job.name.should == "Story.create"
    end

    it "should be the instance method that will be called if its a performable method object" do
      @job = Story.create(:text => "...").send_later(:save)
      @job.name.should == 'Story#save'
    end
  end
  
  context "worker prioritization" do
    it "should fetch jobs ordered by priority" do
      10.times { create_job :priority => rand(10) }
      jobs = @backend.find_available('worker', 10, 10)
      jobs.size.should == 10
      jobs.each_cons(2) do |a, b| 
        a.priority.should <= b.priority
      end
    end
  end
  
  context "clear_locks!" do
    before do
      @job = create_job(:locked_by => 'worker', :locked_at => @backend.db_time_now)
    end
    
    it "should clear locks for the given worker" do
      @backend.clear_locks!('worker')
      @backend.find_available('worker2', 5, 1.minute).should include(@job)
    end
    
    it "should not clear locks for other workers" do
      @backend.clear_locks!('worker1')
      @backend.find_available('worker1', 5, 1.minute).should_not include(@job)
    end
  end
  
  context "unlock" do
    before do
      @job = create_job(:locked_by => 'worker', :locked_at => @backend.db_time_now)
    end

    it "should clear locks" do
      @job.unlock
      @job.locked_by.should be_nil
      @job.locked_at.should be_nil
    end
  end

  context "strands" do
    it "should run strand jobs in strict order" do
      job1 = create_job(:strand => 'myjobs')
      job2 = create_job(:strand => 'myjobs')
      @backend.get_and_lock_next_available('w1', 60).should == job1
      @backend.get_and_lock_next_available('w2', 60).should == nil
      job1.destroy
      # update time since the failed lock pushed it forward
      job2.update_attribute(:run_at, 1.minute.ago)
      @backend.get_and_lock_next_available('w3', 60).should == job2
      @backend.get_and_lock_next_available('w4', 60).should == nil
    end

    it "should fail to lock if an earlier job gets locked" do
      job1 = create_job(:strand => 'myjobs')
      job2 = create_job(:strand => 'myjobs')
      @backend.find_available('w1', 2, 60).should == [job1]
      @backend.find_available('w2', 2, 60).should == [job1]

      # job1 gets locked by w1
      job1.lock_exclusively!(60, 'w1').should == true

      # w2 tries to lock job1, fails
      job1.lock_exclusively!(60, 'w2').should == false
      # normally w2 would now be able to lock job2, but strands prevent it
      @backend.get_and_lock_next_available('w2', 60).should be_nil

      # now job1 is done
      job1.destroy
      # update time since the failed lock pushed it forward
      job2.update_attribute(:run_at, 1.minute.ago)
      job2.lock_exclusively!(60, 'w2').should == true
    end

    it "should keep strand jobs in order as they are rescheduled" do
      job1 = create_job(:strand => 'myjobs')
      job2 = create_job(:strand => 'myjobs')
      job3 = create_job(:strand => 'myjobs')
      @backend.get_and_lock_next_available('w1', 60).should == job1
      @backend.find_available('w2', 1, 60).should == []
      job1.destroy
      # move job2's time forward
      job2.update_attribute(:run_at, 1.second.ago)
      job3.update_attribute(:run_at, 5.seconds.ago)
      # we should still get job2, not job3
      @backend.get_and_lock_next_available('w1', 60).should == job2
    end

    it "should allow to run the next job if a failed job is present" do
      job1 = create_job(:strand => 'myjobs')
      job2 = create_job(:strand => 'myjobs')
      job1.fail!
      @backend.find_available('w1', 2, 60).should == [job2]
      job2.lock_exclusively!(60, 'w1').should == true
    end

    it "should not interfere with jobs with no strand" do
      job1 = create_job(:strand => nil)
      job2 = create_job(:strand => 'myjobs')
      @backend.get_and_lock_next_available('w1', 60).should == job1
      @backend.get_and_lock_next_available('w2', 60).should == job2
      @backend.get_and_lock_next_available('w3', 60).should == nil
    end

    it "should not interfere with jobs in other strands" do
      job1 = create_job(:strand => 'strand1')
      job2 = create_job(:strand => 'strand2')
      @backend.get_and_lock_next_available('w1', 60).should == job1
      @backend.get_and_lock_next_available('w2', 60).should == job2
      @backend.get_and_lock_next_available('w3', 60).should == nil
    end

    context 'clear' do
      it "should clear all jobs" do
        create_job(:strand => 'myjobs')
        @backend.clear_strand!('myjobs')
        @backend.get_and_lock_next_available('w1', 60).should be_nil
      end

      it "should not clear running jobs" do
        job1 = create_job(:strand => 'myjobs')
        @backend.get_and_lock_next_available('w1', 60).should == job1
        @backend.clear_strand!('myjobs')
        job2 = create_job(:strand => 'myjobs')
        # returns nil, because job1 is still running and job2 shouldn't
        # start yet
        @backend.get_and_lock_next_available('w1', 60).should be_nil
      end
    end

    context 'n_strand' do
      it "should default to 1" do
        Delayed::Job.expects(:rand).never
        job = Delayed::Job.enqueue(SimpleJob.new, :n_strand => 'njobs')
        job.strand.should == "njobs"
      end

      it "should pick a strand randomly out of N" do
        Setting.set("njobs_num_strands", "3")
        Delayed::Job.expects(:rand).with(3).returns(1)
        job = Delayed::Job.enqueue(SimpleJob.new, :n_strand => 'njobs')
        job.strand.should == "njobs:2"
      end
    end
  end

  context "on hold" do
    it "should hold/unhold jobs" do
      job1 = create_job()
      job1.hold!
      @backend.get_and_lock_next_available('w1', 60).should be_nil

      job1.unhold!
      @backend.get_and_lock_next_available('w1', 60).should == job1
    end

    it "should hold a scope of jobs" do
      create_job().update_attributes(:attempts => 2)
      3.times { create_job() }
      create_job().update_attributes(:attempts => 1)
      scope = Delayed::Job.scoped(:conditions => { :attempts => 0 })
      scope.hold!.should == 3
      Delayed::Job.count.should == 5
      Delayed::Job.count(:conditions => { :locked_by => 'on hold' }).should == 3
    end

    it "should un-hold a scope of jobs" do
      3.times { create_job() }
      Delayed::Job.hold!
      scope = Delayed::Job.scoped(:limit => 2)
      scope.last.update_attribute(:run_at, 5.hours.from_now)
      scope.unhold!.should == 2
      jobs = scope.sort_by { |j| j.run_at }
      jobs.first.run_at.should <= Time.now
      jobs.last.run_at.should > 4.hours.from_now
    end
  end

  context "periodic jobs" do
    before(:each) do
      Delayed::Periodic.scheduled = {}
      Delayed::Periodic.cron('my SimpleJob', '*/5 * * * * *') do
        @backend.enqueue(SimpleJob.new)
      end
    end

    it "should schedule jobs if they aren't scheduled yet" do
      @backend.count.should == 0
      audit_started = @backend.db_time_now
      Delayed::Periodic.perform_audit!
      @backend.count.should == 1
      job = @backend.first
      job.tag.should == 'periodic: my SimpleJob'
      job.payload_object.should == Delayed::Periodic.scheduled['my SimpleJob']
      job.run_at.should >= audit_started
      job.run_at.should <= @backend.db_time_now + 6.minutes
      job.strand.should == job.tag
    end

    it "should schedule jobs if there are only failed jobs on the queue" do
      @backend.count.should == 0
      expect { Delayed::Periodic.perform_audit! }.to change(@backend, :count).by(1)
      @backend.count.should == 1
      job = @backend.first
      job.fail!
      expect { Delayed::Periodic.perform_audit! }.to change(@backend, :count).by(1)
    end

    it "should not schedule jobs that are already scheduled" do
      @backend.count.should == 0
      Delayed::Periodic.perform_audit!
      @backend.count.should == 1
      job = @backend.first
      Delayed::Periodic.perform_audit!
      @backend.count.should == 1
      job.should == @backend.first
    end

    it "should aduit on the auditor strand" do
      Delayed::Periodic.audit_queue
      @backend.count.should == 1
      @backend.first.strand.should == Delayed::Periodic::STRAND
    end

    it "should only schedule an audit if none is scheduled" do
      Delayed::Periodic.audit_queue
      @backend.count.should == 1
      Delayed::Periodic.audit_queue
      @backend.count.should == 1
    end

    it "should schedule the next job run after performing" do
      Delayed::Periodic.perform_audit!
      job = @backend.first
      run_job(job)
      job.destroy

      @backend.count.should == 2
      job = @backend.first(:order => 'run_at asc')
      job.tag.should == 'SimpleJob#perform'

      next_scheduled = @backend.last(:order => 'run_at asc')
      next_scheduled.tag.should == 'periodic: my SimpleJob'
      next_scheduled.payload_object.should be_is_a(Delayed::Periodic)
      next_scheduled.run_at.utc.to_i.should >= Time.now.utc.to_i
    end

    it "should not schedule the next job if a duplicate exists" do
      Delayed::Periodic.perform_audit!
      Delayed::Periodic.scheduled['my SimpleJob'].enqueue()
      Delayed::Job.count(:conditions => {:tag => 'periodic: my SimpleJob'}).should == 2
      # there's a duplicate, so running this job will delete the dup and
      # re-schedule
      run_job(Delayed::Job.first(:conditions => {:tag => 'periodic: my SimpleJob'}))
      Delayed::Job.count(:conditions => {:tag => 'periodic: my SimpleJob'}).should == 1
      # no more duplicate, so it should re-enqueue as normal
      run_job(Delayed::Job.first(:conditions => {:tag => 'periodic: my SimpleJob'}))
      Delayed::Job.count(:conditions => {:tag => 'periodic: my SimpleJob'}).should == 1
    end

    it "should reject duplicate named jobs" do
      proc { Delayed::Periodic.cron('my SimpleJob', '*/15 * * * * *') {} }.should raise_error(ArgumentError)
    end

    it "should allow overriding schedules using periodic_jobs.yml" do
      Setting.set_config('periodic_jobs', { 'my ChangedJob' => '*/10 * * * * *' })
      Delayed::Periodic.scheduled = {}
      Delayed::Periodic.cron('my ChangedJob', '*/5 * * * * *') do
        @backend.enqueue(SimpleJob.new)
      end
      Delayed::Periodic.scheduled['my ChangedJob'].cron.original.should == '*/10 * * * * *'
      Delayed::Periodic.audit_overrides!
    end

    it "should fail if the override cron line is invalid" do
      Setting.set_config('periodic_jobs', { 'my ChangedJob' => '*/10 * * * * * *' }) # extra asterisk
      Delayed::Periodic.scheduled = {}
      expect { Delayed::Periodic.cron('my ChangedJob', '*/5 * * * * *') do
        @backend.enqueue(SimpleJob.new)
      end }.to raise_error

      expect { Delayed::Periodic.audit_overrides! }.to raise_error
    end
  end

  module InDelayedJobTest
    def self.check_in_job
      Delayed::Job.in_delayed_job?.should == true
    end
  end

  it "should set in_delayed_job?" do
    job = InDelayedJobTest.send_later(:check_in_job)
    Delayed::Job.in_delayed_job?.should == false
    job.invoke_job
    Delayed::Job.in_delayed_job?.should == false
  end
end
