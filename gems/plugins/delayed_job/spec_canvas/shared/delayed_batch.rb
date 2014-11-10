require File.expand_path("../../../../../../spec/sharding_spec_helper", __FILE__)

shared_examples_for 'Delayed::Batch' do
  before :each do
    Delayed::Worker.queue = "Delayed::Batch test"
  end

  context "batching" do
    it "should batch up all deferrable delayed methods" do
      later = 1.hour.from_now
      Delayed::Batch.serial_batch {
        expect("string".send_later_enqueue_args(:size, no_delay: true)).to be true
        expect("string".send_later_enqueue_args(:reverse, run_at: later, no_delay: true)).to be_truthy # won't be batched, it'll get its own job
        expect("string".send_later_enqueue_args(:gsub, { no_delay: true }, /./, "!")).to be_truthy
      }
      batch_jobs = Delayed::Job.find_available(5)
      regular_jobs = Delayed::Job.list_jobs(:future, 5)
      expect(regular_jobs.size).to eq 1
      expect(regular_jobs.first.batch?).to eq false
      expect(batch_jobs.size).to eq 1
      batch_job = batch_jobs.first
      expect(batch_job.batch?).to eq true
      expect(batch_job.payload_object.mode).to  eq :serial
      expect(batch_job.payload_object.jobs.map { |j| [j.payload_object.object, j.payload_object.method, j.payload_object.args] }).to  eq [
        ["string", :size, []],
        ["string", :gsub, [/./, "!"]]
      ]
    end

    it "should not let you invoke it directly" do
      later = 1.hour.from_now
      Delayed::Batch.serial_batch {
        expect("string".send_later_enqueue_args(:size, no_delay: true)).to be true
        expect("string".send_later_enqueue_args(:gsub, { no_delay: true }, /./, "!")).to be true
      }
      expect(Delayed::Job.jobs_count(:current)).to eq 1
      job = Delayed::Job.find_available(1).first
      expect{ job.invoke_job }.to raise_error
    end

    it "should create valid jobs" do
      Delayed::Batch.serial_batch {
        expect("string".send_later_enqueue_args(:size, no_delay: true)).to be true
        expect("string".send_later_enqueue_args(:gsub, { no_delay: true }, /./, "!")).to be true
      }
      expect(Delayed::Job.jobs_count(:current)).to eq 1

      batch_job = Delayed::Job.find_available(1).first
      expect(batch_job.batch?).to eq true
      jobs = batch_job.payload_object.jobs
      expect(jobs.size).to eq 2
      expect(jobs[0]).to be_new_record
      expect(jobs[0].payload_object.class).to   eq Delayed::PerformableMethod
      expect(jobs[0].payload_object.method).to  eq :size
      expect(jobs[0].payload_object.args).to    eq []
      expect(jobs[0].payload_object.perform).to eq 6
      expect(jobs[1]).to be_new_record
      expect(jobs[1].payload_object.class).to   eq Delayed::PerformableMethod
      expect(jobs[1].payload_object.method).to  eq :gsub
      expect(jobs[1].payload_object.args).to    eq [/./, "!"]
      expect(jobs[1].payload_object.perform).to eq "!!!!!!"
    end

    it "should create a different batch for each priority" do
      later = 1.hour.from_now
      Delayed::Batch.serial_batch {
        expect("string".send_later_enqueue_args(:size, :priority => Delayed::LOW_PRIORITY, :no_delay => true)).to be true
        expect("string".send_later_enqueue_args(:gsub, { :no_delay => true }, /./, "!")).to be true
      }
      expect(Delayed::Job.jobs_count(:current)).to eq 2
    end

    it "should use the given priority for all, if specified" do
      Delayed::Batch.serial_batch(:priority => 11) {
        expect("string".send_later_enqueue_args(:size, :priority => 20, :no_delay => true)).to be true
        expect("string".send_later_enqueue_args(:gsub, { :priority => 15, :no_delay => true }, /./, "!")).to be true
      }
      expect(Delayed::Job.jobs_count(:current)).to eq 1
      expect(Delayed::Job.find_available(1).first.priority).to eq 11
    end

    it "should just create the job, if there's only one in the batch" do
      Delayed::Batch.serial_batch(:priority => 11) {
        expect("string".send_later_enqueue_args(:size, no_delay: true)).to be true
      }
      expect(Delayed::Job.jobs_count(:current)).to eq 1
      expect(Delayed::Job.find_available(1).first.tag).to eq "String#size"
      expect(Delayed::Job.find_available(1).first.priority).to eq 11
    end
  end

  shared_examples_for "delayed_jobs_shards" do
    it "should keep track of the current shard on child jobs" do
      shard = @shard1 || Shard.default
      shard.activate do
        Delayed::Batch.serial_batch {
          expect("string".send_later_enqueue_args(:size, no_delay: true)).to be true
          expect("string".send_later_enqueue_args(:gsub, { no_delay: true }, /./, "!")).to be true
        }
      end
      job = Delayed::Job.find_available(1).first
      expect(job.current_shard).to eq shard
      expect(job.payload_object.jobs.first.current_shard).to eq shard
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
