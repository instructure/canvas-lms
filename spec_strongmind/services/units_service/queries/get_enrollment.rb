require_relative '../../../rails_helper'

RSpec.describe UnitsService::Queries::GetEnrollment do
  before do
    @student = student_in_course(:active_all => true).user
    @get_enrollment_query = UnitsService::Queries::GetEnrollment
  end

  describe '#query' do
    it 'finds the enrollment for a course/student' do
      result = @get_enrollment_query.query(course: @course, user: @student)

      expect(result.course_id).to eq(@course.id)
      expect(result.user_id).to eq(@student.id)
    end
  end
end
