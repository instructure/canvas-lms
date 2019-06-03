require_relative '../rails_helper'

RSpec.describe CourseProgress do
  include_context 'stubbed_network'

  let(:user) { user_factory }
  let(:user_2) { user_factory }
  let(:observer) do
    _u = user_factory
    _u.observed_users << user_2
    _u
  end
  let(:observer_2) do
    _u2 = user_factory
    _u2.observed_users << user
    _u2.observed_users << observer
    _u2
  end
  let(:course) { course_factory }
  let(:course_progress_observer) { CourseProgress.new(course, observer) }
  let(:observer_enrollment) { Enrollment.create(user: observer, course: course, type: 'ObserverEnrollment', associated_user_id: user.id) }
  let(:course_progress_observer_2) { CourseProgress.new(course, observer_2) }
  let(:observer_enrollment_3) { Enrollment.create(user: observer_2, course: course, type: 'ObserverEnrollment', associated_user_id: observer.id) }
  let(:course_progress_student) { CourseProgress.new(course, user) }
  let(:student_enrollment) { Enrollment.create(user: user, course: course, type: 'StudentEnrollment') }
  let(:course_progress_student_2) { CourseProgress.new(course, user_2) }

  describe "#find_user_id" do
    it 'returns the first observed user' do
      Enrollment.create(user: observer, course: course, type: 'ObserverEnrollment', associated_user_id: user.id)
      Enrollment.create(user: observer_2, course: course, type: 'ObserverEnrollment', associated_user_id: user.id)
      expect(course_progress_observer.send(:find_user_id)).to eq(user.id)
      expect(course_progress_observer_2.send(:find_user_id)).to eq(user.id)
    end

    it 'returns the user if they have no observers' do
      expect(course_progress_student.send(:find_user_id)).to eq(user.id)
    end
  end

  describe "#allow_course_progress?" do
    before do
      Enrollment.create(user: observer, course: course, type: 'ObserverEnrollment', associated_user_id: user.id)
      Enrollment.create(user: observer_2, course: course, type: 'ObserverEnrollment', associated_user_id: user.id)
    end

    it "returns true if the user is enrolled as a student" do
      allow(@course).to receive(:module_based?).and_return(true)
      expect(course).to receive(:user_is_student?).with(user, :include_all=>true).and_return(true)
      expect(course_progress_student.send(:allow_course_progress?)).to be true
    end

    it "returns true if the user is observing a student" do
      allow(@course).to receive(:module_based?).and_return(true)
      expect(course).to receive(:user_is_student?).with(observer, :include_all=>true).and_return(false)
      expect(course).to receive(:user_is_student?).with(user, :include_all=>true).and_return(true)
      expect(course_progress_observer.send(:allow_course_progress?)).to be true
    end
  end

  describe "#excused_submission_count" do
    context "with excused submission" do
      let(:excused_submission_count) { rand(2..5) }

      it "counts excused submissions" do
        excused_submission_count.times do
          Submission.create!(user: user, assignment: Assignment.create(course: course), excused: true)
        end

        expect(course_progress_student.send(:excused_submission_count)).to eq excused_submission_count
      end
    end
  end

  describe "#requirement_count" do
    context "with excused submission" do
      before do
        excused_submission_count.times do
          Submission.create!(user: user, assignment: Assignment.create(course: course), excused: true)
        end
      end

      let(:excused_submission_count) { 6 }
      let(:fake_requirements) { Array.new(excused_submission_count + 1) }
      let(:fake_completed_reqs) { Array.new(excused_submission_count + 1) }

      it "subtracts excused submissions from requirement count" do
        allow(course_progress_student).to receive(:requirements).and_return(fake_requirements)
        expect(course_progress_student.requirement_count).to eq 1
      end

      it "subtracts excused submissions from requirement completed count" do
        allow(course_progress_student).to receive(:requirements_completed).and_return(fake_completed_reqs)
        expect(course_progress_student.requirement_completed_count).to eq 1
      end

      it "doesnt have more completed requirements than total requirements" do
        allow(course_progress_student).to receive(:requirements).and_return(fake_requirements)
        allow(course_progress_student).to receive(:requirements_completed).and_return(fake_completed_reqs)

        expect(course_progress_student.requirement_completed_count).to be <= course_progress_student.requirement_count
      end
    end
  end
end
