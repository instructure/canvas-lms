
require_relative '../rails_helper'

RSpec.describe Submission do
  include_context 'stubbed_network'

  let(:observer) { User.create }

  before do
    course_with_student_submissions(:active_all => true)
    @course.enroll_user(observer, "ObserverEnrollment", {:allow_multiple_enrollments => true, :associated_user_id => @student.id})
    @submission = @course.submissions.find_by(user: @student)
  end

  it "returns false on an unconcluded observer enrollment" do
    expect(@submission.send(:user_is_observer?, observer)).to be false
  end

  it "returns true when observer enrollment is concluded" do
    @course.enrollments.each(&:conclude)
    expect(@submission.send(:user_is_observer?, observer)).to be true
  end
end
