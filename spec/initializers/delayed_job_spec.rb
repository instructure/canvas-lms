# frozen_string_literal: true

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

describe "Delayed::Job" do
  it "defines job.account" do
    job = Delayed::Job.new
    expect(job).to respond_to(:account)
  end

  shared_examples_for "delayed_jobs_shards" do
    it "keeps track of the current shard on child jobs" do
      shard = @shard1 || Shard.default
      shard.activate do
        Delayed::Batch.serial_batch do
          expect("string".delay(ignore_transaction: true).size).to be true
          expect("string".delay(ignore_transaction: true).gsub(/./, "!")).to be true
        end
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

  describe "log format" do
    specs_require_sharding
    it "defines a useful detailed log format" do
      @shard1.activate do
        account = account_model
        job = Delayed::Job.new(priority: 20, created_at: Time.zone.now, strand: "test", account_id: account.id)
        job.current_shard = @shard1
        log_hash = JSON.parse(job.to_detailed_log_format).with_indifferent_access
        expect(log_hash["priority"]).to eq(20)
        expect(log_hash["strand"]).to eq("test")
        expect(log_hash["shard_id"]).to eq(@shard1.id)
        expect(log_hash["account_id"]).to eq(account.global_id)
        expect(log_hash["root_account_id"]).to eq(account.global_id)
        expect(log_hash["jobs_cluster"]).to eq(Shard.current.delayed_jobs_shard.id)
        expect(log_hash["db_cluster"]).to eq(Shard.current.database_server.id)
      end
    end

    it "defines a useful short log format" do
      @shard1.activate do
        account = account_model
        job = Delayed::Job.new(priority: 20, created_at: Time.zone.now, strand: "test", account_id: account.id)
        job.current_shard = @shard1
        log_hash = JSON.parse(job.to_short_log_format).with_indifferent_access
        expect(log_hash["shard_id"]).to eq(@shard1.id)
        expect(log_hash["account_id"]).to eq(account.global_id)
        expect(log_hash["root_account_id"]).to eq(account.global_id)
        expect(log_hash["jobs_cluster"]).to eq(Shard.current.delayed_jobs_shard.id)
        expect(log_hash["db_cluster"]).to eq(Shard.current.database_server.id)
      end
    end

    it "is resiliant to unexpected data" do
      job = Delayed::Job.new(priority: 20, created_at: Time.zone.now, strand: "test", account_id: 12_345)
      log_hash = JSON.parse(job.to_detailed_log_format).with_indifferent_access
      expect(log_hash["priority"]).to eq(20)
      expect(log_hash["strand"]).to eq("test")
      expect(log_hash["shard_id"]).to eq(Shard.current.id)
      expect(log_hash["account_id"]).to eq(12_345)
      expect(log_hash["root_account_id"]).to be_nil
      expect(log_hash["jobs_cluster"]).to eq(Shard.current.delayed_jobs_shard.id)
      expect(log_hash["db_cluster"]).to eq(Shard.current.database_server.id)
    end
  end
end
