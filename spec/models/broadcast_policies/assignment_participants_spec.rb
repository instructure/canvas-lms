require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe BroadcastPolicies::AssignmentParticipants do
  before :once do
    course_with_student(active_all: true)
    assignment_model course: @course
    @excluded_ids = nil
  end

  subject do
    BroadcastPolicies::AssignmentParticipants.new(@assignment, @excluded_ids)
  end

  describe '#to' do
    it 'includes students with access to the assignment' do
      expect(subject.to).to include(@student)
    end

    context 'with students whose enrollments have not yet started' do
      before :once do
        student_in_course({
          course: @course,
          start_at: 1.month.from_now
        })
      end

      it 'excludes said students' do
        expect(subject.to).not_to include(@student)
      end
    end

    context 'when provided with excluded_ids' do
      before :once do
        student_in_course(active_all: true)
        @excluded_ids = [@student.id]
      end

      it 'excludes students with provided ids' do
        expect(subject.to).not_to include(@student)
      end
    end
  end
end
