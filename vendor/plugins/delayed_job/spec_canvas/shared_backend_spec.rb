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
      @job = create_job :attempts => 50, :failed_at => @backend.db_time_now
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
      @job.lock_exclusively!(1.minute, 'worker2').should == true
    end      
    
    it "should be able to get access to the task if it was started more then max_age ago" do
      @job.locked_at = 5.hours.ago
      @job.save

      @job.lock_exclusively! 4.hours, 'worker2'
      @job.reload
      @job.locked_by.should == 'worker2'
      @job.locked_at.should > 1.minute.ago
    end

    it "should not be found by another worker" do
      @backend.find_available('worker2', 1, 6.minutes).length.should == 0
    end

    it "should be found by another worker if the time has expired" do
      @backend.find_available('worker2', 1, 4.minutes).length.should == 1
    end

    it "should be able to get exclusive access again when the worker name is the same" do
      @job.lock_exclusively!(5.minutes, 'worker1').should be_true
      @job.update_attribute(:locked_at, 1.minute.ago)
      @job.lock_exclusively!(5.minutes, 'worker1').should be_true
      @job.update_attribute(:locked_at, 1.minute.ago)
      @job.lock_exclusively!(5.minutes, 'worker1').should be_true
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
      @backend.find_available('w1', 2, 60).should == [job1, job2]
      @backend.find_available('w2', 2, 60).should == [job1, job2]

      # job1 gets locked by w1
      job1.lock_exclusively!(60, 'w1').should == true

      # w2 tries to lock job1, fails
      job1.lock_exclusively!(60, 'w2').should == false
      # normally w2 would now be able to lock job2, but strands prevent it
      job2.lock_exclusively!(60, 'w2').should == false

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
      @backend.find_available('w2', 1, 60).should == [job2]
      job2.reload.lock_exclusively!(60, 'w2').should be_false
      # job2 just got rescheduled, but not job3. make sure that job2 still runs first.
      job1.destroy
      # fake out the current time since the job got rescheduled for the future
      @backend.stub!(:db_time_now).and_return(5.minutes.from_now)
      @backend.get_and_lock_next_available('w1', 60).should == job2
    end

    it "should allow to run the next job if a failed job is present" do
      job1 = create_job(:strand => 'myjobs')
      job2 = create_job(:strand => 'myjobs')
      job1.update_attribute(:failed_at, Time.now)
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
      Delayed::Periodic.perform_audit!
      @backend.count.should == 1
      job = @backend.first
      job.tag.should == 'periodic: my SimpleJob'
      job.payload_object.should == Delayed::Periodic.scheduled['my SimpleJob']
      job.run_at.should >= @backend.db_time_now
      job.run_at.should <= @backend.db_time_now + 6.minutes
    end

    it "should schedule jobs if there are only failed jobs on the queue" do
      @backend.count.should == 0
      Delayed::Periodic.perform_audit!
      @backend.count.should == 1
      job = @backend.first
      job.update_attribute :failed_at, @backend.db_time_now
      Delayed::Periodic.perform_audit!
      @backend.count.should == 2
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
      job.invoke_job
      job.destroy

      @backend.count.should == 2
      job = @backend.first(:order => 'run_at asc')
      job.tag.should == 'SimpleJob#perform'

      next_scheduled = @backend.last(:order => 'run_at asc')
      next_scheduled.tag.should == 'periodic: my SimpleJob'
      next_scheduled.payload_object.should be_is_a(Delayed::Periodic)
      next_scheduled.run_at.utc.to_i.should >= Time.now.utc.to_i
    end

    it "should reject duplicate named jobs" do
      proc { Delayed::Periodic.cron('my SimpleJob', '*/15 * * * * *') {} }.should raise_error(ArgumentError)
    end
  end
end
