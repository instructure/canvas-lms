require File.expand_path('../sharding_spec_helper', File.dirname( __FILE__ ))

describe 'Delayed::Job' do
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
