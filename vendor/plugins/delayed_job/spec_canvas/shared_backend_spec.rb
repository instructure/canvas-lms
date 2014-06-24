shared_examples_for 'a backend' do
  def create_job(opts = {})
    Delayed::Job.enqueue(SimpleJob.new, { :queue => nil }.merge(opts))
  end

  before do
    SimpleJob.runs = 0
  end

  it "should set run_at automatically if not set" do
    Delayed::Job.create(:payload_object => ErrorJob.new).run_at.should_not be_nil
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
    Delayed::Job.jobs_count(:current).should == 1
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
  end
  
  context "when another worker is already performing an task, it" do

    before :each do
      @job = Delayed::Job.create :payload_object => SimpleJob.new
      Delayed::Job.get_and_lock_next_available('worker1').should == @job
    end

    it "should not allow a second worker to get exclusive access" do
      Delayed::Job.get_and_lock_next_available('worker2').should be_nil
    end

    it "should not be found by another worker" do
      Delayed::Job.find_available(1).length.should == 0
    end
  end

  context "#name" do
    it "should be the class name of the job that was enqueued" do
      Delayed::Job.create(:payload_object => ErrorJob.new ).name.should == 'ErrorJob'
    end

    it "should be the method that will be called if its a performable method object" do
      @job = Story.send_later_enqueue_args(:create, no_delay: true)
      @job.name.should == "Story.create"
    end

    it "should be the instance method that will be called if its a performable method object" do
      @job = Story.create(:text => "...").send_later_enqueue_args(:save, no_delay: true)
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

    it "should not find jobs lower than the given priority" do
      job1 = create_job :priority => 5
      found = Delayed::Job.get_and_lock_next_available('test1', Delayed::Worker.queue, 10, 20)
      found.should be_nil
      job2 = create_job :priority => 10
      found = Delayed::Job.get_and_lock_next_available('test1', Delayed::Worker.queue, 10, 20)
      found.should == job2
      job3 = create_job :priority => 15
      found = Delayed::Job.get_and_lock_next_available('test2', Delayed::Worker.queue, 10, 20)
      found.should == job3
    end

    it "should not find jobs higher than the given priority" do
      job1 = create_job :priority => 25
      found = Delayed::Job.get_and_lock_next_available('test1', Delayed::Worker.queue, 10, 20)
      found.should be_nil
      job2 = create_job :priority => 20
      found = Delayed::Job.get_and_lock_next_available('test1', Delayed::Worker.queue, 10, 20)
      found.should == job2
      job3 = create_job :priority => 15
      found = Delayed::Job.get_and_lock_next_available('test2', Delayed::Worker.queue, 10, 20)
      found.should == job3
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
      job2.run_at = 1.minute.ago
      job2.save!
      Delayed::Job.get_and_lock_next_available('w3').should == job2
      Delayed::Job.get_and_lock_next_available('w4').should == nil
    end

    it "should fail to lock if an earlier job gets locked" do
      job1 = create_job(:strand => 'myjobs')
      job2 = create_job(:strand => 'myjobs')
      Delayed::Job.find_available(2).should == [job1]
      Delayed::Job.find_available(2).should == [job1]

      # job1 gets locked by w1
      Delayed::Job.get_and_lock_next_available('w1').should == job1

      # normally w2 would now be able to lock job2, but strands prevent it
      Delayed::Job.get_and_lock_next_available('w2').should be_nil

      # now job1 is done
      job1.destroy
      # update time since the failed lock pushed it forward
      job2.run_at = 1.minute.ago
      job2.save!
      Delayed::Job.get_and_lock_next_available('w2').should == job2
    end

    it "should keep strand jobs in order as they are rescheduled" do
      job1 = create_job(:strand => 'myjobs')
      job2 = create_job(:strand => 'myjobs')
      job3 = create_job(:strand => 'myjobs')
      Delayed::Job.get_and_lock_next_available('w1').should == job1
      Delayed::Job.find_available(1).should == []
      job1.destroy
      Delayed::Job.find_available(1).should == [job2]
      # move job2's time forward
      job2.run_at = 1.second.ago
      job2.save!
      job3.run_at = 5.seconds.ago
      job3.save!
      # we should still get job2, not job3
      Delayed::Job.get_and_lock_next_available('w1').should == job2
    end

    it "should allow to run the next job if a failed job is present" do
      job1 = create_job(:strand => 'myjobs')
      job2 = create_job(:strand => 'myjobs')
      job1.fail!
      Delayed::Job.get_and_lock_next_available('w1').should == job2
    end

    it "should not interfere with jobs with no strand" do
      jobs = [create_job(:strand => nil), create_job(:strand => 'myjobs')]
      locked = [Delayed::Job.get_and_lock_next_available('w1'),
                Delayed::Job.get_and_lock_next_available('w2')]
      jobs.should =~ locked
      Delayed::Job.get_and_lock_next_available('w3').should == nil
    end

    it "should not interfere with jobs in other strands" do
      jobs = [create_job(:strand => 'strand1'), create_job(:strand => 'strand2')]
      locked = [Delayed::Job.get_and_lock_next_available('w1'),
                Delayed::Job.get_and_lock_next_available('w2')]
      jobs.should =~ locked
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

      context "with two parameters" do
        it "should use the first param as the setting to read" do
          job = Delayed::Job.enqueue(SimpleJob.new, n_strand: ["njobs", "123"])
          job.strand.should == "njobs/123"
          Setting.set("njobs_num_strands", "3")
          Delayed::Job.expects(:rand).with(3).returns(1)
          job = Delayed::Job.enqueue(SimpleJob.new, n_strand: ["njobs", "123"])
          job.strand.should == "njobs/123:2"
        end

        it "should allow overridding the setting based on the second param" do
          Setting.set("njobs/123_num_strands", "5")
          Delayed::Job.expects(:rand).with(5).returns(3)
          job = Delayed::Job.enqueue(SimpleJob.new, n_strand: ["njobs", "123"])
          job.strand.should == "njobs/123:4"
          job = Delayed::Job.enqueue(SimpleJob.new, n_strand: ["njobs", "456"])
          job.strand.should == "njobs/456"

          Setting.set("njobs_num_strands", "3")
          Delayed::Job.expects(:rand).with(5).returns(2)
          Delayed::Job.expects(:rand).with(3).returns(1)
          job = Delayed::Job.enqueue(SimpleJob.new, n_strand: ["njobs", "123"])
          job.strand.should == "njobs/123:3"
          job = Delayed::Job.enqueue(SimpleJob.new, n_strand: ["njobs", "456"])
          job.strand.should == "njobs/456:2"
        end
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
  end

  context "periodic jobs" do
    before(:each) do
      # make the periodic job get scheduled in the past
      @cron_time = 10.minutes.ago
      Delayed::Periodic.stubs(:now).returns(@cron_time)
      Delayed::Periodic.scheduled = {}
      Delayed::Periodic.cron('my SimpleJob', '*/5 * * * * *') do
        Delayed::Job.enqueue(SimpleJob.new)
      end
    end

    it "should schedule jobs if they aren't scheduled yet" do
      Delayed::Job.jobs_count(:current).should == 0
      Delayed::Periodic.perform_audit!
      Delayed::Job.jobs_count(:current).should == 1
      job = Delayed::Job.get_and_lock_next_available('test1')
      job.tag.should == 'periodic: my SimpleJob'
      job.payload_object.should == Delayed::Periodic.scheduled['my SimpleJob']
      job.run_at.should >= @cron_time
      job.run_at.should <= @cron_time + 6.minutes
      job.strand.should == job.tag
    end

    it "should schedule jobs if there are only failed jobs on the queue" do
      Delayed::Job.jobs_count(:current).should == 0
      expect { Delayed::Periodic.perform_audit! }.to change { Delayed::Job.jobs_count(:current) }.by(1)
      Delayed::Job.jobs_count(:current).should == 1
      job = Delayed::Job.get_and_lock_next_available('test1')
      job.fail!
      expect { Delayed::Periodic.perform_audit! }.to change{ Delayed::Job.jobs_count(:current) }.by(1)
    end

    it "should not schedule jobs that are already scheduled" do
      Delayed::Job.jobs_count(:current).should == 0
      Delayed::Periodic.perform_audit!
      Delayed::Job.jobs_count(:current).should == 1
      job = Delayed::Job.find_available(1).first
      Delayed::Periodic.perform_audit!
      Delayed::Job.jobs_count(:current).should == 1
      # verify that the same job still exists, it wasn't just replaced with a new one
      job.should == Delayed::Job.find_available(1).first
    end

    it "should schedule the next job run after performing" do
      Delayed::Periodic.perform_audit!
      Delayed::Job.jobs_count(:current).should == 1
      job = Delayed::Job.get_and_lock_next_available('test')
      run_job(job)

      job = Delayed::Job.get_and_lock_next_available('test1')
      job.tag.should == 'SimpleJob#perform'

      next_scheduled = Delayed::Job.get_and_lock_next_available('test2')
      next_scheduled.tag.should == 'periodic: my SimpleJob'
      next_scheduled.payload_object.should be_is_a(Delayed::Periodic)
    end

    it "should reject duplicate named jobs" do
      proc { Delayed::Periodic.cron('my SimpleJob', '*/15 * * * * *') {} }.should raise_error(ArgumentError)
    end

    it "should handle jobs that are no longer scheduled" do
      Delayed::Periodic.perform_audit!
      Delayed::Periodic.scheduled = {}
      job = Delayed::Job.get_and_lock_next_available('test')
      run_job(job)
      # shouldn't error, and the job should now be deleted
      Delayed::Job.jobs_count(:current).should == 0
    end

    it "should allow overriding schedules using periodic_jobs.yml" do
      ConfigFile.stub('periodic_jobs', { 'my ChangedJob' => '*/10 * * * * *' })
      Delayed::Periodic.scheduled = {}
      Delayed::Periodic.cron('my ChangedJob', '*/5 * * * * *') do
        Delayed::Job.enqueue(SimpleJob.new)
      end
      Delayed::Periodic.scheduled['my ChangedJob'].cron.original.should == '*/10 * * * * *'
      Delayed::Periodic.audit_overrides!
    end

    it "should fail if the override cron line is invalid" do
      ConfigFile.stub('periodic_jobs', { 'my ChangedJob' => '*/10 * * * * * *' }) # extra asterisk
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
    job = InDelayedJobTest.send_later_enqueue_args(:check_in_job, no_delay: true)
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

  # the sort order of current_jobs and list_jobs depends on the back-end
  # implementation, so sort order isn't tested in these specs
  describe "current jobs, queue size, strand_size" do
    before do
      @jobs = []
      3.times { @jobs << create_job(:priority => 3) }
      @jobs.unshift create_job(:priority => 2)
      @jobs.unshift create_job(:priority => 1)
      @jobs << create_job(:priority => 3, :strand => "test1")
      @future_job = create_job(:run_at => 5.hours.from_now)
      2.times { @jobs << create_job(:priority => 3) }
      @jobs << create_job(:priority => 3, :strand => "test1")
      @failed_job = create_job.tap { |j| j.fail! }
      @other_queue_job = create_job(:queue => "another")
    end

    it "should return the queued jobs" do
      Delayed::Job.list_jobs(:current, 100).map(&:id).sort.should == @jobs.map(&:id).sort
    end

    it "should paginate the returned jobs" do
      @returned = []
      @returned += Delayed::Job.list_jobs(:current, 3, 0)
      @returned += Delayed::Job.list_jobs(:current, 4, 3)
      @returned += Delayed::Job.list_jobs(:current, 100, 7)
      @returned.sort_by { |j| j.id }.should == @jobs.sort_by { |j| j.id }
    end

    it "should return other queues" do
      Delayed::Job.list_jobs(:current, 5, 0, "another").should == [@other_queue_job]
    end

    it "should return queue size" do
      Delayed::Job.jobs_count(:current).should == @jobs.size
      Delayed::Job.jobs_count(:current, "another").should == 1
      Delayed::Job.jobs_count(:current, "bogus").should == 0
    end

    it "should return strand size" do
      Delayed::Job.strand_size("test1").should == 2
      Delayed::Job.strand_size("bogus").should == 0
    end
  end

  it "should return the jobs in a strand" do
    strand_jobs = []
    3.times { strand_jobs << create_job(:strand => 'test1') }
    2.times { create_job(:strand => 'test2') }
    strand_jobs << create_job(:strand => 'test1', :run_at => 5.hours.from_now)
    create_job

    jobs = Delayed::Job.list_jobs(:strand, 3, 0, "test1")
    jobs.size.should == 3

    jobs += Delayed::Job.list_jobs(:strand, 3, 3, "test1")
    jobs.size.should == 4

    jobs.sort_by { |j| j.id }.should == strand_jobs.sort_by { |j| j.id }
  end

  it "should return the jobs for a tag" do
    tag_jobs = []
    3.times { tag_jobs << "test".send_later_enqueue_args(:to_s, :no_delay => true) }
    2.times { "test".send_later(:to_i) }
    tag_jobs << "test".send_later_enqueue_args(:to_s, :run_at => 5.hours.from_now, :no_delay => true)
    tag_jobs << "test".send_later_enqueue_args(:to_s, :strand => "test1", :no_delay => true)
    "test".send_later_enqueue_args(:to_i, :strand => "test1")
    create_job

    jobs = Delayed::Job.list_jobs(:tag, 3, 0, "String#to_s")
    jobs.size.should == 3

    jobs += Delayed::Job.list_jobs(:tag, 3, 3, "String#to_s")
    jobs.size.should == 5

    jobs.sort_by { |j| j.id }.should == tag_jobs.sort_by { |j| j.id }
  end

  describe "running_jobs" do
    it "should return the running jobs, ordered by locked_at" do
      Delayed::Job.stubs(:db_time_now).returns(10.minutes.ago)
      3.times { create_job }
      Delayed::Job.stubs(:db_time_now).returns(2.minutes.ago)
      j1 = Delayed::Job.get_and_lock_next_available('w1')
      Delayed::Job.stubs(:db_time_now).returns(5.minutes.ago)
      j2 = Delayed::Job.get_and_lock_next_available('w2')
      Delayed::Job.stubs(:db_time_now).returns(5.seconds.ago)
      j3 = Delayed::Job.get_and_lock_next_available('w3')
      [j1, j2, j3].compact.size.should == 3

      Delayed::Job.running_jobs.should == [j2, j1, j3]
    end
  end

  describe "future jobs" do
    it "should find future jobs once their run_at rolls by" do
      Delayed::Job.stubs(:db_time_now).returns(1.hour.ago)
      @job = create_job :run_at => 5.minutes.from_now
      Delayed::Job.find_available(5).should_not include(@job)
      Delayed::Job.stubs(:db_time_now).returns(1.hour.from_now)
      Delayed::Job.find_available(5).should include(@job)
      Delayed::Job.get_and_lock_next_available('test').should == @job
    end

    it "should return future jobs sorted by their run_at" do
      @j1 = create_job
      @j2 = create_job :run_at => 1.hour.from_now
      @j3 = create_job :run_at => 30.minutes.from_now
      Delayed::Job.list_jobs(:future, 1).should == [@j3]
      Delayed::Job.list_jobs(:future, 5).should == [@j3, @j2]
      Delayed::Job.list_jobs(:future, 1, 1).should == [@j2]
    end
  end

  describe "failed jobs" do
    # the sort order of failed_jobs depends on the back-end implementation,
    # so sort order isn't tested here
    it "should return the list of failed jobs" do
      jobs = []
      3.times { jobs << create_job(:priority => 3) }
      jobs.sort_by { |j| j.id }
      Delayed::Job.list_jobs(:failed, 1).should == []
      jobs[0].fail!
      jobs[1].fail!
      failed = (Delayed::Job.list_jobs(:failed, 1, 0) + Delayed::Job.list_jobs(:failed, 1, 1)).sort_by { |j| j.id }
      failed.size.should == 2
      failed[0].original_job_id.should == jobs[0].id
      failed[1].original_job_id.should == jobs[1].id
    end
  end

  describe "bulk_update" do
    shared_examples_for "scope" do
      before do
        @affected_jobs = []
        @ignored_jobs = []
      end

      it "should hold a scope of jobs" do
        @affected_jobs.all? { |j| j.on_hold? }.should be_false
        @ignored_jobs.any? { |j| j.on_hold? }.should be_false
        Delayed::Job.bulk_update('hold', :flavor => @flavor, :query => @query).should == @affected_jobs.size

        @affected_jobs.all? { |j| Delayed::Job.find(j.id).on_hold? }.should be_true
        @ignored_jobs.any? { |j| Delayed::Job.find(j.id).on_hold? }.should be_false
      end

      it "should un-hold a scope of jobs" do
        pending "fragile on mysql for unknown reasons" if Delayed::Job == Delayed::Backend::ActiveRecord::Job && %w{MySQL Mysql2}.include?(Delayed::Job.connection.adapter_name)
        Delayed::Job.bulk_update('unhold', :flavor => @flavor, :query => @query).should == @affected_jobs.size

        @affected_jobs.any? { |j| Delayed::Job.find(j.id).on_hold? }.should be_false
        @ignored_jobs.any? { |j| Delayed::Job.find(j.id).on_hold? }.should be_false
      end

      it "should delete a scope of jobs" do
        Delayed::Job.bulk_update('destroy', :flavor => @flavor, :query => @query).should == @affected_jobs.size
        @affected_jobs.map { |j| Delayed::Job.find(j.id) rescue nil }.compact.should be_blank
        @ignored_jobs.map { |j| Delayed::Job.find(j.id) rescue nil }.compact.size.should == @ignored_jobs.size
      end
    end

    describe "scope: current" do
      include_examples "scope"
      before do
        @flavor = 'current'
        Timecop.freeze(5.minutes.ago) do
          3.times { @affected_jobs << create_job }
          @ignored_jobs << create_job(:run_at => 2.hours.from_now)
          @ignored_jobs << create_job(:queue => 'q2')
        end
      end
    end

    describe "scope: future" do
      include_examples "scope"
      before do
        @flavor = 'future'
        Timecop.freeze(5.minutes.ago) do
          3.times { @affected_jobs << create_job(:run_at => 2.hours.from_now) }
          @ignored_jobs << create_job
          @ignored_jobs << create_job(:queue => 'q2', :run_at => 2.hours.from_now)
        end
      end
    end

    describe "scope: strand" do
      include_examples "scope"
      before do
        @flavor = 'strand'
        @query = 's1'
        Timecop.freeze(5.minutes.ago) do
          @affected_jobs << create_job(:strand => 's1')
          @affected_jobs << create_job(:strand => 's1', :run_at => 2.hours.from_now)
          @ignored_jobs << create_job
          @ignored_jobs << create_job(:strand => 's2')
          @ignored_jobs << create_job(:strand => 's2', :run_at => 2.hours.from_now)
        end
      end
    end

    describe "scope: tag" do
      include_examples "scope"
      before do
        @flavor = 'tag'
        @query = 'String#to_i'
        Timecop.freeze(5.minutes.ago) do
          @affected_jobs << "test".send_later_enqueue_args(:to_i, :no_delay => true)
          @affected_jobs << "test".send_later_enqueue_args(:to_i, :strand => 's1', :no_delay => true)
          @affected_jobs << "test".send_later_enqueue_args(:to_i, :run_at => 2.hours.from_now, :no_delay => true)
          @ignored_jobs << create_job
          @ignored_jobs << create_job(:run_at => 1.hour.from_now)
        end
      end
    end

    it "should hold and un-hold given job ids" do
      j1 = "test".send_later_enqueue_args(:to_i, :no_delay => true)
      j2 = create_job(:run_at => 2.hours.from_now)
      j3 = "test".send_later_enqueue_args(:to_i, :strand => 's1', :no_delay => true)
      Delayed::Job.bulk_update('hold', :ids => [j1.id, j2.id]).should == 2
      Delayed::Job.find(j1.id).on_hold?.should be_true
      Delayed::Job.find(j2.id).on_hold?.should be_true
      Delayed::Job.find(j3.id).on_hold?.should be_false

      Delayed::Job.bulk_update('unhold', :ids => [j2.id]).should == 1
      Delayed::Job.find(j1.id).on_hold?.should be_true
      Delayed::Job.find(j2.id).on_hold?.should be_false
      Delayed::Job.find(j3.id).on_hold?.should be_false
    end

    it "should delete given job ids" do
      jobs = (0..2).map { create_job }
      Delayed::Job.bulk_update('destroy', :ids => jobs[0,2].map(&:id)).should == 2
      jobs.map { |j| Delayed::Job.find(j.id) rescue nil }.compact.should == jobs[2,1]
    end
  end

  describe "tag_counts" do
    before do
      @cur = []
      3.times { @cur << "test".send_later_enqueue_args(:to_s, no_delay: true) }
      5.times { @cur << "test".send_later_enqueue_args(:to_i, no_delay: true) }
      2.times { @cur << "test".send_later_enqueue_args(:upcase, no_delay: true) }
      ("test".send_later_enqueue_args :downcase, no_delay: true).fail!
      @future = []
      5.times { @future << "test".send_later_enqueue_args(:downcase, run_at: 3.hours.from_now, no_delay: true) }
      @cur << "test".send_later_enqueue_args(:downcase, no_delay: true)
    end

    it "should return a sorted list of popular current tags" do
      Delayed::Job.tag_counts(:current, 1).should == [{ :tag => "String#to_i", :count => 5 }]
      Delayed::Job.tag_counts(:current, 1, 1).should == [{ :tag => "String#to_s", :count => 3 }]
      Delayed::Job.tag_counts(:current, 5).should == [{ :tag => "String#to_i", :count => 5 },
                                                      { :tag => "String#to_s", :count => 3 },
                                                      { :tag => "String#upcase", :count => 2 },
                                                      { :tag => "String#downcase", :count => 1 }]
      @cur[0,4].each { |j| j.destroy }
      @future[0].run_at = @future[1].run_at = 1.hour.ago
      @future[0].save!
      @future[1].save!

      Delayed::Job.tag_counts(:current, 5).should == [{ :tag => "String#to_i", :count => 4 },
                                                      { :tag => "String#downcase", :count => 3 },
                                                      { :tag => "String#upcase", :count => 2 },]
    end

    it "should return a sorted list of all popular tags" do
      Delayed::Job.tag_counts(:all, 1).should == [{ :tag => "String#downcase", :count => 6 }]
      Delayed::Job.tag_counts(:all, 1, 1).should == [{ :tag => "String#to_i", :count => 5 }]
      Delayed::Job.tag_counts(:all, 5).should == [{ :tag => "String#downcase", :count => 6 },
                                                  { :tag => "String#to_i", :count => 5 },
                                                  { :tag => "String#to_s", :count => 3 },
                                                  { :tag => "String#upcase", :count => 2 },]

      @cur[0,4].each { |j| j.destroy }
      @future[0].destroy
      @future[1].fail!
      @future[2].fail!

      Delayed::Job.tag_counts(:all, 5).should == [{ :tag => "String#to_i", :count => 4 },
                                                  { :tag => "String#downcase", :count => 3 },
                                                  { :tag => "String#upcase", :count => 2 },]
    end
  end

  it "should unlock orphaned jobs" do
    job1 = Delayed::Job.new(:tag => 'tag')
    job2 = Delayed::Job.new(:tag => 'tag')
    job3 = Delayed::Job.new(:tag => 'tag')
    job4 = Delayed::Job.new(:tag => 'tag')
    job1.create_and_lock!("Jobworker:#{Process.pid}")
    `echo ''`
    child_pid = $?.pid
    job2.create_and_lock!("Jobworker:#{child_pid}")
    job3.create_and_lock!("someoneelse:#{Process.pid}")
    job4.create_and_lock!("Jobworker:notanumber")

    Delayed::Job.unlock_orphaned_jobs(nil, "Jobworker").should == 1

    Delayed::Job.find(job1.id).locked_by.should_not be_nil
    Delayed::Job.find(job2.id).locked_by.should be_nil
    Delayed::Job.find(job3.id).locked_by.should_not be_nil
    Delayed::Job.find(job4.id).locked_by.should_not be_nil

    Delayed::Job.unlock_orphaned_jobs(nil, "Jobworker").should == 0
  end

  it "should unlock orphaned jobs given a pid" do
    job1 = Delayed::Job.new(:tag => 'tag')
    job2 = Delayed::Job.new(:tag => 'tag')
    job3 = Delayed::Job.new(:tag => 'tag')
    job4 = Delayed::Job.new(:tag => 'tag')
    job1.create_and_lock!("Jobworker:#{Process.pid}")
    `echo ''`
    child_pid = $?.pid
    `echo ''`
    child_pid2 = $?.pid
    job2.create_and_lock!("Jobworker:#{child_pid}")
    job3.create_and_lock!("someoneelse:#{Process.pid}")
    job4.create_and_lock!("Jobworker:notanumber")

    Delayed::Job.unlock_orphaned_jobs(child_pid2, "Jobworker").should == 0
    Delayed::Job.unlock_orphaned_jobs(child_pid, "Jobworker").should == 1

    Delayed::Job.find(job1.id).locked_by.should_not be_nil
    Delayed::Job.find(job2.id).locked_by.should be_nil
    Delayed::Job.find(job3.id).locked_by.should_not be_nil
    Delayed::Job.find(job4.id).locked_by.should_not be_nil

    Delayed::Job.unlock_orphaned_jobs(child_pid, "Jobworker").should == 0
  end
end
