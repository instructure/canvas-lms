# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
#

describe ContentExport do
  before :once do
    course_with_teacher(active_all: true)
    @ce = @course.content_exports.create!
  end

  def create_content_export(opts = {})
    course = course_model
    allow(course).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)
    ContentExport.new({ context: course }.merge(opts))
  end

  it "records the job id" do
    allow(Delayed::Worker).to receive(:current_job).and_return(double("Delayed::Job", id: 123))
    @ce.export(synchronous: true)
    expect(@ce.reload.settings[:job_id]).to eq(123)
  end

  it "logs duration on export success" do
    allow(InstStatsd::Statsd).to receive(:timing)
    @ce.export(synchronous: true)
    expect(InstStatsd::Statsd).to have_received(:timing).with("content_migrations.export_duration", anything, {
                                                                tags: { export_type: nil, selective_export: false }
                                                              }).once
  end

  context "export_object?" do
    it "returns true for everything if there are no copy options" do
      expect(@ce.export_object?(@ce)).to be true
    end

    it "returns true for everything if 'everything' is selected" do
      @ce.selected_content = { everything: "1" }
      expect(@ce.export_object?(@ce)).to be true
    end

    it "returns false for nil objects" do
      expect(@ce.export_object?(nil)).to be false
    end

    it "returns true for all object types if the all_ option is true" do
      @ce.selected_content = { all_content_exports: "1" }
      expect(@ce.export_object?(@ce)).to be true
    end

    it "returns false for objects not selected" do
      @ce.save!
      @ce.selected_content = { all_content_exports: "0" }
      expect(@ce.export_object?(@ce)).to be false
      @ce.selected_content = { content_exports: {} }
      expect(@ce.export_object?(@ce)).to be false
      @ce.selected_content = { content_exports: { CC::CCHelper.create_key(@ce) => "0" } }
      expect(@ce.export_object?(@ce)).to be false
    end

    it "returns true for selected objects" do
      @ce.save!
      @ce.selected_content = { content_exports: { CC::CCHelper.create_key(@ce) => "1" } }
      expect(@ce.export_object?(@ce)).to be true
    end
  end

  context "Quizzes2 Export" do
    before :once do
      quiz = @course.quizzes.create!(title: "quiz1")
      Account.default.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @ce = @course.content_exports.create!(
        export_type: ContentExport::QUIZZES2,
        selected_content: quiz.id,
        user: @user
      )
      @course.root_account.settings[:provision] = { "lti" => "lti url" }
      @course.root_account.save!
    end

    describe "quiz migration alerts" do
      context "new quizzes bank migrations is enabled" do
        before do
          @course.enable_feature!(:quizzes_next)
          allow(@ce).to receive(:new_quizzes_bank_migration_enabled?).and_return(true)
          allow(NewQuizzesFeaturesHelper).to receive(:new_quizzes_bank_migrations_enabled?).and_return(true)
        end

        it "creates a quiz migration alert for the user and course" do
          expect do
            @ce.export(synchronous: true)
          end.to change { QuizMigrationAlert.count }
            .from(0).to(1)
            .and change { @user.quiz_migration_alerts.count }
            .from(0).to(1)
        end

        it "does not crete multiple quiz migration alerts when 'export' runs multiple times" do
          expect do
            2.times do
              @ce.export(synchronous: true)
            end
          end.to change { QuizMigrationAlert.count }
            .from(0).to(1)
            .and change { @user.quiz_migration_alerts.count }
            .from(0).to(1)
        end
      end

      context "new quizzes bank migrations is not enabled" do
        before do
          @course.enable_feature!(:quizzes_next)
        end

        it "does not produce quiz migration alerts" do
          expect { @ce.export(synchronous: true) }.not_to change { QuizMigrationAlert.count }
        end
      end
    end

    it "changes the workflow_state when :quizzes_next is enabled" do
      @course.enable_feature!(:quizzes_next)
      expect { @ce.export(synchronous: true) }.to change { @ce.workflow_state }
      expect(@ce.workflow_state).to eq "exported"
    end

    it "fails the content export when :quizzes_next is disabled" do
      @course.disable_feature!(:quizzes_next)
      @ce.export(synchronous: true)
      expect(@ce.workflow_state).to eq "created"
    end

    it "composes the payload with assignment details" do
      @course.enable_feature!(:quizzes_next)
      @ce.export(synchronous: true)
      expect(@ce.settings[:quizzes2][:assignment]).not_to be_empty
    end

    it "composes the payload with course UUID" do
      @course.enable_feature!(:quizzes_next)
      @ce.export(synchronous: true)
      expect(@ce.settings[:quizzes2][:assignment][:course_uuid]).to eq(@course.uuid)
    end

    it "composes the payload with qti details" do
      @course.enable_feature!(:quizzes_next)
      @ce.export(synchronous: true)
      expect(@ce.settings[:quizzes2][:qti_export][:url]).to eq(@ce.attachment.public_download_url)
    end

    it "composes the payload with account banks flag if new_quizzes_bank_migration_enabled? returns true" do
      @course.enable_feature!(:quizzes_next)
      allow(@ce).to receive(:new_quizzes_bank_migration_enabled?).and_return(true)
      @ce.export(synchronous: true)
      expect(@ce.settings[:selected_content]["all_#{AssessmentQuestionBank.table_name}"]).to be true
    end

    it "composes the payload without account banks flag if new_quizzes_bank_migration_enabled? returns false" do
      allow(@ce).to receive(:new_quizzes_bank_migration_enabled?).and_return(false)
      @ce.export(synchronous: true)
      expect(@ce.settings[:selected_content].class.to_s).to eq("Integer")
    end

    it "completes with export_type of 'quizzes2'" do
      @course.enable_feature!(:quizzes_next)
      @ce.export(synchronous: true)
      expect(@ce.export_type).to eq("quizzes2")
    end

    context "failure cases" do
      it "fails if the quiz exporter fails" do
        @course.enable_feature!(:quizzes_next)
        allow_any_instance_of(Exporters::Quizzes2Exporter).to receive(:export).and_return(false)
        @ce.export(synchronous: true)
        expect(@ce.workflow_state).to eq "failed"
      end

      it "fails if the qti exporter fails" do
        @course.enable_feature!(:quizzes_next)
        allow_any_instance_of(CC::CCExporter).to receive(:export).and_return(false)
        @ce.export(synchronous: true)
        expect(@ce.workflow_state).to eq "failed"
      end
    end

    context "when newquizzes_on_quiz_page is enabled" do
      before do
        @course.enable_feature!(:quizzes_next)
        @course.root_account.enable_feature!(:newquizzes_on_quiz_page)
      end

      it "sets up assignment and content_export settings" do
        expect(@ce).to receive(:export)
        @ce.queue_api_job({})
        expect(@ce.settings["quizzes2"]).not_to be_nil
        assignment_id = @ce.settings["quizzes2"]["assignment"]["assignment_id"]
        assignment = Assignment.find_by(id: assignment_id)
        expect(assignment).not_to be_nil
      end

      # CC export is the first step of Quiz migration
      # Canvas then sends live events to N.Q
      # N.Q finally imports the CC package
      it "completes CC export for new quizzes migration" do
        cc_exporter = CC::CCExporter.new(@ce)
        expect(CC::CCExporter).to receive(:new).and_return(cc_exporter)
        expect(cc_exporter).to receive(:export).and_call_original
        @ce.quizzes2_build_assignment
        @ce.export(synchronous: true)
        expect(@ce.settings[:quizzes2][:qti_export][:url]).to eq(@ce.attachment.public_download_url)
        expect(@ce.export_type).to eq("quizzes2")
      end

      it "marks failure if CC export is failed" do
        cc_exporter = CC::CCExporter.new(@ce)
        expect(CC::CCExporter).to receive(:new).and_return(cc_exporter)
        # CC exporter fails and returns false
        expect(cc_exporter).to receive(:export).and_return(false)
        @ce.quizzes2_build_assignment
        assignment_id = @ce.settings["quizzes2"]["assignment"]["assignment_id"]
        @ce.export(synchronous: true)
        assignment = Assignment.find_by(id: assignment_id)
        expect(assignment.workflow_state).to eq("failed_to_migrate")
        expect(@ce.workflow_state).to eq("failed")
      end

      context "when failed assignment is provided" do
        let(:failed_assignment) do
          @course.assignments.create!(
            position: 777,
            assignment_group:
          )
        end

        let(:assignment_group) do
          @course.assignment_groups.create!(name: "group_123")
        end

        it "creates assignment with expected group and position" do
          @ce.quizzes2_build_assignment(failed_assignment_id: failed_assignment.id)
          expect(@ce.settings[:quizzes2][:assignment]).not_to be_empty
          assignment_id = @ce.settings[:quizzes2][:assignment][:assignment_id]
          assignment = Assignment.find(assignment_id)
          expect(assignment.position).to be(777)
          expect(assignment.assignment_group.id).to be(assignment_group.id)
        end
      end
    end
  end

  context "add_item_to_export" do
    it "does not add nil" do
      @ce.add_item_to_export(nil)
      expect(@ce.selected_content).to be_empty
    end

    it "only adds data model objects" do
      @ce.add_item_to_export("hi")
      expect(@ce.selected_content).to be_empty

      @ce.selected_content = { assignments: nil }
      @ce.save!

      assignment_model
      @ce.add_item_to_export(@assignment)
      expect(@ce.selected_content[:assignments]).not_to be_empty
    end

    it "does not add objects if everything is already set" do
      assignment_model
      @ce.add_item_to_export(@assignment)
      expect(@ce.selected_content).to be_empty

      @ce.selected_content = { everything: 1 }
      @ce.save!

      @ce.add_item_to_export(@assignment)
      expect(@ce.selected_content.keys.map(&:to_s)).to eq ["everything"]
    end
  end

  context "notifications" do
    before :once do
      @ce.update_attribute(:user_id, @user.id)
      Notification.create!(name: "Content Export Finished", category: "Migration")
      Notification.create!(name: "Content Export Failed", category: "Migration")
    end

    it "sends notifications immediately" do
      communication_channel_model.confirm!

      %w[created exporting exported_for_course_copy deleted].each do |workflow|
        @ce.workflow_state = workflow
        expect { @ce.save! }.not_to change(DelayedMessage, :count)
        expect(@ce.messages_sent["Content Export Finished"]).to be_blank
        expect(@ce.messages_sent["Content Export Failed"]).to be_blank
      end

      @ce.workflow_state = "exported"
      expect { @ce.save! }.not_to change(DelayedMessage, :count)
      expect(@ce.messages_sent["Content Export Finished"]).not_to be_blank

      @ce.workflow_state = "failed"
      expect { @ce.save! }.not_to change(DelayedMessage, :count)
      expect(@ce.messages_sent["Content Export Failed"]).not_to be_blank
    end

    it "does not send emails as part of a content migration (course copy)" do
      @cm = ContentMigration.new(user: @user, copy_options: { everything: "1" }, context: @course)
      @ce.content_migration = @cm
      @ce.save!

      @ce.workflow_state = "exported"
      expect { @ce.save! }.not_to change(DelayedMessage, :count)
      expect(@ce.messages_sent["Content Export Finished"]).to be_blank

      @ce.workflow_state = "failed"
      expect { @ce.save! }.not_to change(DelayedMessage, :count)
      expect(@ce.messages_sent["Content Export Failed"]).to be_blank
    end
  end

  describe "#expired?" do
    it "marks as expired after X days" do
      ContentExport.where(id: @ce.id).update_all(created_at: 35.days.ago)
      expect(@ce.reload).to be_expired
    end

    it "does not mark new exports as expired" do
      expect(@ce.reload).not_to be_expired
    end

    it "does not mark as expired if setting is 0" do
      Setting.set("content_exports_expire_after_days", "0")
      ContentExport.where(id: @ce.id).update_all(created_at: 35.days.ago)
      expect(@ce.reload).not_to be_expired
    end

    it "does not mark expired if part of a ContentShare" do
      @teacher.sent_content_shares.create!(read_state: "read", name: "test", content_export_id: @ce.id)
      ContentExport.where(id: @ce.id).update_all(created_at: 35.days.ago, user_id: @teacher.id)
      expect(@ce.reload).not_to be_expired
    end
  end

  describe "#expired" do
    it "marks as expired after X days" do
      ContentExport.where(id: @ce.id).update_all(created_at: 35.days.ago)
      expect(ContentExport.expired.pluck(:id)).to eq [@ce.id]
    end

    it "does not mark new exports as expired" do
      expect(ContentExport.expired.pluck(:id)).to be_empty
    end

    it "does not mark as expired if setting is 0" do
      Setting.set("content_exports_expire_after_days", "0")
      ContentExport.where(id: @ce.id).update_all(created_at: 35.days.ago)
      expect(ContentExport.expired.pluck(:id)).to be_empty
    end
  end

  context "global_identifiers" do
    it "is automatically set to true" do
      cc_export = @course.content_exports.create!(export_type: ContentExport::COURSE_COPY)
      expect(cc_export.global_identifiers).to be true
    end

    it "does not set if there are any other exports in the context that weren't set" do
      prev_export = @course.content_exports.create!(export_type: ContentExport::COURSE_COPY)
      prev_export.update_attribute(:global_identifiers, false)
      cc_export = @course.content_exports.create!(export_type: ContentExport::COURSE_COPY)
      expect(cc_export.global_identifiers).to be false
    end

    it "uses global asset strings for keys if set" do
      export = @course.content_exports.create!(export_type: ContentExport::COURSE_COPY)
      a = @course.assignments.create!
      expect(a).to receive(:global_asset_string).once.and_call_original
      export.create_key(a)
    end

    it "uses local asset strings for keys if not set" do
      export = @course.content_exports.create!(export_type: ContentExport::COURSE_COPY)
      export.update_attribute(:global_identifiers, false)
      a = @course.assignments.create!
      expect(a).to receive(:asset_string).once.and_call_original
      export.create_key(a)
    end
  end

  describe "#disable_content_rewriting?" do
    subject { content_export.disable_content_rewriting? }

    context "quizzes_next export" do
      let(:content_export) { create_content_export(export_type: ContentExport::QUIZZES2, settings: { quizzes2: {} }) }

      context "content rewrite is enabled" do
        before do
          allow(NewQuizzesFeaturesHelper).to receive(:disable_content_rewriting?).and_return false
        end

        it { is_expected.to be false }
      end

      context "content rewrite is disabled" do
        before do
          allow(NewQuizzesFeaturesHelper).to receive(:disable_content_rewriting?).and_return true
        end

        it { is_expected.to be true }
      end
    end

    context "non-quizzes_next export" do
      let(:content_export) { create_content_export(export_type: ContentExport::COURSE_COPY) }

      context "content rewrite is enabled" do
        before do
          allow(NewQuizzesFeaturesHelper).to receive(:disable_content_rewriting?).and_return false
        end

        it { is_expected.to be false }
      end

      context "content rewrite is disabled" do
        before do
          allow(NewQuizzesFeaturesHelper).to receive(:disable_content_rewriting?).and_return true
        end

        it { is_expected.to be false }
      end
    end
  end

  describe "common_cartridge" do
    before :once do
      assignment_model(submission_types: "external_tool", course: @course)
      tool = @c.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @a.external_tool_tag_attributes = { content: tool }
      @a.save!

      @course.root_account.settings[:provision] = { "lti" => "lti url" }
      @course.root_account.save!
      @ce = @course.content_exports.create!
    end

    context "with feature flags enabled" do
      before do
        allow(NewQuizzesFeaturesHelper).to receive(:new_quizzes_common_cartridge_enabled?).and_return(true)
      end

      it "should not have :contains_new_quizzes in the settings" do
        expect(@ce.settings[:contains_new_quizzes]).to be_nil
      end

      context "when setting the contains_new_quizzes" do
        before do
          @ce.set_contains_new_quizzes_settings
        end

        context "when the course has New Quizzes assignments" do
          it "the settings to contains_new_quizzes should be set to true" do
            expect(@ce.settings[:contains_new_quizzes]).to be true
          end
        end

        context "when the course does not have New Quizzes assignments" do
          before do
            @another_course = course_model
            @ce = @another_course.content_exports.create!
            @ce.set_contains_new_quizzes_settings
          end

          it "the settings to contains_new_quizzes should be set to false" do
            expect(@ce.settings[:contains_new_quizzes]).to be false
          end
        end
      end
    end

    context "with feature flags disabled" do
      before do
        @ce.set_contains_new_quizzes_settings
      end

      context "when the course has New Quizzes assignments" do
        it "does not contain new quizzes in the export" do
          expect(@ce.settings[:contains_new_quizzes]).to be false
        end
      end

      context "when the course does not have New Quizzes assignments" do
        before do
          @another_course = course_model
          @ce = @another_course.content_exports.create!
          @ce.set_contains_new_quizzes_settings
        end

        it "should not contain a New Quiz in the export" do
          expect(@ce.settings[:contains_new_quizzes]).to be false
        end
      end
    end
  end

  describe "#mark_waiting_for_external_tool" do
    let(:content_export) do
      create_content_export(export_type: ContentExport::COURSE_COPY, workflow_state: "created")
    end

    it "transitions to waiting_for_external_tool" do
      expect { content_export.mark_waiting_for_external_tool }.to change { content_export.workflow_state }
        .from("created").to("waiting_for_external_tool")
    end
  end

  describe "set new quizzes export settings on save" do
    context "when the export_type is 'common_cartridge'" do
      let(:content_export) { create_content_export(export_type: ContentExport::COMMON_CARTRIDGE, settings: {}) }

      context "and is updated with new quizzes export settings" do
        it "sets appropriate settings" do
          content_export.update!(new_quizzes_export_url: "https://some.url", new_quizzes_export_state: "completed")
          expect(content_export.settings[:new_quizzes_export_url]).to eq("https://some.url")
          expect(content_export.settings[:new_quizzes_export_state]).to eq("completed")
        end
      end

      context "and new_quizzes_export_state is not provided on update" do
        it "does not set new quizzes export settings" do
          content_export.update!(new_quizzes_export_url: "https://some.url")
          expect(content_export.settings[:new_quizzes_export_url]).to be_nil
          expect(content_export.settings[:new_quizzes_export_state]).to be_nil
        end
      end

      context "and new_quizzes_export_state is provided on update" do
        it "sets appropriate settings even with new_quizzes_export_url set as nil" do
          content_export.update!(new_quizzes_export_state: "failed")

          expect(content_export.settings[:new_quizzes_export_state]).to eq "failed"
          expect(content_export.settings[:new_quizzes_export_url]).to be_nil
        end
      end
    end

    context "when the export_type is not 'common_cartridge'" do
      let(:content_export) { create_content_export(export_type: ContentExport::COURSE_COPY, settings: {}) }

      context "and is updated with new quizzes export settings" do
        it "does not set new quizzes export settings" do
          content_export.update!(new_quizzes_export_url: "https://some.url", new_quizzes_export_state: "completed")
          expect(content_export.settings[:new_quizzes_export_url]).to be_nil
          expect(content_export.settings[:new_quizzes_export_state]).to be_nil
        end
      end
    end
  end
end
