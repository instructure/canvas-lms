# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../../import_helper"
require_relative "../../lti2_spec_helper"

describe "Importing assignments" do
  let(:migration_id) { "ib4834d160d180e2e91572e8b9e3b1bc6" }
  let(:default_input_assignment_hash) do
    {
      "migration_id" => migration_id,
      "assignment_group_migration_id" => "i2bc4b8ea8fac88f1899e5e95d76f3004",
      "grading_standard_migration_id" => nil,
      "rubric_migration_id" => nil,
      "rubric_id" => nil,
      "quiz_migration_id" => nil,
      "workflow_state" => "published",
      "title" => "",
      "grading_type" => "points",
      "submission_types" => "none",
      "peer_reviews" => false,
      "automatic_peer_reviews" => false,
      "muted" => false,
      "due_at" => 1_401_947_999_000,
      "peer_reviews_due_at" => 1_401_947_999_000,
      "position" => 6,
      "peer_review_count" => 0
    }
  end
  let(:date_shift_options_settings) do
    {
      migration_settings: {
        date_shift_options: {
          old_start_date: "2023-01-01",
          old_end_date: "2023-12-31",
          new_start_date: "2024-01-01",
          new_end_date: "2024-12-31"
        }
      }
    }
  end

  describe "assignment field setting" do
    describe "time_zone_edited" do
      context "when time_zone_edited provided" do
        let(:expected_time_zone_edited) { "Mountain Time (US & Canada)" }
        let(:input_hash) { { **default_input_assignment_hash, time_zone_edited: expected_time_zone_edited } }

        it "should set time_zone_edited" do
          course_model
          migration = @course.content_migrations.create!
          Importers::AssignmentImporter.import_from_migration(input_hash, @course, migration)
          assignment = @course.assignments.where(migration_id:).first
          expect(assignment.time_zone_edited).to eq expected_time_zone_edited
        end
      end

      context "when time_zone_edited is missing" do
        let(:input_hash) { { **default_input_assignment_hash } }

        it "should set time_zone_edited" do
          course_model
          migration = @course.content_migrations.create!
          Importers::AssignmentImporter.import_from_migration(input_hash, @course, migration)
          assignment = @course.assignments.where(migration_id:).first
          expect(assignment.time_zone_edited).to be_blank
        end
      end
    end

    describe "import_from_migration date shift saving method" do
      subject { Importers::AssignmentImporter.import_from_migration(default_input_assignment_hash, course, migration, item) }

      let(:course) { course_model }
      let(:migration) { course.content_migrations.create! }
      let(:item) { course.assignments.temp_record }

      context "when FF pre_date_shift_for_assignment_importing enabled" do
        before do
          Account.site_admin.enable_feature!(:pre_date_shift_for_assignment_importing)
        end

        it "should use the try_to_save_with_date_shift method" do
          expect(Importers::AssignmentImporter)
            .to receive(:try_to_save_with_date_shift).with(kind_of(Assignment), migration).and_call_original
          subject
        end

        describe "skip_schedule_peer_reviews" do
          before do
            allow(item).to receive(:skip_schedule_peer_reviews=)
          end

          context "when migration contains date_shift_options" do
            let(:migration) { course.content_migrations.create!(date_shift_options_settings) }

            it "should not set the skip_schedule_peer_reviews before save" do
              expect(item).to_not receive(:skip_schedule_peer_reviews=)
              subject
            end
          end

          context "when migration not contains date_shift_options" do
            it "should not set the skip_schedule_peer_reviews before save" do
              expect(item).to_not receive(:skip_schedule_peer_reviews=)
              subject
            end
          end
        end
      end

      context "when FF pre_date_shift_for_assignment_importing disabled" do
        it "should not use the try_to_save_with_date_shift method" do
          expect(Importers::AssignmentImporter).to_not receive(:try_to_save_with_date_shift)
          subject
        end

        describe "skip_schedule_peer_reviews" do
          before do
            allow(item).to receive(:skip_schedule_peer_reviews=)
          end

          context "when migration contains date_shift_options" do
            let(:migration) { course.content_migrations.create!(date_shift_options_settings) }

            it "should set the skip_schedule_peer_reviews before save" do
              expect(item).to receive(:skip_schedule_peer_reviews=).with(true).ordered
              expect(item).to receive(:skip_schedule_peer_reviews=).with(nil).ordered
              subject
            end
          end

          context "when migration not contains date_shift_options" do
            it "should not set skip_schedule_peer_reviews but cleanup with nil" do
              expect(item).to receive(:skip_schedule_peer_reviews=).with(nil)
              subject
            end
          end
        end
      end
    end
  end

  SYSTEMS.each do |system|
    next unless import_data_exists? system, "assignment"

    it "imports assignments for #{system}" do
      data = get_import_data(system, "assignment")
      context = get_import_context(system)
      migration = context.content_migrations.create!

      data[:assignments_to_import] = {}
      expect do
        expect(Importers::AssignmentImporter.import_from_migration(data, context, migration)).to be_nil
      end.not_to change(Assignment, :count)

      data[:assignments_to_import][data[:migration_id]] = true
      expect do
        Importers::AssignmentImporter.import_from_migration(data, context, migration)
        Importers::AssignmentImporter.import_from_migration(data, context, migration)
      end.to change(Assignment, :count).by(1)
      a = Assignment.where(migration_id: data[:migration_id]).first

      expect(a.title).to eq data[:title]
      expect(a.description).to include(data[:instructions]) if data[:instructions]
      expect(a.description).to include(data[:description]) if data[:description]
      a.due_at = Time.zone.at(data[:due_date].to_i / 1000)
      expect(a.points_possible).to eq data[:grading][:points_possible].to_f
    end
  end

  it "imports grading information when rubric is included" do
    file_data = get_import_data("", "assignment")
    context = get_import_context("")
    migration = context.content_migrations.create!

    assignment_hash = file_data.find { |h| h["migration_id"] == "4469882339231" }.with_indifferent_access

    rubric = rubric_model(context:)
    rubric.migration_id = assignment_hash[:grading][:rubric_id]
    rubric.points_possible = 42
    rubric.save!

    Importers::AssignmentImporter.import_from_migration(assignment_hash, context, migration)
    a = Assignment.where(migration_id: assignment_hash[:migration_id]).first
    expect(a.points_possible).to eq rubric.points_possible
  end

  it "imports association settings when rubric is included" do
    file_data = get_import_data("", "assignment")
    context = get_import_context("")
    migration = context.content_migrations.create!

    assignment_hash = file_data.find { |h| h["migration_id"] == "4469882339231" }.with_indifferent_access
    rubric_model({ context:, migration_id: assignment_hash[:grading][:rubric_id] })
    assignment_hash[:rubric_use_for_grading] = true
    assignment_hash[:rubric_hide_points] = true
    assignment_hash[:rubric_hide_outcome_results] = true

    Importers::AssignmentImporter.import_from_migration(assignment_hash, context, migration)
    ra = Assignment.where(migration_id: assignment_hash[:migration_id]).first.rubric_association
    expect(ra.use_for_grading).to be true
    expect(ra.hide_points).to be true
    expect(ra.hide_outcome_results).to be true
  end

  describe "migrate_assignment_group_categories" do
    context "with feature off" do
      it "imports group category into existing group with same name when marked as a group assignment" do
        file_data = get_import_data("", "assignment")
        context = get_import_context("")
        assignment_hash = file_data.find { |h| h["migration_id"] == "4469882339232" }.with_indifferent_access
        migration = context.content_migrations.create!
        gc = context.group_categories.create! name: assignment_hash[:group_category]

        Importers::AssignmentImporter.import_from_migration(assignment_hash, context, migration)
        a = Assignment.where(migration_id: assignment_hash[:migration_id]).first
        expect(a).to be_has_group_category
        expect(a.group_category).to eq gc
      end
    end

    context "with feature on" do
      before do
        Account.default.enable_feature!(:migrate_assignment_group_categories)
      end

      it "copies group category" do
        file_data = get_import_data("", "assignment")
        context = get_import_context("")
        assignment_hash = file_data.find { |h| h["migration_id"] == "4469882339232" }.with_indifferent_access
        migration = context.content_migrations.create!

        Importers::AssignmentImporter.import_from_migration(assignment_hash, context, migration)
        a = Assignment.where(migration_id: assignment_hash[:migration_id]).first
        expect(a).to be_has_group_category
        expect(a.group_category.name).to eq "A Team"
        expect(context.group_categories.where(name: "Project Groups")).to be_empty
      end
    end
  end

  it "infers the default name when importing a nameless assignment" do
    course_model
    migration = @course.content_migrations.create!
    Importers::AssignmentImporter.import_from_migration(default_input_assignment_hash, @course, migration)
    assignment = @course.assignments.where(migration_id:).first
    expect(assignment.title).to eq "untitled assignment"
  end

  it "schedules auto peer reviews if dates are not shifted" do
    course_model
    migration = @course.content_migrations.create!
    assign_hash = {
      "migration_id" => migration_id,
      "assignment_group_migration_id" => "i2bc4b8ea8fac88f1899e5e95d76f3004",
      "workflow_state" => "published",
      "title" => "auto peer review assignment",
      "grading_type" => "points",
      "submission_types" => "none",
      "peer_reviews" => true,
      "automatic_peer_reviews" => true,
      "due_at" => 1_401_947_999_000,
      "peer_reviews_due_at" => 1_401_947_999_000
    }
    expects_job_with_tag("Assignment#do_auto_peer_review") do
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    end
  end

  it "does not schedule auto peer reviews if dates are shifted (it'll be scheduled later)" do
    course_model
    assign_hash = {
      "migration_id" => migration_id,
      "assignment_group_migration_id" => "i2bc4b8ea8fac88f1899e5e95d76f3004",
      "workflow_state" => "published",
      "title" => "auto peer review assignment",
      "grading_type" => "points",
      "submission_types" => "none",
      "peer_reviews" => true,
      "automatic_peer_reviews" => true,
      "due_at" => 1_401_947_999_000,
      "peer_reviews_due_at" => 1_401_947_999_000
    }
    migration = @course.content_migrations.create!
    allow(migration).to receive(:date_shift_options).and_return(true)
    expects_job_with_tag("Assignment#do_auto_peer_review", 0) do
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    end
  end

  it "includes turnitin_settings" do
    course_model
    expect(@course).to receive(:turnitin_enabled?).at_least(1).and_return(true)
    migration = @course.content_migrations.create!
    nameless_assignment_hash = {
      "migration_id" => migration_id,
      "assignment_group_migration_id" => "i2bc4b8ea8fac88f1899e5e95d76f3004",
      "grading_standard_migration_id" => nil,
      "rubric_migration_id" => nil,
      "rubric_id" => nil,
      "quiz_migration_id" => nil,
      "workflow_state" => "published",
      "title" => "",
      "grading_type" => "points",
      "submission_types" => "none",
      "peer_reviews" => false,
      "automatic_peer_reviews" => false,
      "muted" => false,
      "due_at" => 1_401_947_999_000,
      "peer_reviews_due_at" => 1_401_947_999_000,
      "position" => 6,
      "peer_review_count" => 0,
      "turnitin_enabled" => true,
      "turnitin_settings" => "{\"originality_report_visibility\":\"after_due_date\",\"s_paper_check\":\"1\",\"internet_check\":\"0\",\"journal_check\":\"1\",\"exclude_biblio\":\"1\",\"exclude_quoted\":\"0\",\"exclude_type\":\"1\",\"exclude_value\":\"5\",\"submit_papers_to\":\"1\",\"s_view_report\":\"1\"}"
    }
    Importers::AssignmentImporter.import_from_migration(nameless_assignment_hash, @course, migration)
    assignment = @course.assignments.where(migration_id:).first
    expect(assignment.turnitin_enabled).to be true
    settings = assignment.turnitin_settings
    expect(settings["originality_report_visibility"]).to eq("after_due_date")
    expect(settings["exclude_value"]).to eq("5")

    %w[s_paper_check journal_check exclude_biblio exclude_type submit_papers_to s_view_report].each do |field|
      expect(settings[field]).to eq("1")
    end

    ["internet_check", "exclude_quoted"].each do |field|
      expect(settings[field]).to eq("0")
    end
  end

  it "does not explode if it tries to import negative points possible" do
    course_model
    assign_hash = {
      "migration_id" => migration_id,
      "assignment_group_migration_id" => "i2bc4b8ea8fac88f1899e5e95d76f3004",
      "workflow_state" => "published",
      "title" => "weird negative assignment",
      "grading_type" => "points",
      "submission_types" => "none",
      "points_possible" => -42
    }
    migration = @course.content_migrations.create!
    allow(migration).to receive(:date_shift_options).and_return(true)
    Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    assignment = @course.assignments.where(migration_id:).first
    expect(assignment.points_possible).to eq 0
  end

  it "does not clear dates if these are null in the source hash" do
    course_model
    assign_hash = {
      "migration_id" => migration_id,
      "assignment_group_migration_id" => "i2bc4b8ea8fac88f1899e5e95d76f3004",
      "workflow_state" => "published",
      "title" => "date clobber or not",
      "grading_type" => "points",
      "submission_types" => "none",
      "points_possible" => 10,
      "due_at" => nil,
      "peer_reviews_due_at" => nil,
      "lock_at" => nil,
      "unlock_at" => nil
    }
    migration = @course.content_migrations.create!
    assignment = @course.assignments.create! title: "test", due_at: Time.zone.now, unlock_at: 1.day.ago, lock_at: 1.day.from_now, peer_reviews_due_at: 2.days.from_now, migration_id: "ib4834d160d180e2e91572e8b9e3b1bc6"
    Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    assignment.reload
    expect(assignment.title).to eq "date clobber or not"
    expect(assignment.due_at).not_to be_nil
    expect(assignment.peer_reviews_due_at).not_to be_nil
    expect(assignment.unlock_at).not_to be_nil
    expect(assignment.lock_at).not_to be_nil
  end

  it "results in the creation of an audit event, with the migration user, when configured with anonymous grading" do
    course_model
    @course.enable_feature!(:anonymous_marking)
    migration = @course.content_migrations.create! user: User.create!
    Importers::AssignmentImporter.import_from_migration({ "title" => "Imported", "anonymous_grading" => true }, @course, migration)
    expect(AnonymousOrModerationEvent.last.user).to eq migration.user
  end

  context "when assignments are new quizzes/quiz lti" do
    subject do
      new_quiz
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
      new_quiz.reload
    end

    let(:course) { course_model }
    let(:migration) { course.content_migrations.create! }
    let(:new_quiz) do
      new_quizzes_assignment(course:, title: "Some New Quiz", migration_id:)
    end
    let(:assignment_hash) do
      {
        migration_id:,
        workflow_state: "published",
        title: "Tool Assignment",
        submission_types: "external_tool",
      }
    end

    it "sets the content tag workflow state back to active when a previously deleted quiz lti assignment is re-imported back into the course" do
      subject
      new_quiz.destroy
      new_quiz.save!
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
      new_quiz.reload
      expect(new_quiz.external_tool_tag).to be_active
    end
  end

  context "when assignments use an LTI tool" do
    subject do
      assignment # trigger create
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
      assignment.reload
    end

    let(:course) { course_model }
    let(:migration) { course.content_migrations.create! }

    let(:assignment) do
      course.assignments.create!(
        title: "test",
        due_at: Time.zone.now,
        unlock_at: 1.day.ago,
        lock_at: 1.day.from_now,
        peer_reviews_due_at: 2.days.from_now,
        migration_id:,
        submission_types: "external_tool",
        external_tool_tag_attributes: { url: tool.url, content: tool, new_tab: tool_current_tab },
        points_possible: 10
      )
    end

    let(:assignment_hash) do
      {
        "migration_id" => migration_id,
        "assignment_group_migration_id" => "i2bc4b8ea8fac88f1899e5e95d76f3004",
        "workflow_state" => "published",
        "title" => "Tool Assignment",
        "grading_type" => "points",
        "submission_types" => "external_tool",
        "points_possible" => 10,
        "due_at" => nil,
        "peer_reviews_due_at" => nil,
        "lock_at" => nil,
        "unlock_at" => nil,
        "external_tool_url" => tool_url,
        "external_tool_id" => tool_id,
        "external_tool_new_tab" => tool_new_tab
      }
    end
    let(:tool_current_tab) { false }
    let(:tool_new_tab) { false }

    context "and a matching tool is installed in the destination" do
      let(:tool) { external_tool_model(context: course.root_account) }
      let(:tool_id) { tool.id }
      let(:tool_url) { tool.url }

      context "but the matching tool has a different ID" do
        let(:tool_id) { tool.id + 1 }

        it "matches the tool via URL lookup" do
          expect(subject.external_tool_tag.content).to eq tool
        end
      end

      context "but the matching tool has a different URL" do
        let(:tool_url) { "http://google.com/launch/2" }

        it "updates the URL" do
          expect { subject }.to change { assignment.external_tool_tag.url }.from(tool.url).to tool_url
        end
      end

      context "and there is no new_tab setting" do
        let(:tool_current_tab) { false }
        let(:tool_new_tab) { nil }

        it "does not change the setting" do
          expect { subject }.not_to change { assignment.external_tool_tag.new_tab }.from(false)
        end
      end

      context "and the new_tab setting is the same as the tool" do
        let(:tool_current_tab) { false }
        let(:tool_new_tab) { false }

        it "does not change the setting" do
          expect { subject }.not_to change { assignment.external_tool_tag.new_tab }.from(false)
        end
      end

      context "but the matching tool has a different new_tab setting" do
        context "when the old setting is false and the new is true" do
          let(:tool_current_tab) { false }
          let(:tool_new_tab) { true }

          it "updates the setting to true" do
            expect { subject }.to change { assignment.external_tool_tag.new_tab }.from(false).to true
          end
        end

        context "when the old setting is true and the new is false" do
          let(:tool_current_tab) { true }
          let(:tool_new_tab) { false }

          it "updates the setting to false" do
            expect { subject }.to change { assignment.external_tool_tag.new_tab }.from(true).to false
          end
        end
      end
    end

    context "when previously deleted LTI assignment is re-imported" do
      let(:tool) { external_tool_model(context: course.root_account) }
      let(:tool_id) { tool.id }
      let(:tool_url) { tool.url }

      before do
        assignment
        Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
        assignment.reload
        assignment.destroy
        assignment.save!
      end

      it "un-deletes content tag" do
        expect(assignment.external_tool_tag).to be_deleted
        subject
        expect(assignment.external_tool_tag).to be_active
      end
    end

    context "and the tool uses LTI 1.3" do
      let(:tool_id) { tool.id }
      let(:tool_url) { tool.url }
      let(:registration) { lti_registration_with_tool(account: course.root_account, created_by: user_model) }
      let(:dev_key) { DeveloperKey.create! }
      let(:tool) do
        registration.deployments.first
      end
      let(:assignment) do
        course.assignments.create!(
          title: "test",
          due_at: Time.zone.now,
          unlock_at: 1.day.ago,
          lock_at: 1.day.from_now,
          peer_reviews_due_at: 2.days.from_now,
          migration_id:
        )
      end

      it "creates the assignment line item" do
        expect { subject }.to change { assignment.line_items.count }.from(0).to 1
      end

      it "creates a resource link" do
        expect { subject }.to change { assignment.line_items.first&.resource_link.present? }.from(false).to true
      end

      context "when assignment content tag has link_settings" do
        let(:link_settings) { { selection_width: 456, selection_height: 789 } }
        let(:assignment_hash) do
          super().merge({ external_tool_link_settings_json: link_settings.to_json })
        end

        it "copies to new tag" do
          subject
          expect(assignment.external_tool_tag.link_settings).to eq link_settings.stringify_keys
        end
      end

      describe "line item creation" do
        let(:course) { Course.create! }
        let(:migration) { course.content_migrations.create! }
        let(:assignment) do
          Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
          course.assignments.find_by(migration_id:)
        end
        let(:assignment_hash) do
          {
            migration_id:,
            title: "my assignment",
            grading_type: "points",
            points_possible: 123,
            line_items: line_items_array,
            external_tool_url: assignment_tool_url,
            submission_types: assignment_submission_types,
          }.compact.with_indifferent_access
        end

        let(:assignment_submission_types) { "external_tool" }
        let(:assignment_tool_url) { tool.url }

        let(:line_items_array) { [line_item_hash] }
        let(:line_item_hash) do
          {
            coupled:,
          }.merge(extra_line_item_params).with_indifferent_access
        end
        let(:extra_line_item_params) { {} }
        let(:coupled) { false }

        let(:created_resource_link_ids) { Lti::ResourceLink.where(context: assignment).pluck(:id) }

        shared_examples_for "a single imported line item" do
          subject { assignment.line_items.take }

          it "creates exactly one line item" do
            expect(assignment.line_items.count).to eq(1)
          end

          it "sets the client_id" do
            expect(subject.client_id).to eq(tool.global_developer_key_id)
          end

          it "defaults label to the assignment's name" do
            expect(subject.label).to eq(assignment_hash[:title])
          end

          it "defaults score_maximum to the assignment's points possible" do
            expect(subject.score_maximum).to eq(assignment_hash[:points_possible])
          end

          context "when resource_id and tag are given" do
            let(:extra_line_item_params) { super().merge(resource_id: "abc", tag: "def") }

            it "sets them on the line item" do
              expect(subject.resource_id).to eq("abc")
              expect(subject.tag).to eq("def")
            end
          end

          context "when label is given" do
            let(:extra_line_item_params) { super().merge(label: "ghi") }

            it "sets label on the line item but doesn't affect the assignment name" do
              expect(subject.label).to eq("ghi")
              expect(assignment.name).to eq(assignment_hash[:title])
            end
          end

          context "when score_maximum is given" do
            let(:extra_line_item_params) { super().merge(score_maximum: 98_765) }

            it "sets score_maximum on the line item but doesn't affect the assignment points_possible" do
              expect(subject.score_maximum).to eq(98_765)
              expect(assignment.points_possible).to eq(assignment_hash[:points_possible])
            end
          end

          context "when extensions is set" do
            let(:extra_line_item_params) { super().merge(extensions: { foo: "bar" }.to_json) }

            it "sets extensions on the line item" do
              expect(subject.extensions).to eq("foo" => "bar")
            end
          end
        end

        describe "an external tool assignment with no line items" do
          let(:line_items_array) { [] }
          let(:coupled) { true }

          it "creates a default coupled line item with an Lti::ResourceLink" do
            expect(assignment.line_items.count).to eq(1)
            expect(created_resource_link_ids.count).to eq(1)
            expect(assignment.line_items.take.attributes.symbolize_keys).to include(
              coupled: true,
              label: assignment_hash[:title],
              score_maximum: assignment_hash[:points_possible],
              lti_resource_link_id: created_resource_link_ids.first,
              extensions: {},
              client_id: tool.global_developer_key_id
            )
          end
        end

        describe "an external tool assignment with a coupled line item" do
          let(:coupled) { true }

          it_behaves_like "a single imported line item"

          it "creates one Lti::ResourceLink for the assignment and the line item" do
            expect(created_resource_link_ids).to eq([assignment.line_items.take.lti_resource_link_id])
          end
        end

        describe "a submission_type=none assignment (AGS-created) with a uncoupled line item" do
          let(:assignment_submission_types) { "none" }
          let(:assignment_tool_url) { nil }
          let(:extra_line_item_params) { { client_id: tool.global_developer_key_id } }

          it_behaves_like "a single imported line item"

          it "does not create an Lti::ResourceLink" do
            expect(created_resource_link_ids).to eq([])
            expect(assignment.line_items.take.lti_resource_link_id).to be_nil
          end

          context "without an explicit client_id" do
            let(:extra_line_item_params) { {} }

            it "fails to import" do
              expect do
                assignment
              end.to raise_error(/Client can't be blank/)
            end
          end
        end

        describe "an external tool assignment with an uncoupled line item (AGS-created assignment)" do
          it_behaves_like "a single imported line item"

          it "creates one Lti::ResourceLink for the assignment and the line item" do
            expect(created_resource_link_ids).to eq([assignment.line_items.take.lti_resource_link_id])
          end
        end

        describe "an external tool assignment with multiple uncoupled line items" do
          let(:line_items_array) do
            [
              { coupled: false, label: "abc", score_maximum: 123 },
              { coupled: false, label: "def" },
              { coupled: false },
            ]
          end

          it "creates all line items" do
            expect(assignment.line_items.pluck(:label, :coupled, :score_maximum).sort_by(&:first)).to eq([
                                                                                                           ["abc", false, 123],
                                                                                                           ["def", false, assignment_hash[:points_possible]],
                                                                                                           [assignment_hash[:title], false, assignment_hash[:points_possible]],
                                                                                                         ])
          end

          it "creates the line items with the same Lti::ResourceLink" do
            expect(assignment.line_items.pluck(:lti_resource_link_id)).to eq(created_resource_link_ids * 3)
          end
        end

        describe "an external tool assignment with a coupled line item and additional uncoupled line items" do
          let(:line_items_array) do
            [
              { coupled: false, label: "abc", score_maximum: 123 },
              { coupled: false, label: "abc", score_maximum: 123 },
              { coupled: true, label: "def" },
              { coupled: false },
            ]
          end

          let(:expected_created_line_items_fields) do
            [
              ["abc", false, 123],
              ["abc", false, 123],
              ["def", true, assignment_hash[:points_possible]],
              [assignment_hash[:title], false, assignment_hash[:points_possible]],
            ]
          end

          it "creates all line items" do
            expect(assignment.line_items.pluck(:label, :coupled, :score_maximum)
            .sort_by(&:first)).to eq(expected_created_line_items_fields)
          end

          it "creates the line items with the same Lti::ResourceLink" do
            expect(assignment.line_items.pluck(:lti_resource_link_id))
              .to eq(created_resource_link_ids * 4)
          end

          context "when the same line items are imported again in an additional run" do
            it "doesn't create the same line items over again" do
              assignment
              expect do
                Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
                Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
              end.to_not change { Assignment.count }
              expect(assignment.line_items.pluck(:label, :coupled, :score_maximum).sort_by(&:first))
                .to eq(expected_created_line_items_fields)
            end
          end
        end
      end

      context "when previously deleted LTI assignment is re-imported" do
        let(:line_item) { assignment.line_items.first }
        let(:resource_link) { assignment.lti_resource_links.first }

        before do
          assignment
          Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
          assignment.reload
          assignment.destroy
          assignment.save!
        end

        it "un-deletes resource links" do
          expect(line_item).to be_deleted
          subject
          expect(line_item.reload).to be_active
        end

        it "un-deletes line items" do
          expect(resource_link).to be_deleted
          subject
          expect(resource_link.reload).to be_active
        end
      end
    end
  end

  describe "#create_tool_settings" do
    include_context "lti2_spec_helper"

    let(:course) { course_model }
    let(:migration) { course.content_migrations.create! }
    let(:assignment) do
      course.assignments.create!(
        title: "test",
        due_at: Time.zone.now,
        unlock_at: 1.day.ago,
        lock_at: 1.day.from_now,
        peer_reviews_due_at: 2.days.from_now,
        migration_id: migration.id
      )
    end

    let(:custom) do
      {
        "custom_var_1" => "value one",
        "custom_var_2" => "value two",
      }
    end

    let(:custom_parameters) do
      {
        "custom_parameter_1" => "param value one",
        "custom_parameter_2" => "param value two",
      }
    end

    let(:tool_setting) do
      {
        "product_code" => tool_proxy.product_family.product_code,
        "vendor_code" => tool_proxy.product_family.vendor_code,
        "custom" => custom,
        "custom_parameters" => custom_parameters
      }
    end

    it "does nothing if the tool settings is blank" do
      Importers::AssignmentImporter.create_tool_settings({}, tool_proxy, assignment)
      expect(tool_proxy.tool_settings.length).to eq 0
    end

    it "creates the tool setting if codes match" do
      Importers::AssignmentImporter.create_tool_settings(tool_setting, tool_proxy, assignment)
      expect(tool_proxy.reload.tool_settings.length).to eq 1
    end

    it 'uses the new assignment "lti_context_id" as the resource link id' do
      Importers::AssignmentImporter.create_tool_settings(tool_setting, tool_proxy, assignment)
      expect(tool_proxy.tool_settings.first.resource_link_id).to eq assignment.lti_context_id
    end

    it "sets the context to the course of the assignment" do
      Importers::AssignmentImporter.create_tool_settings(tool_setting, tool_proxy, assignment)
      expect(tool_proxy.tool_settings.first.context).to eq course
    end

    it "sets the custom data" do
      Importers::AssignmentImporter.create_tool_settings(tool_setting, tool_proxy, assignment)
      expect(tool_proxy.tool_settings.first.custom).to eq(custom)
    end

    it "sets the custom data parameters" do
      Importers::AssignmentImporter.create_tool_settings(tool_setting, tool_proxy, assignment)
      expect(tool_proxy.tool_settings.first.custom_parameters).to eq(custom_parameters)
    end

    it "does not attempt to recreate tool settings if they already exist" do
      tool_proxy.tool_settings.create!(
        context: course,
        tool_proxy:,
        resource_link_id: assignment.lti_context_id
      )
      expect do
        Importers::AssignmentImporter.create_tool_settings(
          tool_setting,
          tool_proxy,
          assignment
        )
      end.not_to raise_exception
    end
  end

  describe "similarity_detection_tool" do
    include_context "lti2_spec_helper"

    let(:resource_type_code) { "123" }
    let(:vendor_code) { "abc" }
    let(:product_code) { "qrx" }
    let(:visibility) { "after_grading" }
    let(:assign_hash) do
      {
        "migration_id" => migration_id,
        "assignment_group_migration_id" => "i2bc4b8ea8fac88f1899e5e95d76f3004",
        "workflow_state" => "published",
        "title" => "similarity_detection_tool",
        "grading_type" => "points",
        "submission_types" => "online",
        "points_possible" => 10,
        "due_at" => nil,
        "peer_reviews_due_at" => nil,
        "lock_at" => nil,
        "unlock_at" => nil,
        "similarity_detection_tool" => {
          resource_type_code:,
          vendor_code:,
          product_code:,
          visibility:
        }
      }
    end

    context "when plagiarism detection tools are being imported" do
      let(:course) { course_model }
      let(:migration) { course.content_migrations.create! }
      let(:assignment) do
        course.assignments.create!(
          title: "test",
          due_at: Time.zone.now,
          unlock_at: 1.day.ago,
          lock_at: 1.day.from_now,
          peer_reviews_due_at: 2.days.from_now,
          migration_id:
        )
      end

      it "creates a assignment_configuration_tool_lookup" do
        allow(Lti::ToolProxy)
          .to receive(:find_active_proxies_for_context_by_vendor_code_and_product_code) { [tool_proxy] }
        assignment
        Importers::AssignmentImporter.import_from_migration(assign_hash, course, migration)
        assignment.reload
        expect(assignment.assignment_configuration_tool_lookups).to exist
      end

      it "does not create duplicate assignment_configuration_tool_lookups" do
        assignment.assignment_configuration_tool_lookups.create!(
          tool_vendor_code: vendor_code,
          tool_product_code: product_code,
          tool_resource_type_code: resource_type_code,
          tool_type: "Lti::MessageHandler",
          context_type: "Course"
        )

        Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
        assignment.reload
        expect(assignment.assignment_configuration_tool_lookups.count).to eq 1
      end

      it "clears out extra tool settings" do
        allow(Lti::ToolProxy)
          .to receive(:find_active_proxies_for_context_by_vendor_code_and_product_code) { [tool_proxy] }
        assignment.assignment_configuration_tool_lookups.create!(
          tool_vendor_code: "extra_vendor_code",
          tool_product_code: "extra_product_code",
          tool_resource_type_code: "extra_resource_type_code",
          tool_type: "Lti::MessageHandler",
          context_type: "Course"
        )
        Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
        assignment.reload
        expect(assignment.assignment_configuration_tool_lookups.count).to eq 1
        tool_lookup = assignment.assignment_configuration_tool_lookups.first
        expect(tool_lookup.tool_vendor_code).to eq vendor_code
        expect(tool_lookup.tool_product_code).to eq product_code
        expect(tool_lookup.tool_resource_type_code).to eq resource_type_code
        expect(tool_lookup.tool_type).to eq "Lti::MessageHandler"
        expect(tool_lookup.context_type).to eq "Course"
      end

      context "when similarity_detection_tool is empty in hash" do
        let(:empty_similarity_tool_assign_hash) do
          assign_hash[:similarity_detection_tool] = nil
          assign_hash
        end

        before do
          allow(Lti::ToolProxy)
            .to receive(:find_active_proxies_for_context_by_vendor_code_and_product_code) { [tool_proxy] }
          assignment.assignment_configuration_tool_lookups.create!(
            tool_vendor_code: vendor_code,
            tool_product_code: product_code,
            tool_resource_type_code: resource_type_code,
            tool_type: "Lti::MessageHandler",
            context_type: "Account"
          )
        end

        context "when import is not master migration" do
          it "does not remove ACTLs on empty similarity_detection_tool" do
            Importers::AssignmentImporter.import_from_migration(empty_similarity_tool_assign_hash, @course, migration)
            assignment.reload
            expect(assignment.assignment_configuration_tool_lookups.count).to eq 1
            tool_lookup = assignment.assignment_configuration_tool_lookups.first
            expect(tool_lookup.tool_vendor_code).to eq vendor_code
            expect(tool_lookup.tool_product_code).to eq product_code
            expect(tool_lookup.tool_resource_type_code).to eq resource_type_code
          end
        end

        context "when import is a master migration" do
          let(:migration) { double("Migration") }
          let(:master_course_subscription) { double("MasterCourseSubscription") }
          let(:item) { double("Item") }
          let(:content_tag) { double("ContentTag", downstream_changes: ["none"]) }

          let(:master_migration) do
            migration = course.content_migrations.create!
            allow_any_instance_of(Assignment).to receive(:mark_as_importing!)
            allow(migration).to receive_messages(for_master_course_import?: true, master_course_subscription:)
            allow(master_course_subscription).to receive(:content_tag_for).with(assignment).and_return(content_tag)
            migration
          end

          it "removes ACTLs on empty similarity_detection_tool" do
            Importers::AssignmentImporter.import_from_migration(empty_similarity_tool_assign_hash, @course, master_migration)
            assignment.reload
            expect(assignment.assignment_configuration_tool_lookups.count).to eq 0
          end
        end
      end
    end

    it "sets the vendor/product/resource_type codes" do
      allow(Lti::ToolProxy)
        .to receive(:find_active_proxies_for_context_by_vendor_code_and_product_code) { [tool_proxy] }
      course_model
      migration = @course.content_migrations.create!
      assignment = @course.assignments.create!(title: "test", due_at: Time.zone.now, unlock_at: 1.day.ago, lock_at: 1.day.from_now, peer_reviews_due_at: 2.days.from_now, migration_id:)
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
      assignment.reload
      expect(assignment.assignment_configuration_tool_lookups.count).to eq 1
      tool_lookup = assignment.assignment_configuration_tool_lookups.first
      expect(tool_lookup.tool_vendor_code).to eq vendor_code
      expect(tool_lookup.tool_product_code).to eq product_code
      expect(tool_lookup.tool_resource_type_code).to eq resource_type_code
      expect(tool_lookup.tool_type).to eq "Lti::MessageHandler"
      expect(tool_lookup.context_type).to eq "Course"
    end

    it "sets the tool_type to 'LTI::MessageHandler'" do
      allow(Lti::ToolProxy)
        .to receive(:find_active_proxies_for_context_by_vendor_code_and_product_code) { [tool_proxy] }
      course_model
      migration = @course.content_migrations.create!
      assignment = @course.assignments.create!(title: "test", due_at: Time.zone.now, unlock_at: 1.day.ago, lock_at: 1.day.from_now, peer_reviews_due_at: 2.days.from_now, migration_id:)
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
      assignment.reload
      tool_lookup = assignment.assignment_configuration_tool_lookups.first
      expect(tool_lookup.tool_type).to eq "Lti::MessageHandler"
    end

    it "sets the visibility" do
      allow(Lti::ToolProxy)
        .to receive(:find_active_proxies_for_context_by_vendor_code_and_product_code) { [tool_proxy] }
      course_model
      migration = @course.content_migrations.create!
      assignment = @course.assignments.create!(title: "test", due_at: Time.zone.now, unlock_at: 1.day.ago, lock_at: 1.day.from_now, peer_reviews_due_at: 2.days.from_now, migration_id:)
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
      assignment.reload
      expect(assignment.turnitin_settings.with_indifferent_access[:originality_report_visibility]).to eq visibility
    end

    it "adds a warning to the migration without an active tool_proxy" do
      course_model
      migration = @course.content_migrations.create!
      @course.assignments.create!(title: "test", due_at: Time.zone.now, unlock_at: 1.day.ago, lock_at: 1.day.from_now, peer_reviews_due_at: 2.days.from_now, migration_id:)
      expect(migration).to receive(:add_warning).with("We were unable to find a tool profile match for vendor_code: \"abc\" product_code: \"qrx\".")
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    end

    it "doesn't add a warning to the migration if there is an active tool_proxy" do
      allow(Lti::ToolProxy)
        .to receive(:find_active_proxies_for_context_by_vendor_code_and_product_code) { [tool_proxy] }
      course_model
      migration = @course.content_migrations.create!
      @course.assignments.create!(title: "test", due_at: Time.zone.now, unlock_at: 1.day.ago, lock_at: 1.day.from_now, peer_reviews_due_at: 2.days.from_now, migration_id:)
      expect(migration).to_not receive(:add_warning).with("We were unable to find a tool profile match for vendor_code: \"abc\" product_code: \"qrx\".")
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    end
  end

  describe "post_policy" do
    let(:course) { Course.create! }
    let(:migration) { course.content_migrations.create! }
    let(:assignment_hash) do
      {
        "migration_id" => migration_id,
        "post_policy" => { "post_manually" => false }
      }.with_indifferent_access
    end

    let(:imported_assignment) do
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
      course.assignments.find_by(migration_id:)
    end

    before do
      course.enable_feature!(:anonymous_marking)
      course.enable_feature!(:moderated_grading)
    end

    it "sets the assignment to manually-posted if post_policy['post_manually'] is true" do
      assignment_hash[:post_policy][:post_manually] = true
      expect(imported_assignment.post_policy).to be_post_manually
    end

    it "sets the assignment to manually-posted if the assignment is anonymous" do
      assignment_hash.delete(:post_policy)
      assignment_hash[:anonymous_grading] = true
      expect(imported_assignment.post_policy).to be_post_manually
    end

    it "sets the assignment to manually-posted if the assignment is moderated" do
      assignment_hash.delete(:post_policy)
      assignment_hash[:moderated_grading] = true
      assignment_hash[:grader_count] = 2
      expect(imported_assignment.post_policy).to be_post_manually
    end

    it "sets the assignment to auto-posted if post_policy['post_manually'] is false and not anonymous or moderated" do
      expect(imported_assignment.post_policy).not_to be_post_manually
    end

    it "does not update the assignment's post policy if no post_policy element is present and not anonymous or moderated" do
      assignment_hash.delete(:post_policy)
      expect(imported_assignment.post_policy).not_to be_post_manually
    end
  end

  describe "post_to_sis" do
    let(:course) { Course.create! }
    let(:account) { course.account }
    let(:migration) { course.content_migrations.create! }
    let(:assignment_hash) do
      {
        "migration_id" => migration_id,
        "title" => "post_to_sis",
        "post_to_sis" => false,
        "date_shift_options" => {
          remove_dates: true
        }
      }.with_indifferent_access
    end

    let(:imported_assignment) do
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
      course.assignments.find_by(migration_id:)
    end

    it "adds a warning to the migration if the post_to_sis validation will fail without due dates" do
      assignment_hash[:post_to_sis] = true
      account.settings = {
        sis_syncing: { value: true },
        sis_require_assignment_due_date: { value: true }
      }
      account.save!
      account.enable_feature!(:new_sis_integrations)

      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(true)
      expect(migration).to receive(:add_warning).with("The Sync to SIS setting could not be enabled for the assignment \"#{assignment_hash["title"]}\" without a due date.")
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
    end

    it "sets post_to_sis if provided" do
      assignment_hash[:post_to_sis] = true
      expect(imported_assignment.post_to_sis).to eq(assignment_hash["post_to_sis"])
    end

    it "does not change the value set on the assignment if previously imported" do
      imported_assignment
      imported_assignment.update(post_to_sis: !assignment_hash["post_to_sis"])
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
      imported_assignment.reload
      expect(imported_assignment.post_to_sis).not_to eq(assignment_hash["post_to_sis"])
    end

    it "does change the value if the blueprint has been locked" do
      imported_assignment
      imported_assignment.update(post_to_sis: !assignment_hash["post_to_sis"])
      allow(Assignment).to receive(:where).and_return([imported_assignment])
      allow(imported_assignment).to receive(:editing_restricted?).with(:any).and_return(true)
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
      imported_assignment.reload
      expect(imported_assignment.post_to_sis).to eq(assignment_hash["post_to_sis"])
    end
  end

  describe "#try_to_save_with_date_shift" do
    subject do
      Importers::AssignmentImporter.try_to_save_with_date_shift(item, migration)
    end

    let(:course) { Course.create! }
    let(:migration) { course.content_migrations.create!(date_shift_options_settings) }
    # This is not saved at this point, so there is no id
    let(:item) { course.assignments.temp_record }
    let(:original_date) { Time.zone.parse("2023-06-01") }
    # With the given date shift options, this is the expected date
    let(:expected_date) { Time.zone.parse("2024-05-30") }
    let(:deletable_error_fields) { %i[due_at lock_at unlock_at peer_reviews_due_at needs_update_cached_due_dates] }

    context "when there is no date_shift_options on migration" do
      let(:migration) { super().tap { |m| m.migration_settings.delete(:date_shift_options) } }

      before do
        item.update!(
          due_at: original_date,
          lock_at: original_date,
          unlock_at: original_date,
          peer_reviews_due_at: original_date,
          needs_update_cached_due_dates: false
        )
      end

      it "should not change the due_at field" do
        expect(subject.due_at).to eq(original_date)
      end

      it "should not change the lock_at field" do
        expect(subject.lock_at).to eq(original_date)
      end

      it "should not change the unlock_at field" do
        expect(subject.unlock_at).to eq(original_date)
      end

      it "should not change the peer_reviews_due_at field" do
        expect(subject.peer_reviews_due_at).to eq(original_date)
      end

      it "should not change the needs_update_cached_due_dates field" do
        expect(subject.needs_update_cached_due_dates).to be_falsey
      end

      it "should early return" do
        expect(Importers::CourseContentImporter).not_to receive(:shift_date_options_from_migration)
        subject
      end
    end

    context "when setting due_at field" do
      context "when field is given" do
        before do
          item.update!(due_at: original_date)
        end

        it "should shift the date" do
          expect(subject.due_at).to eq(expected_date)
        end
      end

      context "when date is invalid after shifting" do
        let(:title) { "test title" }

        before do
          item.update!(title:)
          item.due_at = original_date
          item.errors.add(:due_at, "a validation error message")

          allow(item).to receive(:invalid?).and_return(true)
          deletable_error_fields.each { |attr| allow(item.errors).to receive(:delete).with(attr) }
        end

        it "should keep the original incoming date" do
          expect(subject.due_at).to eq(original_date)
        end

        it "should clear the date error field" do
          expect(item.errors).to receive(:delete).with(:due_at)
          subject
        end

        it "should add a warning to the migration on record with id" do
          subject
          expected_issue_message = "Couldn't adjust dates on assignment #{title} (ID #{item.id})"
          issues = migration.migration_issues
          expect(issues.count).to eq(1)
          expect(migration.migration_issues.first.description).to eq(expected_issue_message)
        end
      end

      context "when field is missing" do
        it "should shift the date" do
          expect(subject.due_at).to be_nil
        end
      end
    end

    context "when setting lock_at field" do
      context "when field is given" do
        before do
          item.update!(lock_at: original_date)
        end

        it "should shift the date" do
          expect(subject.lock_at).to eq(expected_date)
        end
      end

      context "when date is invalid after shifting" do
        let(:title) { "test title" }

        before do
          item.update!(title:)
          item.lock_at = original_date
          item.errors.add(:lock_at, "a validation error message")

          allow(item).to receive(:invalid?).and_return(true)
          deletable_error_fields.each { |attr| allow(item.errors).to receive(:delete).with(attr) }
        end

        it "should keep the original incoming date" do
          expect(subject.lock_at).to eq(original_date)
        end

        it "should clear the date error field" do
          expect(item.errors).to receive(:delete).with(:lock_at)
          subject
        end

        it "should add a warning to the migration on record with id" do
          subject
          expected_issue_message = "Couldn't adjust dates on assignment #{title} (ID #{item.id})"
          issues = migration.migration_issues
          expect(issues.count).to eq(1)
          expect(migration.migration_issues.first.description).to eq(expected_issue_message)
        end
      end

      context "when field is missing" do
        it "should shift the date" do
          expect(subject.lock_at).to be_nil
        end
      end
    end

    context "when setting unlock_at field" do
      context "when field is given" do
        before do
          item.update!(unlock_at: original_date)
        end

        it "should shift the date" do
          expect(subject.unlock_at).to eq(expected_date)
        end
      end

      context "when date is invalid after shifting" do
        let(:title) { "test title" }

        before do
          item.update!(title:)
          item.unlock_at = original_date
          item.errors.add(:unlock_at, "a validation error message")

          allow(item).to receive(:invalid?).and_return(true)
          deletable_error_fields.each { |attr| allow(item.errors).to receive(:delete).with(attr) }
        end

        it "should keep the original incoming date" do
          expect(subject.unlock_at).to eq(original_date)
        end

        it "should clear the date error field" do
          expect(item.errors).to receive(:delete).with(:unlock_at)
          subject
        end

        it "should add a warning to the migration on record with id" do
          subject
          expected_issue_message = "Couldn't adjust dates on assignment #{title} (ID #{item.id})"
          issues = migration.migration_issues
          expect(issues.count).to eq(1)
          expect(migration.migration_issues.first.description).to eq(expected_issue_message)
        end
      end

      context "when field is missing" do
        it "should shift the date" do
          expect(subject.unlock_at).to be_nil
        end
      end
    end

    context "when setting peer_reviews_due_at field" do
      context "when field is given" do
        before do
          item.update!(peer_reviews_due_at: original_date)
        end

        it "should shift the date" do
          expect(subject.peer_reviews_due_at).to eq(expected_date)
        end
      end

      context "when date is invalid after shifting" do
        let(:title) { "test title" }

        before do
          item.update!(title:)
          item.peer_reviews_due_at = original_date
          item.errors.add(:peer_reviews_due_at, "a validation error message")

          allow(item).to receive(:invalid?).and_return(true)
          deletable_error_fields.each { |attr| allow(item.errors).to receive(:delete).with(attr) }
        end

        it "should keep the original incoming date" do
          expect(subject.peer_reviews_due_at).to eq(original_date)
        end

        it "should clear the date error field" do
          expect(item.errors).to receive(:delete).with(:peer_reviews_due_at)
          subject
        end

        it "should add a warning to the migration on record with id" do
          subject
          expected_issue_message = "Couldn't adjust dates on assignment #{title} (ID #{item.id})"
          issues = migration.migration_issues
          expect(issues.count).to eq(1)
          expect(migration.migration_issues.first.description).to eq(expected_issue_message)
        end
      end

      context "when field is missing" do
        it "should shift the date" do
          expect(subject.peer_reviews_due_at).to be_nil
        end
      end
    end

    context "when setting needs_update_cached_due_dates field" do
      context "when field is given" do
        let(:item) { Assignment.new }

        before do
          allow(item).to receive(:save_without_broadcasting!)
        end

        it "should shift the date" do
          expect(subject.needs_update_cached_due_dates).to be_truthy
        end

        context "when the update_cached_due_dates? is false" do
          before do
            allow(item).to receive_messages(update_cached_due_dates?: false)
          end

          it "sets needs_update_cached_due_dates false" do
            expect(subject.needs_update_cached_due_dates).to be_falsey
          end
        end

        context "when the update_cached_due_dates? is true" do
          before do
            allow(item).to receive_messages(update_cached_due_dates?: true)
          end

          it "sets needs_update_cached_due_dates to true" do
            expect(subject.needs_update_cached_due_dates).to be true
          end
        end
      end

      context "when date is invalid after shifting" do
        let(:title) { "test title" }

        before do
          item.update!(title:)
          item.needs_update_cached_due_dates = false
          item.errors.add(:needs_update_cached_due_dates, "a validation error message")

          allow(item).to receive(:invalid?).and_return(true)
          deletable_error_fields.each { |attr| allow(item.errors).to receive(:delete).with(attr) }
        end

        it "should keep the original incoming date" do
          expect(subject.needs_update_cached_due_dates).to be_falsey
        end

        it "should clear the date error field" do
          expect(item.errors).to receive(:delete).with(:needs_update_cached_due_dates)
          subject
        end

        it "should add a warning to the migration on record with id" do
          subject
          expected_issue_message = "Couldn't adjust dates on assignment #{title} (ID #{item.id})"
          issues = migration.migration_issues
          expect(issues.count).to eq(1)
          expect(migration.migration_issues.first.description).to eq(expected_issue_message)
        end
      end
    end
  end

  describe "import sub assignments" do
    subject do
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
      course.assignments.find_by(migration_id:)
    end

    let(:course) { Course.create! }
    let(:account) { course.root_account }
    let(:migration) { course.content_migrations.create! }
    let(:assignment_hash) do
      {
        migration_id:,
        title: "with_subassignment",
        post_to_sis: false,
        date_shift_options: {
          remove_dates: true
        },
        sub_assignments: [
          {
            id: 1337,
            migration_id: "test_migration_id_1337",
            title: "sub_assignment1",
            tag: CheckpointLabels::REPLY_TO_TOPIC,
          },
          {
            title: "sub_assignment2",
            tag: CheckpointLabels::REPLY_TO_ENTRY,
          }
        ],
      }
    end

    context "when the discussion_checkpoints feature flag is on" do
      before do
        account.enable_feature!(:discussion_checkpoints)
      end

      it "imports the two sub assignments from the hash" do
        expect(subject.sub_assignments.length).to eq(2)
      end

      it "sets the has_sub_assignments" do
        expect(subject.has_sub_assignments).to be_truthy
      end

      it "sets the proper tags for the sub assignments" do
        expect(subject.sub_assignments.pluck(:sub_assignment_tag)).to match_array([CheckpointLabels::REPLY_TO_TOPIC, CheckpointLabels::REPLY_TO_ENTRY])
      end

      it "sets the same context for sub assignments" do
        expect(subject.sub_assignments.all? { |sub_assignment| sub_assignment.context == subject.context }).to be_truthy
      end

      it "handles nil sub assignments" do
        assignment_hash[:sub_assignments] = nil

        expect(subject.sub_assignments.length).to eq(0)
      end

      it "handles empty sub assignments" do
        assignment_hash[:sub_assignments] = []

        expect(subject.sub_assignments.length).to eq(0)
      end

      it "raises error if any sub assignment is invalid" do
        assignment_hash[:sub_assignments] = assignment_hash[:sub_assignments] + [{ title: "sub_assignment1" }]

        expect do
          subject
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when the discussion_checkpoints feature flag is off" do
      before do
        account.disable_feature!(:discussion_checkpoints)
      end

      it "does not import sub assignments" do
        expect(subject.sub_assignments.length).to eq(0)
      end
    end

    describe ".find_or_create_sub_assignment" do
      subject do
        Importers::AssignmentImporter.find_or_create_sub_assignment(sub_assignment_hash, parent_item)
      end

      let(:parent_item) { course.assignments.create!(title: "parent_assignment") }
      let(:sub_assignment_hash) { assignment_hash[:sub_assignments].first }

      context "when a sub assignment already exists with the same id" do
        before do
          @existing_sub_assignment = parent_item.sub_assignments.create!(
            id: sub_assignment_hash[:id],
            title: "sub_assignment1",
            sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
            context: parent_item.context
          )
        end

        it "does not create a new sub assignment" do
          expect(subject).to eq(@existing_sub_assignment)
        end
      end

      context "when a sub assignment already exists with the same migration id" do
        before do
          @existing_sub_assignment = parent_item.sub_assignments.create!(
            migration_id: sub_assignment_hash[:migration_id],
            title: "sub_assignment1",
            sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
            context: parent_item.context
          )
        end

        it "returns that sub assignment" do
          expect(subject).to eq(@existing_sub_assignment)
        end
      end

      context "when a sub assignment does not exist" do
        it "creates a new sub assignment model instance" do
          expect(subject.id).to be_nil
        end

        it "properly sets parent_assignment_id" do
          expect(subject.parent_assignment_id).to eq(parent_item.id)
        end
      end
    end
  end

  describe "default assignment group" do
    let(:course) { Course.create! }
    let(:migration) { course.content_migrations.create! }
    let(:assignment_hash) do
      {
        migration_id:,
        title: "wiki page assignment",
        submission_types: "wiki_page",
        assignment_group_migration_id: nil,
        wiki_page_migration_id: "mig"
      }
    end

    it "hidden assignment for wiki page has default assignment group" do
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)

      assignment = course.assignments.where(migration_id:).first
      expect(assignment.assignment_group.name).to eq("Imported Assignments")
    end
  end

  describe "assignment group association on wiki page assignment and conditional release course" do
    let(:course) { Course.create! }
    let(:migration) { course.content_migrations.create! }
    let(:assignment_migration_id) { "assignment_migration_id" }
    let(:assignment_group_migration_id) { "assignment_group_migration_id" }
    let(:assignment_group) { course.assignment_groups.create!(migration_id: assignment_group_migration_id) }
    let(:assignment) do
      course.assignments.create!(
        assignment_group:,
        submission_types: "wiki_page",
        migration_id: assignment_migration_id
      )
    end
    let(:assignment_hash) do
      {
        migration_id: assignment_migration_id,
        title: "wiki page assignment",
        submission_types: "wiki_page",
        assignment_group_migration_id:,
        wiki_page_migration_id: "mig"
      }
    end

    before do
      allow_any_instance_of(Course).to receive(:conditional_release?).and_return(true)
    end

    context "when wiki_page_mastery_path_no_assignment_group FF is disabled" do
      before do
        Account.site_admin.disable_feature!(:wiki_page_mastery_path_no_assignment_group)
      end

      it "should not nil the assignment_group" do
        imported_assignment = Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration, assignment)

        expect(imported_assignment.assignment_group).to eq(assignment_group)
      end
    end

    context "when wiki_page_mastery_path_no_assignment_group FF is enabled" do
      before do
        Account.site_admin.enable_feature!(:wiki_page_mastery_path_no_assignment_group)
      end

      context "when submission_types is not wiki_page" do
        it "should not nil the assignment_group" do
          assignment
          assignment_hash[:submission_types] = "somethingelse"

          imported_assignment = Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)

          expect(imported_assignment.assignment_group).to eq(assignment_group)
        end
      end

      context "when not conditional_release?" do
        it "should not nil the assignment_group" do
          allow_any_instance_of(Course).to receive(:conditional_release?).and_return(false)
          assignment

          imported_assignment = Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)

          expect(imported_assignment.assignment_group).to eq(assignment_group)
        end
      end

      context "when conditional_release? and submission_types" do
        it "should set nil the assignment_group" do
          assignment

          imported_assignment = Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)

          expect(imported_assignment.assignment_group).to be_nil
        end
      end
    end
  end

  describe "#associate_assignment_group" do
    let(:course) { Course.create! }
    let(:assignment_group_migration_id) { "assignment_group_migration_id" }
    let(:assignment_group) { course.assignment_groups.create!(migration_id: assignment_group_migration_id) }
    let(:assignment) { course.assignments.create! }
    let(:assignment_hash) { { migration_id:, assignment_group_migration_id: } }

    it "associate assignment group that we find for assignment_group_migration_id from import hash" do
      assignment_group

      Importers::AssignmentImporter.associate_assignment_group(assignment_hash, course, assignment)

      expect(assignment.assignment_group).to eq(assignment_group)
    end

    it "keep the original assignment group on the assignment if there's no assignment_group_migration_id from import hash" do
      assignment_hash.delete(:assignment_group_migration_id)
      assignment.assignment_group = assignment_group

      Importers::AssignmentImporter.associate_assignment_group(assignment_hash, course, assignment)

      expect(assignment.assignment_group).to eq(assignment_group)
    end

    it "default to 'Imported Assignments' if there is no assignment group found for the given assignment_group_migration_id" do
      assignment_hash[:assignment_group_migration_id] = "a random migration id"
      assignment.assignment_group = assignment_group

      Importers::AssignmentImporter.associate_assignment_group(assignment_hash, course, assignment)

      expect(assignment.assignment_group.id).to_not eq(assignment_group.id)
      expect(assignment.assignment_group.name).to eq("Imported Assignments")
    end

    it "default to 'Imported Assignments' if there is no assignment_group_migration_id and assignment has no assignment_group associated" do
      assignment_hash.delete(:assignment_group_migration_id)
      assignment.assignment_group = nil

      Importers::AssignmentImporter.associate_assignment_group(assignment_hash, course, assignment)

      expect(assignment.assignment_group.id).to_not eq(assignment_group.id)
      expect(assignment.assignment_group.name).to eq("Imported Assignments")
    end
  end
end
