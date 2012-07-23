shared_examples_for 'a backend' do
  def create_job(opts = {})
    Delayed::Job.enqueue(SimpleJob.new, { :queue => nil }.merge(opts))
  end

  before do
    SimpleJob.runs = 0
  end

  it "should set run_at automatically if not set" do
    Delayed::Job.create(:payload_object => ErrorJob.new ).run_at.should_not be_nil
  end

  it "should not set run_at automatically if already set" do
    later = Delayed::Job.db_time_now + 5.minutes
    Delayed::Job.create(:payload_object => ErrorJob.new, :run_at => later).run_at.should be_close(later, 1)
  end

  it "should raise ArgumentError when handler doesn't respond_to :perform" do
    lambda { Delayed::Job.enqueue(Object.new) }.should raise_error(ArgumentError)
  end

  it "should increase count after enqueuing items" do
    Delayed::Job.enqueue SimpleJob.new
    Delayed::Job.count.should == 1
  end

  it "should be able to set priority when enqueuing items" do
    @job = Delayed::Job.enqueue SimpleJob.new, :priority => 5
    @job.priority.should == 5
  end

  it "should use the default priority when enqueuing items" do
    Delayed::Job.default_priority = 0
    @job = Delayed::Job.enqueue SimpleJob.new
    @job.priority.should == 0
    Delayed::Job.default_priority = 10
    @job = Delayed::Job.enqueue SimpleJob.new
    @job.priority.should == 10
    Delayed::Job.default_priority = 0
  end

  it "should be able to set run_at when enqueuing items" do
    later = Delayed::Job.db_time_now + 5.minutes
    @job = Delayed::Job.enqueue SimpleJob.new, :priority => 5, :run_at => later
    @job.run_at.should be_close(later, 1)
  end

  it "should work with jobs in modules" do
    M::ModuleJob.runs = 0
    job = Delayed::Job.enqueue M::ModuleJob.new
    lambda { job.invoke_job }.should change { M::ModuleJob.runs }.from(0).to(1)
  end

  it "should raise an DeserializationError when the job class is totally unknown" do
    job = Delayed::Job.new :handler => "--- !ruby/object:JobThatDoesNotExist {}"
    lambda { job.payload_object.perform }.should raise_error(Delayed::Backend::DeserializationError)
  end

  it "should try to load the class when it is unknown at the time of the deserialization" do
    job = Delayed::Job.new :handler => "--- !ruby/object:JobThatDoesNotExist {}"
    lambda { job.payload_object.perform }.should raise_error(Delayed::Backend::DeserializationError)
  end

  it "should try include the namespace when loading unknown objects" do
    job = Delayed::Job.new :handler => "--- !ruby/object:Delayed::JobThatDoesNotExist {}"
    lambda { job.payload_object.perform }.should raise_error(Delayed::Backend::DeserializationError)
  end

  it "should also try to load structs when they are unknown (raises TypeError)" do
    job = Delayed::Job.new :handler => "--- !ruby/struct:JobThatDoesNotExist {}"
    lambda { job.payload_object.perform }.should raise_error(Delayed::Backend::DeserializationError)
  end

  it "should try include the namespace when loading unknown structs" do
    job = Delayed::Job.new :handler => "--- !ruby/struct:Delayed::JobThatDoesNotExist {}"
    lambda { job.payload_object.perform }.should raise_error(Delayed::Backend::DeserializationError)
  end
  
  describe "find_available" do
    it "should not find failed jobs" do
      @job = create_job :attempts => 50
      @job.fail!
      Delayed::Job.find_available(5).should_not include(@job)
    end
    
    it "should not find jobs scheduled for the future" do
      @job = create_job :run_at => (Delayed::Job.db_time_now + 1.minute)
      Delayed::Job.find_available(5).should_not include(@job)
    end
    
    it "should not find jobs locked by another worker" do
      @job = create_job
      Delayed::Job.get_and_lock_next_available('other_worker').should == @job
      Delayed::Job.find_available(5).should_not include(@job)
    end
    
    it "should find open jobs" do
      @job = create_job
      Delayed::Job.find_available(5).should include(@job)
    end
    
    it "should find expired jobs" do
      @job = create_job
      Delayed::Job.get_and_lock_next_available('other_worker').should == @job
      @job.update_attribute(:locked_at, Delayed::Job.db_time_now - 2.minutes)
      Delayed::Job.unlock_expired_jobs(1.minute)
      Delayed::Job.find_available(5).should include(@job)
    end
  end
  
  context "when another worker is already performing an task, it" do

    before :each do
      @job = Delayed::Job.create :payload_object => SimpleJob.new
      Delayed::Job.get_and_lock_next_available('worker1').should == @job
    end

    it "should not allow a second worker to get exclusive access" do
      Delayed::Job.get_and_lock_next_available('worker2').should be_nil
    end

    it "should allow a second worker to get exclusive access if the timeout has passed" do
      @job.update_attribute(:locked_at, 5.hours.ago)
      Delayed::Job.unlock_expired_jobs(4.hours)
      Delayed::Job.get_and_lock_next_available('worker2').should == @job
      @job.reload
      @job.locked_by.should == 'worker2'
      @job.locked_at.should > 1.minute.ago
    end

    it "should not be found by another worker" do
      Delayed::Job.find_available(1).length.should == 0
    end

    it "should be found by another worker if the time has expired" do
      @job.update_attribute(:locked_at, 5.hours.ago)
      Delayed::Job.unlock_expired_jobs(4.hours)
      Delayed::Job.find_available(5).length.should == 1
    end
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
  end

  context "#name" do
    it "should be the class name of the job that was enqueued" do
      Delayed::Job.create(:payload_object => ErrorJob.new ).name.should == 'ErrorJob'
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
      jobs = Delayed::Job.find_available(10)
      jobs.size.should == 10
      jobs.each_cons(2) do |a, b| 
        a.priority.should <= b.priority
      end
    end
  end
  
  context "clear_locks!" do
    before do
      @job = create_job(:locked_by => 'worker', :locked_at => Delayed::Job.db_time_now)
    end
    
    it "should clear locks for the given worker" do
      Delayed::Job.clear_locks!('worker')
      Delayed::Job.find_available(5).should include(@job)
    end
    
    it "should not clear locks for other workers" do
      Delayed::Job.clear_locks!('worker1')
      Delayed::Job.find_available(5).should_not include(@job)
    end
  end
  
  context "unlock" do
    before do
      @job = create_job(:locked_by => 'worker', :locked_at => Delayed::Job.db_time_now)
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
      Delayed::Job.get_and_lock_next_available('w1').should == job1
      Delayed::Job.get_and_lock_next_available('w2').should == nil
      job1.destroy
      # update time since the failed lock pushed it forward
      job2.update_attribute(:run_at, 1.minute.ago)
      Delayed::Job.get_and_lock_next_available('w3').should == job2
      Delayed::Job.get_and_lock_next_available('w4').should == nil
    end

    it "should fail to lock if an earlier job gets locked" do
      job1 = create_job(:strand => 'myjobs')
      job2 = create_job(:strand => 'myjobs')
      Delayed::Job.find_available(2).should == [job1]
      Delayed::Job.find_available(2).should == [job1]

      # job1 gets locked by w1
      job1.lock_exclusively!('w1').should == true

      # w2 tries to lock job1, fails
      job1.lock_exclusively!('w2').should == false
      # normally w2 would now be able to lock job2, but strands prevent it
      Delayed::Job.get_and_lock_next_available('w2').should be_nil

      # now job1 is done
      job1.destroy
      # update time since the failed lock pushed it forward
      job2.update_attribute(:run_at, 1.minute.ago)
      job2.lock_exclusively!('w2').should == true
    end

    it "should keep strand jobs in order as they are rescheduled" do
      job1 = create_job(:strand => 'myjobs')
      job2 = create_job(:strand => 'myjobs')
      job3 = create_job(:strand => 'myjobs')
      Delayed::Job.get_and_lock_next_available('w1').should == job1
      Delayed::Job.find_available(1).should == []
      job1.destroy
      # move job2's time forward
      job2.update_attribute(:run_at, 1.second.ago)
      job3.update_attribute(:run_at, 5.seconds.ago)
      # we should still get job2, not job3
      Delayed::Job.get_and_lock_next_available('w1').should == job2
    end

    it "should allow to run the next job if a failed job is present" do
      job1 = create_job(:strand => 'myjobs')
      job2 = create_job(:strand => 'myjobs')
      job1.fail!
      Delayed::Job.find_available(2).should == [job2]
      job2.lock_exclusively!('w1').should == true
    end

    it "should not interfere with jobs with no strand" do
      job1 = create_job(:strand => nil)
      job2 = create_job(:strand => 'myjobs')
      Delayed::Job.get_and_lock_next_available('w1').should == job1
      Delayed::Job.get_and_lock_next_available('w2').should == job2
      Delayed::Job.get_and_lock_next_available('w3').should == nil
    end

    it "should not interfere with jobs in other strands" do
      job1 = create_job(:strand => 'strand1')
      job2 = create_job(:strand => 'strand2')
      Delayed::Job.get_and_lock_next_available('w1').should == job1
      Delayed::Job.get_and_lock_next_available('w2').should == job2
      Delayed::Job.get_and_lock_next_available('w3').should == nil
    end

    context 'singleton' do
      it "should create if there's no jobs on the strand" do
        @job = create_job(:singleton => 'myjobs')
        @job.should be_present
        Delayed::Job.get_and_lock_next_available('w1').should == @job
      end

      it "should create if there's another job on the strand, but it's running" do
        @job = create_job(:singleton => 'myjobs')
        @job.should be_present
        Delayed::Job.get_and_lock_next_available('w1').should == @job

        @job2 = create_job(:singleton => 'myjobs')
        @job.should be_present
        @job2.should_not == @job
      end

      it "should not create if there's another non-running job on the strand" do
        @job = create_job(:singleton => 'myjobs')
        @job.should be_present

        @job2 = create_job(:singleton => 'myjobs')
        @job2.should == @job
      end

      it "should not create if there's a job running and one waiting on the strand" do
        @job = create_job(:singleton => 'myjobs')
        @job.should be_present
        Delayed::Job.get_and_lock_next_available('w1').should == @job

        @job2 = create_job(:singleton => 'myjobs')
        @job2.should be_present
        @job2.should_not == @job

        @job3 = create_job(:singleton => 'myjobs')
        @job3.should == @job2
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
      Delayed::Job.get_and_lock_next_available('w1').should be_nil

      job1.unhold!
      Delayed::Job.get_and_lock_next_available('w1').should == job1
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
      scope = Delayed::Job.scoped(:limit => 2, :order => :id)
      scope.unhold!.should == 2
      Delayed::Job.count(:conditions => { :locked_by => 'on hold' }).should == 1
    end
  end

  context "periodic jobs" do
    before(:each) do
      Delayed::Periodic.scheduled = {}
      Delayed::Periodic.cron('my SimpleJob', '*/5 * * * * *') do
        Delayed::Job.enqueue(SimpleJob.new)
      end
    end

    it "should schedule jobs if they aren't scheduled yet" do
      Delayed::Job.count.should == 0
      audit_started = Delayed::Job.db_time_now
      Delayed::Periodic.perform_audit!
      Delayed::Job.count.should == 1
      job = Delayed::Job.first
      job.tag.should == 'periodic: my SimpleJob'
      job.payload_object.should == Delayed::Periodic.scheduled['my SimpleJob']
      job.run_at.should >= audit_started
      job.run_at.should <= Delayed::Job.db_time_now + 6.minutes
      job.strand.should == job.tag
    end

    it "should schedule jobs if there are only failed jobs on the queue" do
      Delayed::Job.count.should == 0
      expect { Delayed::Periodic.perform_audit! }.to change(Delayed::Job, :count).by(1)
      Delayed::Job.count.should == 1
      job = Delayed::Job.first
      job.fail!
      expect { Delayed::Periodic.perform_audit! }.to change(Delayed::Job, :count).by(1)
    end

    it "should not schedule jobs that are already scheduled" do
      Delayed::Job.count.should == 0
      Delayed::Periodic.perform_audit!
      Delayed::Job.count.should == 1
      job = Delayed::Job.first
      Delayed::Periodic.perform_audit!
      Delayed::Job.count.should == 1
      # verify that the same job still exists, it wasn't just replaced with a new one
      job.should == Delayed::Job.first
    end

    it "should schedule the next job run after performing" do
      # make the periodic job get scheduled in the past
      Delayed::Periodic.expects(:now).twice.returns(5.minutes.ago)

      Delayed::Periodic.perform_audit!
      job = Delayed::Job.get_and_lock_next_available('test1')
      run_job(job)
      job.destroy

      job = Delayed::Job.get_and_lock_next_available('test1')
      job.tag.should == 'SimpleJob#perform'

      next_scheduled = Delayed::Job.get_and_lock_next_available('test2')
      next_scheduled.tag.should == 'periodic: my SimpleJob'
      next_scheduled.payload_object.should be_is_a(Delayed::Periodic)
    end

    it "should not schedule the next job if a duplicate exists" do
      Delayed::Periodic.stubs(:now).returns(5.minutes.ago)
      tag =  'periodic: my SimpleJob'
      Delayed::Periodic.perform_audit!
      Delayed::Job.enqueue(Delayed::Periodic.scheduled['my SimpleJob'], :max_attempts => 1, :strand => tag)
      Delayed::Job.count(:conditions => {:tag => 'periodic: my SimpleJob'}).should == 2
      # there's a duplicate, so running this job will delete the dup and
      # re-schedule
      run_job(Delayed::Job.get_and_lock_next_available('test1'))
      Delayed::Job.count(:conditions => {:tag => 'periodic: my SimpleJob'}).should == 1
      # no more duplicate, so it should re-enqueue as normal
      run_job(Delayed::Job.get_and_lock_next_available('test1'))
      Delayed::Job.count(:conditions => {:tag => 'periodic: my SimpleJob'}).should == 1
    end

    it "should reject duplicate named jobs" do
      proc { Delayed::Periodic.cron('my SimpleJob', '*/15 * * * * *') {} }.should raise_error(ArgumentError)
    end

    it "should allow overriding schedules using periodic_jobs.yml" do
      Setting.set_config('periodic_jobs', { 'my ChangedJob' => '*/10 * * * * *' })
      Delayed::Periodic.scheduled = {}
      Delayed::Periodic.cron('my ChangedJob', '*/5 * * * * *') do
        Delayed::Job.enqueue(SimpleJob.new)
      end
      Delayed::Periodic.scheduled['my ChangedJob'].cron.original.should == '*/10 * * * * *'
      Delayed::Periodic.audit_overrides!
    end

    it "should fail if the override cron line is invalid" do
      Setting.set_config('periodic_jobs', { 'my ChangedJob' => '*/10 * * * * * *' }) # extra asterisk
      Delayed::Periodic.scheduled = {}
      expect { Delayed::Periodic.cron('my ChangedJob', '*/5 * * * * *') do
        Delayed::Job.enqueue(SimpleJob.new)
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

  it "should fail on job creation if an unsaved AR object is used" do
    story = Story.new :text => "Once upon..."
    lambda { story.send_later(:text) }.should raise_error

    reader = StoryReader.new
    lambda { reader.send_later(:read, story) }.should raise_error

    lambda { [story, 1, story, false].send_later(:first) }.should raise_error
  end
end
