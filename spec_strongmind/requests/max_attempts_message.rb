require_relative '../rails_helper'

RSpec.describe "Redirect with max attempts", type: :request do
  include_context 'stubbed_network'

  before(:each) do
    student_in_course(active_all: true)
    course_with_student_logged_in(course: @course)
    @module1 = @course.context_modules.create!(:name => "Module 1")

    @min_score_assignment = @course.assignments.create!(:name => "Assignment 3: min score", :submission_types => ["online_text_entry"], :points_possible => 50, migration_id: '12345')
    @min_score_assignment.publish
    @min_score_assignment_tag = @module1.add_item(:id => @min_score_assignment.id, :type => 'assignment', :title => 'Assignment 2: min score')

    @regular_assignment = @course.assignments.create!(:name => "Assignment 1: pls submit", :submission_types => ["online_text_entry"], :points_possible => 25)
    @regular_assignment.publish
    @regular_assignment_tag = @module1.add_item(:id => @regular_assignment.id, :type => 'assignment', :title => 'Assignment: requires submission')
    
    @submission = @student.submissions.find_by(assignment: @min_score_assignment)
    @submission.update_columns({:score => 0, :grader_id => -1, :attempt => 3})
    Version.create(:versionable => @submission, :yaml => @submission.attributes.to_yaml)

    allow(SettingsService).to receive(:get_settings).with(object: 'assignment', id: @min_score_assignment.migration_id).and_return('max_attempts' => 3)
    allow(SettingsService).to receive(:get_settings).with(object: :course, id: @course.id).and_return('passing_threshold' => 70.0)
    allow(SettingsService).to receive(:get_settings).with(object: :enrollment, id: @student.id).and_return('sequence_control' => 'on')
    allow_any_instance_of(CourseProgress).to receive(:current_content_tag).and_return(@min_score_assignment_tag)
  end

  it "has maxed out attempts" do
    get course_context_modules_item_redirect_path(@course, @regular_assignment_tag)
    expect(@controller.instance_variable_get(:@maxed_out)).to be true
  end

  context "max attempts higher than attempts" do
    before do
      allow(SettingsService).to receive(:get_settings).with(object: 'assignment', id: @min_score_assignment.migration_id).and_return('max_attempts' => 5)
    end

    it "returns false" do
      get course_context_modules_item_redirect_path(@course, @regular_assignment_tag)
      expect(@controller.instance_variable_get(:@maxed_out)).to be false
    end
  end

  context "no passing threshold" do
    before do
      allow(SettingsService).to receive(:get_settings).with(object: :course, id: @course.id).and_return('passing_threshold' => nil)
    end

    it "does not assign" do
      get course_context_modules_item_redirect_path(@course, @regular_assignment_tag)
      expect(@controller.instance_variable_get(:@maxed_out)).to be nil
    end
  end
end