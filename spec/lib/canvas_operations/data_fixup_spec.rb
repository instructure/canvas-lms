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
        self.progress_tracking = false

        scope { User.all }

        def process_batch(records)
          records.update_all(name: "Fixed User")
        end
      end)
    end
  end

  shared_context "batch data fixup that skips the default shard" do
    before do
      stub_const("BatchDataFixup", Class.new(described_class) do
        self.mode = :batch
        self.progress_tracking = false
        self.run_on_default_shard = false

        scope { User.all }

        def process_batch(records)
          records.update_all(name: "Fixed User")
        end
      end)
    end
  end

  shared_context "batch data fixup with recording" do
    before do
      stub_const("BatchDataFixup", Class.new(described_class) do
        self.mode = :batch
        self.record_changes = true
        self.progress_tracking = false

        scope { User.all }

        def process_batch(records)
          records.update_all(name: "Fixed User")
          "Updated #{records.count} users"
        end
      end)
    end
  end

  shared_context "individual record data fixup" do
    before do
      stub_const("IndividualRecordDataFixup", Class.new(described_class) do
        self.mode = :individual_record
        self.progress_tracking = false

        scope { User.all }

        def process_record(record)
          record.update!(name: "Fixed User")
        end
      end)
    end
  end

  shared_context "individual record data fixup with recording" do
    before do
      stub_const("IndividualRecordDataFixup", Class.new(described_class) do
        self.mode = :individual_record
        self.record_changes = true
        self.progress_tracking = false

        scope { User.all }

        def process_record(record)
          record.update!(name: "Fixed User")
          "Fixed user #{record.id}"
        end
      end)
    end
  end

  shared_context "batch data fixup with restrictive scope" do
    before do
      stub_const("RestrictiveScopeDataFixup", Class.new(described_class) do
        self.mode = :batch
        self.progress_tracking = false

        scope { User.where(name: "Target User") }

        def process_batch(records)
          records.update_all(name: "Fixed User")
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

  describe "record_changes setting" do
    it "defaults to false" do
      expect(described_class.record_changes?).to be(false)
    end

    context "when not in test environment" do
      before { allow(Rails.env).to receive(:test?).and_return(false) }

      it "can be set to true" do
        described_class.record_changes = true
        expect(described_class.record_changes?).to be(true)
      end

      it "can be set to false" do
        described_class.record_changes = false
        expect(described_class.record_changes?).to be(false)
      end
    end

    it "raises an error for invalid values" do
      expect do
        described_class.record_changes = "invalid"
      end.to raise_error(CanvasOperations::Errors::InvalidPropertyValue, "record_changes must be a boolean")
    end

    it "returns false in test environment even when set to true" do
      described_class.record_changes = true
      expect(described_class.record_changes?).to be(false)
    end
  end

  describe "required method implementations" do
    describe "#process_batch" do
      it "raises NoMethodError when not implemented for batch mode" do
        fixup_class = Class.new(described_class) do
          self.mode = :batch
          scope { User.all }
        end

        fixup = fixup_class.new
        expect { fixup.send(:process_batch, []) }.to raise_error(NoMethodError, "Subclasses must implement #process_batch when mode is :batch")
      end
    end

    describe "#process_record" do
      it "raises NoMethodError when not implemented for individual_record mode" do
        fixup_class = Class.new(described_class) do
          self.mode = :individual_record
          scope { User.all }
        end

        fixup = fixup_class.new
        record = double("record")
        expect { fixup.send(:process_record, record) }.to raise_error(NoMethodError, "Subclasses must implement #process_record when mode is :individual_record")
      end
    end

    describe "#scope" do
      it "raises NotImplementedError when not defined" do
        fixup_class = Class.new(described_class) do
          self.mode = :batch
        end

        fixup = fixup_class.new
        expect { fixup.send(:scope) }.to raise_error(NotImplementedError, "Subclasses must define scope using `scope { ... }` or implement #scope method")
      end
    end
  end

  describe "#run" do
    subject(:run_fixup) { fixup_instance.run(nil) }

    let(:fixup_instance) { BatchDataFixup.new }

    specs_require_sharding
    include_context "batch data fixup"

    before { BatchDataFixup.range_batch_size = 1 }

    context "when the current shard is the default shard" do
      it "does execute the fixup by default" do
        expect(fixup_instance).to receive(:execute)

        run_fixup
      end

      context "but the fixup is set to skip the default shard" do
        include_context "batch data fixup that skips the default shard"

        it "does not execute the fixup" do
          expect(fixup_instance).not_to receive(:execute)

          run_fixup
        end
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

        allow(Rails.env).to receive(:production?).and_return(true)
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

      context "with restrictive scope" do
        include_context "batch data fixup with restrictive scope"

        before do
          RestrictiveScopeDataFixup.range_batch_size = 1
        end

        it "does not enqueue process_range when process_batch? returns false" do
          # Create users that don't match the restrictive scope (name: "Target User")
          user_one = user_model(name: "User One")
          User.create!(
            id: user_one.id + 10,
            name: "User Two"
          )

          fixup_instance = RestrictiveScopeDataFixup.new
          job_scope = Delayed::Job.where(tag: "RestrictiveScopeDataFixup#process_range")

          allow(Rails.env).to receive(:production?).and_return(true)

          # No jobs should be enqueued because process_batch? will return false
          # since no users in the ID ranges match the scope's where clause
          expect { fixup_instance.send(:execute) }.not_to change { job_scope.count }
        end
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

      context "with record_changes set to true" do
        include_context "individual record data fixup with recording"

        let(:fixup_instance) { IndividualRecordDataFixup.new }

        before do
          allow(described_class).to receive(:auditable_environment?).and_return(true)
          allow(InstFS).to receive(:direct_upload).and_return(SecureRandom.uuid)
        end

        context "when record_changes is true" do
          it "creates attachment audit logs" do
            user_model

            expect(Attachment).to receive(:new).with(
              context: instance_of(Account),
              filename: "instructure_data_fixup/individual_record_data_fixup/shards/#{Shard.current.id}.part0",
              content_type: "text/plain"
            ).and_call_original

            run_fixup
            run_jobs
          end

          it "schedules cleanup jobs for audit attachments" do
            user_model

            expect do
              run_fixup
              run_jobs
            end.to change { Delayed::Job.where(tag: "IndividualRecordDataFixup#delete_audit_attachment").count }.from(0).to(1)

            job = Delayed::Job.find_by(tag: "IndividualRecordDataFixup#delete_audit_attachment")
            expect(job.run_at).to be_within(2.hours).of(90.days.from_now)

            expect_any_instance_of(Attachment).to receive(:destroy_content)
            expect_any_instance_of(Attachment).to receive(:destroy_permanently!)

            job.invoke_job
          end
        end

        context "when record_changes is false" do
          before { IndividualRecordDataFixup.record_changes = false }

          it "does not create attachment audit logs" do
            user_model

            expect(Attachment).not_to receive(:create!)

            run_fixup
            run_jobs
          end

          it "does not write to tempfile" do
            user_model

            expect_any_instance_of(Tempfile).not_to receive(:write)

            run_fixup
            run_jobs
          end
        end

        context "with batch mode auditing" do
          include_context "batch data fixup with recording"

          let(:fixup_instance) { BatchDataFixup.new }

          before do
            BatchDataFixup.range_batch_size = 1
          end

          it "creates attachment audit logs" do
            user_model

            expect(Attachment).to receive(:new).with(
              context: instance_of(Account),
              filename: "instructure_data_fixup/batch_data_fixup/shards/#{Shard.current.id}.part0",
              content_type: "text/plain"
            ).and_call_original

            run_fixup
            run_jobs
          end

          it "schedules cleanup jobs for audit attachments" do
            user_model

            expect do
              run_fixup
              run_jobs
            end.to change { Delayed::Job.where(tag: "BatchDataFixup#delete_audit_attachment").count }.from(0).to(1)
          end
        end
      end
    end
  end
end
