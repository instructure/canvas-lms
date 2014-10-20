require File.expand_path("../../../../../../spec/sharding_spec_helper", __FILE__)

shared_examples_for 'Delayed::Batch' do
  before :each do
    Delayed::Worker.queue = "Delayed::Batch test"
  end

  context "batching" do
    it "should batch up all deferrable delayed methods" do
      later = 1.hour.from_now
      Delayed::Batch.serial_batch {
        "string".send_later_enqueue_args(:size, no_delay: true).should be true
        "string".send_later_enqueue_args(:reverse, run_at: later, no_delay: true).should be_truthy # won't be batched, it'll get its own job
        "string".send_later_enqueue_args(:gsub, { no_delay: true }, /./, "!").should be_truthy
      }
      batch_jobs = Delayed::Job.find_available(5)
      regular_jobs = Delayed::Job.list_jobs(:future, 5)
      regular_jobs.size.should == 1
      regular_jobs.first.batch?.should == false
      batch_jobs.size.should == 1
      batch_job = batch_jobs.first
      batch_job.batch?.should == true
      batch_job.payload_object.mode.should  == :serial
      batch_job.payload_object.jobs.map { |j| [j.payload_object.object, j.payload_object.method, j.payload_object.args] }.should  == [
        ["string", :size, []],
        ["string", :gsub, [/./, "!"]]
      ]
    end

    it "should not let you invoke it directly" do
      later = 1.hour.from_now
      Delayed::Batch.serial_batch {
        "string".send_later_enqueue_args(:size, no_delay: true).should be true
        "string".send_later_enqueue_args(:gsub, { no_delay: true }, /./, "!").should be true
      }
      Delayed::Job.jobs_count(:current).should == 1
      job = Delayed::Job.find_available(1).first
      expect{ job.invoke_job }.to raise_error
    end

    it "should create valid jobs" do
      Delayed::Batch.serial_batch {
        "string".send_later_enqueue_args(:size, no_delay: true).should be true
        "string".send_later_enqueue_args(:gsub, { no_delay: true }, /./, "!").should be true
      }
      Delayed::Job.jobs_count(:current).should == 1

      batch_job = Delayed::Job.find_available(1).first
      batch_job.batch?.should == true
      jobs = batch_job.payload_object.jobs
      jobs.size.should == 2
      jobs[0].should be_new_record
      jobs[0].payload_object.class.should   == Delayed::PerformableMethod
      jobs[0].payload_object.method.should  == :size
      jobs[0].payload_object.args.should    == []
      jobs[0].payload_object.perform.should == 6
      jobs[1].should be_new_record
      jobs[1].payload_object.class.should   == Delayed::PerformableMethod
      jobs[1].payload_object.method.should  == :gsub
      jobs[1].payload_object.args.should    == [/./, "!"]
      jobs[1].payload_object.perform.should == "!!!!!!"
    end

    it "should create a different batch for each priority" do
      later = 1.hour.from_now
      Delayed::Batch.serial_batch {
        "string".send_later_enqueue_args(:size, :priority => Delayed::LOW_PRIORITY, :no_delay => true).should be true
        "string".send_later_enqueue_args(:gsub, { :no_delay => true }, /./, "!").should be true
      }
      Delayed::Job.jobs_count(:current).should == 2
    end

    it "should use the given priority for all, if specified" do
      Delayed::Batch.serial_batch(:priority => 11) {
        "string".send_later_enqueue_args(:size, :priority => 20, :no_delay => true).should be true
        "string".send_later_enqueue_args(:gsub, { :priority => 15, :no_delay => true }, /./, "!").should be true
      }
      Delayed::Job.jobs_count(:current).should == 1
      Delayed::Job.find_available(1).first.priority.should == 11
    end

    it "should just create the job, if there's only one in the batch" do
      Delayed::Batch.serial_batch(:priority => 11) {
        "string".send_later_enqueue_args(:size, no_delay: true).should be true
      }
      Delayed::Job.jobs_count(:current).should == 1
      Delayed::Job.find_available(1).first.tag.should == "String#size"
      Delayed::Job.find_available(1).first.priority.should == 11
    end
  end

  shared_examples_for "delayed_jobs_shards" do
    it "should keep track of the current shard on child jobs" do
      shard = @shard1 || Shard.default
      shard.activate do
        Delayed::Batch.serial_batch {
          "string".send_later_enqueue_args(:size, no_delay: true).should be true
          "string".send_later_enqueue_args(:gsub, { no_delay: true }, /./, "!").should be true
        }
      end
      job = Delayed::Job.find_available(1).first
      job.current_shard.should == shard
      job.payload_object.jobs.first.current_shard.should == shard
    end
  end

  describe "current_shard" do
    include_examples "delayed_jobs_shards"

    context "sharding" do
      specs_require_sharding
      include_examples "delayed_jobs_shards"
    end
  end
end
