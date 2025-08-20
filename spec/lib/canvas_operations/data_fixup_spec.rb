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

RSpec.describe CanvasOperations::DataFixup do
  before do
    allow_any_instance_of(described_class).to receive(:wait_between_jobs)
    allow_any_instance_of(described_class).to receive(:wait_between_processing)
  end

  shared_context "batch data fixup" do
    before do
      stub_const("BatchDataFixup", Class.new(described_class) do
        self.mode = :batch
        scope { User.all }

        def process_batch(records)
          records.update_all(name: "Fixed User")
        end
      end)
    end
  end

  shared_context "individual record data fixup" do
    before do
      stub_const("IndividualRecordDataFixup", Class.new(described_class) do
        self.mode = :individual_record
        scope { User.all }

        def process_record(record)
          record.update!(name: "Fixed User")
        end
      end)
    end
  end

  describe "settings" do
    it "includes settings for batching and sleeping" do
      expect(described_class.range_batch_size).to eq(5_000)
      expect(described_class.job_scheduled_sleep_time).to eq(0.25)
      expect(described_class.processing_sleep_time).to eq(0.1)
    end
  end

  describe "#run" do
    subject(:run_fixup) { fixup_instance.run(nil) }

    let(:fixup_instance) { BatchDataFixup.new }

    specs_require_sharding
    include_context "batch data fixup"

    before { BatchDataFixup.range_batch_size = 1 }

    context "when the current shard is the default shard" do
      it "does not execute the fixup" do
        expect(fixup_instance).not_to receive(:execute)

        run_fixup
      end
    end

    context "on a non-default shard" do
      around do |example|
        @shard2.activate do
          example.run
        end
      end

      it "iterates over the scope in ranges of the configured batch size" do
        expect(User).to receive(:find_ids_in_ranges).with(
          batch_size: BatchDataFixup.range_batch_size,
          loose: true
        ).and_call_original

        run_fixup
      end

      it "enqueues jobs to process each ID range where there are matching rows" do
        user_one = user_model
        user_two = User.create!(
          id: user_one.id + 10,
          name: "User Two"
        )

        job_scope = Delayed::Job.where(tag: "BatchDataFixup#process_range").order(created_at: :asc)

        expect(BatchDataFixup.range_batch_size).to eq 1
        # Batch size is 1 for this test. Despite there being a gap of 9 IDs between the two users,
        # we only expect jobs to get enqueued if the batch contains a matching row.
        expect { fixup_instance.send(:execute) }.to change { job_scope.count }.from(0).to(2)

        id_ranges = job_scope.each.map do |job|
          job_args = job.payload_object.args

          job_args.first..job_args.last
        end

        # The ranges provided to the jobs contain the users
        expect(id_ranges.length).to eq 2
        expect(id_ranges.first).to include(user_one.id)
        expect(id_ranges.second).to include(user_two.id)
      end

      it "invokes the batch processing handler for each batch" do
        user_one = user_model
        user_two = User.create!(
          id: user_one.id + 10,
          name: "User Two"
        )

        expect(user_one.name).not_to eq("Fixed User")
        expect(user_two.name).not_to eq("Fixed User")

        run_fixup
        run_jobs

        expect(user_one.reload.name).to eq("Fixed User")
        expect(user_two.reload.name).to eq("Fixed User")
      end

      context "when mode is :individual_record" do
        include_context "individual record data fixup"

        let!(:user_one) { user_model }
        let!(:user_two) { user_model }

        let(:fixup_instance) { IndividualRecordDataFixup.new }

        it "fixes up the data" do
          expect(user_one.name).not_to eq("Fixed User")
          expect(user_two.name).not_to eq("Fixed User")

          run_fixup
          run_jobs

          expect(user_one.reload.name).to eq("Fixed User")
          expect(user_two.reload.name).to eq("Fixed User")
        end

        it "invokes the individual record processing handler for each record" do
          expect_any_instance_of(fixup_instance.class).to receive(:process_record).once.with(user_one)
          expect_any_instance_of(fixup_instance.class).to receive(:process_record).once.with(user_two)

          run_fixup
          run_jobs
        end
      end

      context "when no mode is set" do
        it "raises CanvasOperations::Errors::InvalidDataFixupModeError" do
          expect do
            stub_const("NoModeDataFixup", Class.new(described_class) do
              self.mode = :banana

              scope { User.all }
            end)
          end.to raise_error(CanvasOperations::Errors::InvalidPropertyValue)
        end
      end
    end
  end
end
