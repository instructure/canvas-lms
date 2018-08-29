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
          tool_type: 'Lti::MessageHandler'
        )

        Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
        assignment.reload
        expect(assignment.assignment_configuration_tool_lookups.count).to eq 1
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

    it "doesn't add a warning to the migratio if there is an active tool_proxy" do
      tool_proxy_double = double("ToolProxy", preload: [tool_proxy])
      allow(Lti::ToolProxy).
        to receive(:find_active_proxies_for_context_by_vendor_code_and_product_code) {tool_proxy_double}
      course_model
      migration = @course.content_migrations.create!
      @course.assignments.create! :title => "test", :due_at => Time.now, :unlock_at => 1.day.ago, :lock_at => 1.day.from_now, :peer_reviews_due_at => 2.days.from_now, :migration_id => migration_id
      expect(migration).to_not receive(:add_warning).with("We were unable to find a tool profile match for vendor_code: \"abc\" product_code: \"qrx\".")
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    end

  end

end
