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

require File.expand_path(File.dirname(__FILE__) + '../../../import_helper')
require File.expand_path(File.dirname(__FILE__) + '../../../lti2_spec_helper')

describe "Importing assignments" do

  SYSTEMS.each do |system|
    if import_data_exists? system, 'assignment'
      it "should import assignments for #{system}" do
        data = get_import_data(system, 'assignment')
        context = get_import_context(system)
        migration = context.content_migrations.create!

        data[:assignments_to_import] = {}
        expect {
          expect(Importers::AssignmentImporter.import_from_migration(data, context, migration)).to be_nil
        }.to change(Assignment, :count).by(0)

        data[:assignments_to_import][data[:migration_id]] = true
        expect {
          Importers::AssignmentImporter.import_from_migration(data, context, migration)
          Importers::AssignmentImporter.import_from_migration(data, context, migration)
        }.to change(Assignment, :count).by(1)
        a = Assignment.where(migration_id: data[:migration_id]).first

        expect(a.title).to eq data[:title]
        expect(a.description).to include(data[:instructions]) if data[:instructions]
        expect(a.description).to include(data[:description]) if data[:description]
        a.due_at = Time.at(data[:due_date].to_i / 1000)
        expect(a.points_possible).to eq data[:grading][:points_possible].to_f
      end
    end
  end

  it "should import grading information when rubric is included" do
    file_data = get_import_data('', 'assignment')
    context = get_import_context('')
    migration = context.content_migrations.create!

    assignment_hash = file_data.find{|h| h['migration_id'] == '4469882339231'}.with_indifferent_access

    rubric = rubric_model(:context => context)
    rubric.migration_id = assignment_hash[:grading][:rubric_id]
    rubric.points_possible = 42
    rubric.save!

    Importers::AssignmentImporter.import_from_migration(assignment_hash, context, migration)
    a = Assignment.where(migration_id: assignment_hash[:migration_id]).first
    expect(a.points_possible).to eq rubric.points_possible
  end

  it "should import association settings when rubric is included" do
    file_data = get_import_data('', 'assignment')
    context = get_import_context('')
    migration = context.content_migrations.create!

    assignment_hash = file_data.find{|h| h['migration_id'] == '4469882339231'}.with_indifferent_access
    rubric_model({context: context, migration_id: assignment_hash[:grading][:rubric_id]})
    assignment_hash[:rubric_use_for_grading] = true
    assignment_hash[:rubric_hide_points] = true
    assignment_hash[:rubric_hide_outcome_results] = true

    Importers::AssignmentImporter.import_from_migration(assignment_hash, context, migration)
    ra = Assignment.where(migration_id: assignment_hash[:migration_id]).first.rubric_association
    expect(ra.use_for_grading).to be true
    expect(ra.hide_points).to be true
    expect(ra.hide_outcome_results).to be true
  end

  it "should import group category into existing group with same name when marked as a group assignment" do
    file_data = get_import_data('', 'assignment')
    context = get_import_context('')
    assignment_hash = file_data.find{|h| h['migration_id'] == '4469882339232'}.with_indifferent_access
    migration = context.content_migrations.create!
    context.group_categories.create! name: assignment_hash[:group_category]

    Importers::AssignmentImporter.import_from_migration(assignment_hash, context, migration)
    a = Assignment.where(migration_id: assignment_hash[:migration_id]).first
    expect(a).to be_has_group_category
    expect(a.group_category.name).to eq assignment_hash[:group_category]
  end

  it "should infer the default name when importing a nameless assignment" do
    course_model
    migration = @course.content_migrations.create!
    nameless_assignment_hash = {
        "migration_id" => "ib4834d160d180e2e91572e8b9e3b1bc6",
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
        "due_at" => 1401947999000,
        "peer_reviews_due_at" => 1401947999000,
        "position" => 6,
        "peer_review_count" => 0
    }
    Importers::AssignmentImporter.import_from_migration(nameless_assignment_hash, @course, migration)
    assignment = @course.assignments.where(migration_id: 'ib4834d160d180e2e91572e8b9e3b1bc6').first
    expect(assignment.title).to eq 'untitled assignment'
  end

  it "should schedule auto peer reviews if dates are not shifted " do
    course_model
    migration = @course.content_migrations.create!
    assign_hash = {
      "migration_id" => "ib4834d160d180e2e91572e8b9e3b1bc6",
      "assignment_group_migration_id" => "i2bc4b8ea8fac88f1899e5e95d76f3004",
      "workflow_state" => "published",
      "title" => "auto peer review assignment",
      "grading_type" => "points",
      "submission_types" => "none",
      "peer_reviews" => true,
      "automatic_peer_reviews" => true,
      "due_at" => 1401947999000,
      "peer_reviews_due_at" => 1401947999000
    }
    expects_job_with_tag('Assignment#do_auto_peer_review') {
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    }
  end

  it "should not schedule auto peer reviews if dates are shifted (it'll be scheduled later)" do
    course_model
    assign_hash = {
      "migration_id" => "ib4834d160d180e2e91572e8b9e3b1bc6",
      "assignment_group_migration_id" => "i2bc4b8ea8fac88f1899e5e95d76f3004",
      "workflow_state" => "published",
      "title" => "auto peer review assignment",
      "grading_type" => "points",
      "submission_types" => "none",
      "peer_reviews" => true,
      "automatic_peer_reviews" => true,
      "due_at" => 1401947999000,
      "peer_reviews_due_at" => 1401947999000
    }
    migration = @course.content_migrations.create!
    allow(migration).to receive(:date_shift_options).and_return(true)
    expects_job_with_tag('Assignment#do_auto_peer_review', 0) {
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    }
  end

  it "should include turnitin_settings" do
    course_model
    expect(@course).to receive(:turnitin_enabled?).at_least(1).and_return(true)
    migration = @course.content_migrations.create!
    nameless_assignment_hash = {
        "migration_id" => "ib4834d160d180e2e91572e8b9e3b1bc6",
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
        "due_at" => 1401947999000,
        "peer_reviews_due_at" => 1401947999000,
        "position" => 6,
        "peer_review_count" => 0,
        "turnitin_enabled" => true,
        "turnitin_settings" => "{\"originality_report_visibility\":\"after_due_date\",\"s_paper_check\":\"1\",\"internet_check\":\"0\",\"journal_check\":\"1\",\"exclude_biblio\":\"1\",\"exclude_quoted\":\"0\",\"exclude_type\":\"1\",\"exclude_value\":\"5\",\"submit_papers_to\":\"1\",\"s_view_report\":\"1\"}"
    }
    Importers::AssignmentImporter.import_from_migration(nameless_assignment_hash, @course, migration)
    assignment = @course.assignments.where(migration_id: 'ib4834d160d180e2e91572e8b9e3b1bc6').first
    expect(assignment.turnitin_enabled).to eq true
    settings = assignment.turnitin_settings
    expect(settings["originality_report_visibility"]).to eq("after_due_date")
    expect(settings["exclude_value"]).to eq("5")

    ["s_paper_check", "journal_check", "exclude_biblio", "exclude_type", "submit_papers_to", "s_view_report"].each do |field|
      expect(settings[field]).to eq("1")
    end

    ["internet_check", "exclude_quoted"].each do |field|
      expect(settings[field]).to eq("0")
    end
  end

  it "should not explode if it tries to import negative points possible" do
    course_model
    assign_hash = {
      "migration_id" => "ib4834d160d180e2e91572e8b9e3b1bc6",
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
    assignment = @course.assignments.where(migration_id: 'ib4834d160d180e2e91572e8b9e3b1bc6').first
    expect(assignment.points_possible).to eq 0
  end

  it "should not clear dates if these are null in the source hash" do
    course_model
    assign_hash = {
      "migration_id" => "ib4834d160d180e2e91572e8b9e3b1bc6",
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
    assignment = @course.assignments.create! :title => "test", :due_at => Time.now, :unlock_at => 1.day.ago, :lock_at => 1.day.from_now, :peer_reviews_due_at => 2.days.from_now, :migration_id => "ib4834d160d180e2e91572e8b9e3b1bc6"
    Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    assignment.reload
    expect(assignment.title).to eq "date clobber or not"
    expect(assignment.due_at).not_to be_nil
    expect(assignment.peer_reviews_due_at).not_to be_nil
    expect(assignment.unlock_at).not_to be_nil
    expect(assignment.lock_at).not_to be_nil
  end

  context 'when assignments use an LTI tool' do
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
        migration_id: "ib4834d160d180e2e91572e8b9e3b1bc6",
        submission_types: 'external_tool',
        external_tool_tag_attributes: { url: tool.url, content: tool },
        points_possible: 10
      )
    end

    let(:assignment_hash) do
      {
        "migration_id" => "ib4834d160d180e2e91572e8b9e3b1bc6",
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
        "external_tool_id" => tool_id
      }
    end

    context 'and a matching tool is installed in the destination' do
      let(:tool) { external_tool_model(context: course.root_account) }
      let(:tool_id) { tool.id }
      let(:tool_url) { tool.url }

      context 'but the matching tool has a different ID' do
        let(:tool_id) { tool.id + 1 }

        it 'matches the tool via URL lookup' do
          expect(subject.external_tool_tag.content).to eq tool
        end
      end

      context 'but the matching tool has a different URL' do
        let(:tool_url) { 'http://google.com/launch/2' }

        it 'updates the URL' do
          expect { subject }.to change { assignment.external_tool_tag.url }.from(tool.url).to tool_url
        end
      end
    end

    context 'and the tool uses LTI 1.3' do
      let(:tool_id) { tool.id }
      let(:tool_url) { tool.url }
      let(:use_1_3) { true }
      let(:dev_key) { DeveloperKey.create! }
      let(:tool) do
        course.context_external_tools.create!(
          consumer_key: 'key',
          shared_secret: 'secret',
          name: 'test tool',
          url: 'http://www.tool.com/launch',
          settings: { use_1_3: use_1_3 },
          workflow_state: 'public',
          developer_key: dev_key
        )
      end
      let(:assignment) do
        course.assignments.create!(
          title: "test",
          due_at: Time.zone.now,
          unlock_at: 1.day.ago,
          lock_at: 1.day.from_now,
          peer_reviews_due_at: 2.days.from_now,
          migration_id: "ib4834d160d180e2e91572e8b9e3b1bc6"
        )
      end

      it 'creates the assignment line item' do
        expect { subject }.to change { assignment.line_items.count }.from(0).to 1
      end

      it 'creates a resource link' do
        expect { subject }.to change { assignment.line_items.first&.resource_link.present? }.from(false).to true
      end

      describe 'line item creation' do
        let(:migration_id) { "ib4834d160d180e2e91572e8b9e3b1bc6" }
        let(:course) { Course.create! }
        let(:migration) { course.content_migrations.create! }
        let(:assignment) do
          Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
          course.assignments.find_by(migration_id: migration_id)
        end
        let(:assignment_hash) do
          {
            migration_id: migration_id,
            title: "my assignment",
            grading_type: 'points',
            points_possible: 123,
            line_items: line_items_array,
            external_tool_url: assignment_tool_url,
            submission_types: assignment_submission_types,
          }.compact.with_indifferent_access
        end

        let(:assignment_submission_types) { 'external_tool' }
        let(:assignment_tool_url) { tool.url }

        let(:line_items_array) { [line_item_hash] }
        let(:line_item_hash) do
          {
            coupled: coupled,
          }.merge(extra_line_item_params).with_indifferent_access
        end
        let(:extra_line_item_params) { {} }
        let(:coupled) { false }

        let(:created_resource_link_ids) { Lti::ResourceLink.where(context: assignment).pluck(:id) }

        shared_examples_for 'a single imported line item' do
          subject { assignment.line_items.take }

          it 'creates exactly one line item' do
            expect(assignment.line_items.count).to eq(1)
          end

          it 'sets the client_id' do
            expect(subject.client_id).to eq(tool.global_developer_key_id)
          end

          it "defaults label to the assignment's name" do
            expect(subject.label).to eq(assignment_hash[:title])
          end

          it "defaults score_maximum to the assignment's points possible" do
            expect(subject.score_maximum).to eq(assignment_hash[:points_possible])
          end

          context 'when resource_id and tag are given' do
            let(:extra_line_item_params) { super().merge(resource_id: 'abc', tag: 'def') }

            it 'sets them on the line item' do
              expect(subject.resource_id).to eq('abc')
              expect(subject.tag).to eq('def')
            end
          end

          context 'when label is given' do
            let(:extra_line_item_params) { super().merge(label: 'ghi') }

            it "sets label on the line item but doesn't affect the assignment name" do
              expect(subject.label).to eq('ghi')
              expect(assignment.name).to eq(assignment_hash[:title])
            end
          end

          context 'when score_maximum is given' do
            let(:extra_line_item_params) { super().merge(score_maximum: 98765) }

            it "sets score_maximum on the line item but doesn't affect the assignment points_possible" do
              expect(subject.score_maximum).to eq(98765)
              expect(assignment.points_possible).to eq(assignment_hash[:points_possible])
            end
          end

          context 'when extensions is set' do
            let(:extra_line_item_params) { super().merge(extensions: {foo: 'bar'}.to_json) }

            it 'sets extensions on the line item' do
              expect(subject.extensions).to eq('foo' => 'bar')
            end
          end
        end

        describe 'an external tool assignment with no line items' do
          let(:line_items_array) { [] }
          let(:coupled) { true }

          it 'creates a default coupled line item with an Lti::ResourceLink' do
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

        describe 'an external tool assignment with a coupled line item' do
          let(:coupled) { true }

          it_behaves_like 'a single imported line item'

          it 'creates one Lti::ResourceLink for the assignment and the line item' do
            expect(created_resource_link_ids).to eq([assignment.line_items.take.lti_resource_link_id])
          end
        end

        describe 'a submission_type=none assignment (AGS-created) with a uncoupled line item' do
          let(:assignment_submission_types) { 'none' }
          let(:assignment_tool_url) { nil }
          let(:extra_line_item_params) { {client_id: tool.global_developer_key_id} }

          it_behaves_like 'a single imported line item'

          it 'does not create an Lti::ResourceLink' do
            expect(created_resource_link_ids).to eq([])
            expect(assignment.line_items.take.lti_resource_link_id).to eq(nil)
          end

          context 'without an explicit client_id' do
            let(:extra_line_item_params) { {} }

            it 'fails to import' do
              expect {
                assignment
              }.to raise_error(/Client can't be blank/)
            end
          end

        end

        describe 'an external tool assignment with an uncoupled line item (AGS-created assignment)' do
          it_behaves_like 'a single imported line item'

          it 'creates one Lti::ResourceLink for the assignment and the line item' do
            expect(created_resource_link_ids).to eq([assignment.line_items.take.lti_resource_link_id])
          end
        end

        describe 'an external tool assignment with multiple uncoupled line items' do
          let(:line_items_array) do
            [
              { coupled: false, label: 'abc', score_maximum: 123 },
              { coupled: false, label: 'def' },
              { coupled: false },
            ]
          end

          it 'creates all line items' do
            expect(assignment.line_items.pluck(:label, :coupled, :score_maximum).sort_by(&:first)).to eq([
              ['abc', false, 123],
              ['def', false, assignment_hash[:points_possible]],
              [assignment_hash[:title], false, assignment_hash[:points_possible]],
            ])
          end

          it 'creates the line items with the same Lti::ResourceLink' do
            expect(assignment.line_items.pluck(:lti_resource_link_id)).to \
              eq(created_resource_link_ids * 3)
          end
        end

        describe 'an external tool assignment with a coupled line item and additional uncoupled line items' do
          let(:line_items_array) do
            [
              { coupled: false, label: 'abc', score_maximum: 123 },
              { coupled: false, label: 'abc', score_maximum: 123 },
              { coupled: true, label: 'def' },
              { coupled: false },
            ]
          end

          let(:expected_created_line_items_fields) do
            [
              ['abc', false, 123],
              ['abc', false, 123],
              ['def', true, assignment_hash[:points_possible]],
              [assignment_hash[:title], false, assignment_hash[:points_possible]],
            ]
          end

          it 'creates all line items' do
            expect(assignment.line_items.pluck(:label, :coupled, :score_maximum).sort_by(&:first)).to \
              eq(expected_created_line_items_fields)
          end

          it 'creates the line items with the same Lti::ResourceLink' do
            expect(assignment.line_items.pluck(:lti_resource_link_id)).to \
              eq(created_resource_link_ids * 4)
          end

          context 'when the same line items are imported again in an additional run' do
            it "doesn't create the same line items over again" do
              assignment
              expect {
                Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
                Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
              }.to_not change { Assignment.count }
              expect(assignment.line_items.pluck(:label, :coupled, :score_maximum).sort_by(&:first)).to \
                eq(expected_created_line_items_fields)
            end
          end
        end

      end

    end
  end

  describe '#create_tool_settings' do
    include_context 'lti2_spec_helper'

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
        'custom_var_1' => 'value one',
        'custom_var_2' => 'value two',
      }
    end

    let(:custom_parameters) do
      {
        'custom_parameter_1' => 'param value one',
        'custom_parameter_2' => 'param value two',
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

    it 'does nothing if the tool settings is blank' do
      Importers::AssignmentImporter.create_tool_settings({}, tool_proxy, assignment)
      expect(tool_proxy.tool_settings.length).to eq 0
    end

    it 'creates the tool setting if codes match' do
      Importers::AssignmentImporter.create_tool_settings(tool_setting, tool_proxy, assignment)
      expect(tool_proxy.reload.tool_settings.length).to eq 1
    end

    it 'uses the new assignment "lti_context_id" as the resource link id' do
      Importers::AssignmentImporter.create_tool_settings(tool_setting, tool_proxy, assignment)
      expect(tool_proxy.tool_settings.first.resource_link_id).to eq assignment.lti_context_id
    end

    it 'sets the context to the course of the assignment' do
      Importers::AssignmentImporter.create_tool_settings(tool_setting, tool_proxy, assignment)
      expect(tool_proxy.tool_settings.first.context).to eq course
    end

    it 'sets the custom data' do
      Importers::AssignmentImporter.create_tool_settings(tool_setting, tool_proxy, assignment)
      expect(tool_proxy.tool_settings.first.custom).to eq(custom)
    end

    it 'sets the custom data parameters' do
      Importers::AssignmentImporter.create_tool_settings(tool_setting, tool_proxy, assignment)
      expect(tool_proxy.tool_settings.first.custom_parameters).to eq(custom_parameters)
    end

    it 'does not attempt to recreate tool settings if they already exist' do
      tool_proxy.tool_settings.create!(
        context: course,
        tool_proxy: tool_proxy,
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
    include_context 'lti2_spec_helper'

    let(:migration_id) { "ib4834d160d180e2e91572e8b9e3b1bc6" }
    let(:resource_type_code) {'123'}
    let(:vendor_code) {'abc'}
    let(:product_code) {'qrx'}
    let(:visibility) {'after_grading'}
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
          resource_type_code: resource_type_code,
          vendor_code: vendor_code,
          product_code: product_code,
          visibility: visibility
        }
      }
    end

    context 'when plagiarism detection tools are being imported' do
      let(:course) { course_model }
      let(:migration) { course.content_migrations.create! }
      let(:assignment) do
        course.assignments.create!(
          title: "test",
          due_at: Time.zone.now,
          unlock_at: 1.day.ago,
          lock_at: 1.day.from_now,
          peer_reviews_due_at: 2.days.from_now,
          migration_id: migration_id
        )
      end

      it "creates a assignment_configuration_tool_lookup" do
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
          tool_type: 'Lti::MessageHandler',
          context_type: 'Course'
        )

        Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
        assignment.reload
        expect(assignment.assignment_configuration_tool_lookups.count).to eq 1
      end

      it "creates assignment_configuration_tool_lookups with the proper context_type" do
        actl1 = assignment.assignment_configuration_tool_lookups.create!(
          tool_vendor_code: vendor_code,
          tool_product_code: product_code,
          tool_resource_type_code: resource_type_code,
          tool_type: 'Lti::MessageHandler',
          context_type: 'Account'
        )

        Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
        assignment.reload
        expect(assignment.assignment_configuration_tool_lookups.count).to eq 2
        new_actls = assignment.assignment_configuration_tool_lookups.reject do |actl|
          actl.id == actl1.id
        end
        expect(new_actls.map(&:context_type)).to eq(['Course'])
      end
    end

    it "sets the vendor/product/resource_type codes" do
      course_model
      migration = @course.content_migrations.create!
      assignment = @course.assignments.create! :title => "test", :due_at => Time.now, :unlock_at => 1.day.ago, :lock_at => 1.day.from_now, :peer_reviews_due_at => 2.days.from_now, :migration_id => migration_id
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
      assignment.reload
      tool_lookup = assignment.assignment_configuration_tool_lookups.first
      expect(tool_lookup.tool_vendor_code).to eq vendor_code
      expect(tool_lookup.tool_product_code).to eq product_code
      expect(tool_lookup.tool_resource_type_code).to eq resource_type_code
    end

    it "sets the tool_type to 'LTI::MessageHandler'" do
      course_model
      migration = @course.content_migrations.create!
      assignment = @course.assignments.create! :title => "test", :due_at => Time.now, :unlock_at => 1.day.ago, :lock_at => 1.day.from_now, :peer_reviews_due_at => 2.days.from_now, :migration_id => migration_id
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
      assignment.reload
      tool_lookup = assignment.assignment_configuration_tool_lookups.first
      expect(tool_lookup.tool_type).to eq 'Lti::MessageHandler'
    end

    it "sets the visibility" do
      course_model
      migration = @course.content_migrations.create!
      assignment = @course.assignments.create! :title => "test", :due_at => Time.now, :unlock_at => 1.day.ago, :lock_at => 1.day.from_now, :peer_reviews_due_at => 2.days.from_now, :migration_id => migration_id
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
      assignment.reload
      expect(assignment.turnitin_settings.with_indifferent_access[:originality_report_visibility]).to eq visibility
    end

    it 'adds a warning to the migration without an active tool_proxy' do
      course_model
      migration = @course.content_migrations.create!
      @course.assignments.create! :title => "test", :due_at => Time.now, :unlock_at => 1.day.ago, :lock_at => 1.day.from_now, :peer_reviews_due_at => 2.days.from_now, :migration_id => migration_id
      expect(migration).to receive(:add_warning).with("We were unable to find a tool profile match for vendor_code: \"abc\" product_code: \"qrx\".")
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    end

    it "doesn't add a warning to the migration if there is an active tool_proxy" do
      allow(Lti::ToolProxy).
        to receive(:find_active_proxies_for_context_by_vendor_code_and_product_code) {[tool_proxy]}
      course_model
      migration = @course.content_migrations.create!
      @course.assignments.create! :title => "test", :due_at => Time.now, :unlock_at => 1.day.ago, :lock_at => 1.day.from_now, :peer_reviews_due_at => 2.days.from_now, :migration_id => migration_id
      expect(migration).to_not receive(:add_warning).with("We were unable to find a tool profile match for vendor_code: \"abc\" product_code: \"qrx\".")
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    end
  end

  describe "post_policy" do
    let(:migration_id) { "ib4834d160d180e2e91572e8b9e3b1bc6" }
    let(:course) { Course.create! }
    let(:migration) { course.content_migrations.create! }
    let(:assignment_hash) do
      {
        "migration_id" => migration_id,
        "post_policy" => {"post_manually" => false}
      }.with_indifferent_access
    end

    let(:imported_assignment) do
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
      course.assignments.find_by(migration_id: migration_id)
    end

    before(:each) do
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
    let(:migration_id) { "ib4834d160d180e2e91572e8b9e3b1bc6" }
    let(:course) { Course.create! }
    let(:account) { course.account }
    let(:migration) { course.content_migrations.create! }
    let(:assignment_hash) do
      {
        "migration_id" => migration_id,
        "title" => "post_to_sis",
        "post_to_sis" => false,
        "date_shift_options" => {
          "remove_dates": true
        }
      }.with_indifferent_access
    end

    let(:imported_assignment) do
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
      course.assignments.find_by(migration_id: migration_id)
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
      expect(migration).to receive(:add_warning).with("The Sync to SIS setting could not be enabled for the assignment \"#{assignment_hash['title']}\" without a due date.")
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
    end

    it "sets post_to_sis if provided" do
      assignment_hash[:post_to_sis] = true
      expect(imported_assignment.post_to_sis).to eq(assignment_hash['post_to_sis'])
    end

    it "does not change the value set on the assignment if previously imported" do
      imported_assignment
      imported_assignment.update(post_to_sis: !assignment_hash['post_to_sis'])
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
      imported_assignment.reload
      expect(imported_assignment.post_to_sis).not_to eq(assignment_hash['post_to_sis'])
    end

    it "does change the value if the blueprint has been locked" do
      imported_assignment
      imported_assignment.update(post_to_sis: !assignment_hash['post_to_sis'])
      allow(Assignment).to receive(:where).and_return([imported_assignment])
      allow(imported_assignment).to receive(:editing_restricted?).with(:any).and_return(true)
      Importers::AssignmentImporter.import_from_migration(assignment_hash, course, migration)
      imported_assignment.reload
      expect(imported_assignment.post_to_sis).to eq(assignment_hash['post_to_sis'])
    end
  end
end
