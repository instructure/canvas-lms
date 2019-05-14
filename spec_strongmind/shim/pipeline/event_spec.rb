require_relative '../../rails_helper'

RSpec.describe 'pipeline service', type: :model do
  include_context 'stubbed_network'
  let(:course) { create_course }

  before :each do
    teacher, student = create_users(2, return_type: :record)
    @teacher_enrollment = create_enrollment course, teacher, enrollment_type: "TeacherEnrollment"
    @student_enrollment = create_enrollment course, student
  end

  it 'will publish to the pipeline after save'do
    expect(PipelineService).to receive(:publish).with(an_instance_of(StudentEnrollment))
    @student_enrollment.update(workflow_state: 'completed')
  end
end
