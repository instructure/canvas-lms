#
# Copyright (C) 2011 Instructure, Inc.
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
    migration.stubs(:date_shift_options).returns(true)
    expects_job_with_tag('Assignment#do_auto_peer_review', 0) {
      Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    }
  end

  it "should include turnitin_settings" do
    course_model
    @course.expects(:turnitin_enabled?).at_least(1).returns(true)
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
    migration.stubs(:date_shift_options).returns(true)
    Importers::AssignmentImporter.import_from_migration(assign_hash, @course, migration)
    assignment = @course.assignments.where(migration_id: 'ib4834d160d180e2e91572e8b9e3b1bc6').first
    expect(assignment.points_possible).to eq 0
  end

end
