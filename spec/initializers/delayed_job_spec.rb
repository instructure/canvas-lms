#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../sharding_spec_helper', File.dirname( __FILE__ ))

describe 'Delayed::Job' do
  it "should define job.account" do
    job = Delayed::Job.create
    expect(job).to respond_to(:account)
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
