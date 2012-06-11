require File.expand_path("../../../../../spec/sharding_spec_helper", __FILE__)

shared_examples_for 'Delayed::Batch' do
  before :each do
    Delayed::Worker.queue = nil
    Delayed::Job.delete_all
  end

  context "batching" do
    it "should batch up all deferrable delayed methods" do
      later = 1.hour.from_now
      Delayed::Batch.serial_batch {
        "string".send_later(:size).should be_true
        "string".send_at(later, :reverse).should be_true # won't be batched, it'll get its own job
        "string".send_later(:gsub, /./, "!").should be_true
      }
      jobs = Delayed::Job.all
      jobs.size.should == 2
      batch_jobs, regular_jobs = jobs.partition(&:batch?)
      regular_jobs.size.should == 1
      batch_jobs.size.should == 1
      batch_job = batch_jobs.first 
      batch_job.payload_object.mode.should  == :serial
      batch_job.payload_object.jobs.map { |j| [j.payload_object.object, j.payload_object.method, j.payload_object.args] }.should  == [
        ["string", :size, []],
        ["string", :gsub, [/./, "!"]]
      ]
    end

    it "should not let you invoke it directly" do
      later = 1.hour.from_now
      Delayed::Batch.serial_batch {
        "string".send_later(:size).should be_true
        "string".send_later(:gsub, /./, "!").should be_true
      }
      Delayed::Job.count.should == 1
      job = Delayed::Job.first
      expect{ job.invoke_job }.to raise_error
    end

    it "should create valid jobs" do
      Delayed::Batch.serial_batch {
        "string".send_later(:size).should be_true
        "string".send_later(:gsub, /./, "!").should be_true
      }
      Delayed::Job.count.should == 1

      batch_job = Delayed::Job.first
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
        "string".send_later_enqueue_args(:size, :priority => Delayed::LOW_PRIORITY).should be_true
        "string".send_later(:gsub, /./, "!").should be_true
      }
      Delayed::Job.count.should == 2
    end
  end

  shared_examples_for "delayed_jobs_shards" do
    it "should keep track of the current shard on child jobs" do
      shard = @shard1 || Shard.default
      shard.activate do
        Delayed::Batch.serial_batch {
          "string".send_later(:size).should be_true
          "string".send_later(:gsub, /./, "!").should be_true
        }
      end
      job = Delayed::Job.last
      job.current_shard.should == shard
      job.payload_object.jobs.first.current_shard.should == shard
    end
  end

  describe "current_shard" do
    it_should_behave_like "delayed_jobs_shards"

    context "sharding" do
      it_should_behave_like "sharding"
      it_should_behave_like "delayed_jobs_shards"
    end
  end
end
