require_relative '../../../rails_helper'

RSpec.describe UnitsService::Commands::GetUnitGrades do
  include_context "stubbed_network"

  before do
    @enrollment = student_in_course(:active_all => true)
    @student    = @enrollment.student
    teacher_in_course(course: @course)


    allow(SettingsService).to receive(:get_settings).and_return('auto_due_dates' => nil, 'auto_enrollment_due_dates' => nil)

    allow(@enrollment).to receive(:computed_current_score).and_return(90)
    allow(UnitsService::Queries::GetEnrollment).to receive(:query).and_return(@enrollment)
    allow(PipelineService).to receive(:publish)
    allow(SettingsService).to receive(:get_settings).and_return(
      'enable_unit_grade_calculations' => true
    )

    seed
  end

  it 'calculates a weighted score for each unit' do
    result = described_class.new(course: @course, student: @student, submission: Submission.first).call

    expect(result[:units].count).to eq 6

    result[:units].each do |unit|
      expect(unit[:score]).to eq 75
    end
  end

  def seed
    6.times do |count|
      assignment_group1 = AssignmentGroup.create(name: "assignments", group_weight: 0.5, context: @course)
      assignment_group2 = AssignmentGroup.create(name: "workbook", group_weight: 0.5, context: @course)

      @context_module   = @course.context_modules.create!(name: "Module #{count}") # unit

      @assignment1      = @course.assignments.create!(title: "Assignment #{count} A", workflow_state: 'published', assignment_group: assignment_group1)
      @content_tag1     = @context_module.add_item({id: @assignment1.id, type: 'assignment'}) # item
      @submission1      = @assignment1.submit_homework(@student)
      @submission1.update_attributes!(graded_at: Time.zone.now, grader_id: @teacher.id, score: 50)

      @assignment2      = @course.assignments.create!(title: "Assignment #{count} B", workflow_state: 'published', assignment_group: assignment_group2)
      @content_tag2     = @context_module.add_item({id: @assignment2.id, type: 'assignment'}) # item
      @submission2      = @assignment2.submit_homework(@student)
      @submission2.update_attributes!(graded_at: Time.zone.now, grader_id: @teacher.id, score: 100)
    end
  end
end
