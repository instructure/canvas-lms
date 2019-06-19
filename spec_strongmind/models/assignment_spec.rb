require_relative '../rails_helper'

RSpec.describe 'Assignment', type: :model do
  include_context 'stubbed_network'

  describe 'Callbacks' do
    describe 'after_save' do
      let!(:assignment) { assignment_model }

      it 'publishes to the Pipeline' do
        expect(PipelineService).to receive(:publish).with(an_instance_of(Assignment))
        assignment.save
      end
    end
  end

  describe 'is_excused?' do
    let!(:assignment) { assignment_model }

    context 'when user passed is nil' do
      it 'does not throw an exception' do
        nil_user = double('user', nil?: true)

        expect(nil_user).not_to receive(:id)
        expect {
          assignment.is_excused?(nil_user)
        }.not_to raise_error
      end

      it 'returns false' do
        expect(assignment.is_excused?(nil)).to be false
      end
    end

    context 'when user passed is an excused User' do
      before do
        student_in_course(active_all: true)
        teacher_in_course(course: @course)
      end

      it 'returns true' do
        @assignment = @course.assignments.create!(:title => 'Assignment', :points_possible => 10)

        @assignment.grade_student(@student, grader: @teacher, excused: true)

        expect(@assignment.is_excused?(@student)).to be true
      end
    end
  end
end