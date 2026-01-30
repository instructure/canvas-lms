# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.describe CanvasOperations::RootAccountOperation do
  specs_require_sharding

  let(:root_account) { account_model }

  shared_context "simple root account operation" do
    before do
      stub_const("MyRootAccountOperation", Class.new(described_class) do
        def execute
          log_message("Executing MyRootAccountOperation for account #{root_account.global_id}")
          results[:account_id] = root_account.global_id
        end
      end)
    end
  end

  describe "#initialize" do
    include_context "simple root account operation"

    let(:operation_instance) { MyRootAccountOperation.new(root_account:) }

    it "sets the root_account" do
      expect(operation_instance.root_account).to eq(root_account)
    end

    it "sets the switchman_shard to the root account's shard" do
      expect(operation_instance.switchman_shard).to eq(root_account.shard)
    end

    context "when root account is on a different shard" do
      it "uses the root account's shard" do
        account = @shard1.activate { Account.create! }
        operation = MyRootAccountOperation.new(root_account: account)

        expect(operation.switchman_shard).to eq(account.shard)
        expect(operation.root_account).to eq(account)
      end
    end
  end

  describe "#run_later" do
    include_context "simple root account operation"

    let(:operation_instance) { MyRootAccountOperation.new(root_account:) }

    it "executes the operation successfully" do
      operation_instance.run_later

      job = Delayed::Job.find_by(
        singleton: "operations/my_root_account_operation/shards/#{root_account.shard.id}/accounts/#{root_account.global_id}"
      )
      expect(job).to be_present
      expect(job.shard).to eq(root_account.shard)
      expect(job.account).to eq(root_account)

      run_jobs

      progress = operation_instance.send(:progress).reload
      expect(progress).to be_present
      expect(progress.workflow_state).to eq("completed")
      expect(progress.results[:account_id]).to eq(root_account.global_id)
    end

    it "enqueues the operation with correct singleton including account ID" do
      operation_instance.run_later

      job = Delayed::Job.find_by(
        singleton: "operations/my_root_account_operation/shards/#{root_account.shard.id}/accounts/#{root_account.global_id}"
      )
      expect(job).to be_present
    end
  end

  describe "#singleton" do
    include_context "simple root account operation"

    let(:operation_instance) { MyRootAccountOperation.new(root_account:) }

    it "includes the shard ID and root account global ID" do
      expect(operation_instance.send(:singleton)).to eq("shards/#{root_account.shard.id}/accounts/#{root_account.global_id}")
    end

    context "when operations are created for different accounts" do
      it "generates different singleton values" do
        account1 = Account.create!
        account2 = Account.create!
        operation1 = MyRootAccountOperation.new(root_account: account1)
        operation2 = MyRootAccountOperation.new(root_account: account2)

        expect(operation1.send(:singleton)).not_to eq(operation2.send(:singleton))
      end
    end

    context "when operations are created for the same account" do
      it "generates the same singleton value" do
        operation1 = MyRootAccountOperation.new(root_account:)
        operation2 = MyRootAccountOperation.new(root_account:)

        expect(operation1.send(:singleton)).to eq(operation2.send(:singleton))
      end
    end
  end

  describe "#context" do
    include_context "simple root account operation"

    let(:operation_instance) { MyRootAccountOperation.new(root_account:) }

    it "returns the root account" do
      expect(operation_instance.send(:context)).to eq(root_account)
    end
  end

  describe "#run" do
    include_context "simple root account operation"

    let(:operation_instance) { MyRootAccountOperation.new(root_account:) }

    it "executes the operation in the context of the root account" do
      operation_instance.run

      expect(operation_instance.results[:account_id]).to eq(root_account.global_id)
      progress = operation_instance.send(:progress)
      expect(progress.context).to eq(root_account)
    end

    it "runs on the correct shard" do
      account = @shard1.activate { account_model }
      operation = MyRootAccountOperation.new(root_account: account)

      @shard1.activate do
        operation.run
      end

      expect(operation.results[:account_id]).to eq(account.global_id)
      progress = @shard1.activate { operation.send(:progress) }
      expect(progress.context).to eq(account)
    end

    it "fails to runs if not on the correct shard" do
      account = @shard1.activate { account_model }
      operation = MyRootAccountOperation.new(root_account: account)

      expect do
        @shard2.activate do
          operation.run
        end
      end.to raise_error(CanvasOperations::Errors::WrongShard)

      progress = operation.send(:progress).reload
      expect(progress.context).to eq(account)

      # The reason this is queued is that we do not fail the progress because it might not be
      # safe to do so if we are on the wrong shard.
      expect(progress.workflow_state).to eq("queued")
    end
  end

  describe "parallel execution for different accounts" do
    include_context "simple root account operation"

    it "allows concurrent jobs for different accounts" do
      account1 = account_model
      account2 = account_model
      operation1 = MyRootAccountOperation.new(root_account: account1)
      operation2 = MyRootAccountOperation.new(root_account: account2)

      expect do
        operation1.run_later
        operation2.run_later
      end.to change(Delayed::Job, :count).by(2)

      jobs = Delayed::Job.where("singleton LIKE 'operations/my_root_account_operation%'")
      expect(jobs.pluck(:singleton)).to contain_exactly(
        "operations/my_root_account_operation/shards/#{account1.shard.id}/accounts/#{account1.global_id}",
        "operations/my_root_account_operation/shards/#{account2.shard.id}/accounts/#{account2.global_id}"
      )

      job1 = jobs.find_by("singleton LIKE '%accounts/#{account1.global_id}'")
      expect(job1.shard).to eq(account1.shard)
      expect(job1.account).to eq(account1)

      job2 = jobs.find_by("singleton LIKE '%accounts/#{account2.global_id}'")
      expect(job2.shard).to eq(account2.shard)
      expect(job2.account).to eq(account2)
    end

    it "prevents duplicate jobs for the same account" do
      operation1 = MyRootAccountOperation.new(root_account:)
      operation2 = MyRootAccountOperation.new(root_account:)

      expect do
        operation1.run_later
        operation2.run_later
      end.to change(Delayed::Job, :count).by(1)

      jobs = Delayed::Job.where("singleton LIKE 'operations/my_root_account_operation%'")
      expect(jobs.count).to eq(1)
      expect(jobs.first.singleton).to eq("operations/my_root_account_operation/shards/#{root_account.shard.id}/accounts/#{root_account.global_id}")
      expect(jobs.first.shard).to eq(root_account.shard)
      expect(jobs.first.account).to eq(root_account)
    end
  end
end
