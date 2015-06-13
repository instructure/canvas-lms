require File.expand_path('../../spec_helper', File.dirname(__FILE__))

module BroadcastPolicies
  describe QuizSubmissionPolicy do

    let(:course) do
      mock("Course").tap do |c|
        c.stubs(:available?).returns(true)
        c.stubs(:feature_enabled?).with(:differentiated_assignments).returns(false)
      end
    end
    let(:assignment) do
      mock("Assignment")
    end
    let(:quiz) do
      mock("Quizzes::Quiz").tap do |q|
        q.stubs(:context_id).returns(1)
        q.stubs(:deleted?).returns(false)
        q.stubs(:muted?).returns(false)
        q.stubs(:context).returns(course)
        q.stubs(:assignment).returns(assignment)
        q.stubs(:survey?).returns(false)
      end
    end
    let(:submission) do
      mock("Submission").tap do |s|
        s.stubs(:graded_at).returns(Time.now)
      end
    end
    let(:enrollment) do
      mock("Enrollment") do |e|
        e.stubs(:course_id).returns(1)
      end
    end
    let(:user) do
      mock("User").tap do |u|
        u.stubs(:student_enrollments).returns([enrollment])
      end
    end
    let(:quiz_submission) do
      mock("Quizzes::QuizSubmission").tap do |qs|
        qs.stubs(:quiz).returns(quiz)
        qs.stubs(:submission).returns(submission)
        qs.stubs(:user).returns(user)
        qs.stubs(:context).returns(course)
      end
    end
    let(:policy) { QuizSubmissionPolicy.new(quiz_submission) }

    describe '#should_dispatch_submission_graded?' do
      before do
        quiz_submission.stubs(:changed_state_to).with(:complete).returns true
        quiz_submission.stubs(:changed_in_state).
          with(:pending_review, {:fields => [:fudge_points]}).returns false
      end

      it 'is true when the dependent inputs are true' do
        expect(policy.should_dispatch_submission_graded?).to be_truthy
      end

      def wont_send_when
        yield
        expect(policy.should_dispatch_submission_graded?).to be_falsey
      end

      specify { wont_send_when { quiz.stubs(:assignment).returns nil } }
      specify { wont_send_when { quiz.stubs(:muted?).returns true } }
      specify { wont_send_when { course.stubs(:available?).returns false} }
      specify { wont_send_when { quiz.stubs(:deleted?).returns true } }
      specify { wont_send_when { enrollment.stubs(:course_id).returns 2 } }
      specify { wont_send_when { quiz_submission.stubs(:user).returns nil } }

      specify do
        wont_send_when do
          quiz_submission.stubs(:changed_state_to).with(:complete).returns false
        end
      end

    end

    describe '#should_dispatch_submission_needs_grading?' do
      before { quiz_submission.stubs(:pending_review?).returns false }
      def wont_send_when
        yield
        expect(policy.should_dispatch_submission_needs_grading?).to be_falsey
      end
      it "is true when quiz is pending review" do
        quiz_submission.stubs(:pending_review?).returns true
        expect(policy.should_dispatch_submission_needs_grading?).to eq true
      end
      specify { wont_send_when { quiz.stubs(:assignment).returns nil } }
      specify { wont_send_when { quiz.stubs(:survey?).returns true} }
      specify { wont_send_when { quiz.stubs(:muted?).returns true } }
      specify { wont_send_when { course.stubs(:available?).returns false} }
      specify { wont_send_when { quiz.stubs(:deleted?).returns true } }
      specify { wont_send_when { quiz_submission.stubs(:submission).returns nil } }
      specify { wont_send_when { submission.stubs(:graded_at).returns nil }}
      specify { wont_send_when { submission.stubs(:pending_review?).returns false }}
      specify { wont_send_when { QuizSubmissionPolicy.any_instance.stubs(:user_has_visibility?).returns(false) }}
    end


    describe '#should_dispatch_submission_grade_changed?' do
      def wont_send_when
        yield
        expect(policy.should_dispatch_submission_grade_changed?).to be_falsey
      end

      before do
        quiz_submission.stubs(:changed_in_state).
          with(:complete, :fields => [:score]).returns true
      end

      it 'is true when the necessary inputs are true' do
        expect(policy.should_dispatch_submission_grade_changed?).to be_truthy
      end

      specify { wont_send_when { quiz.stubs(:assignment).returns nil } }
      specify { wont_send_when { quiz.stubs(:muted?).returns true } }
      specify { wont_send_when { course.stubs(:available?).returns false} }
      specify { wont_send_when { quiz.stubs(:deleted?).returns true } }
      specify { wont_send_when { submission.stubs(:graded_at).returns nil }}
      specify { wont_send_when { QuizSubmissionPolicy.any_instance.stubs(:user_has_visibility?).returns(false) }}

      specify do
        wont_send_when do
          quiz_submission.stubs(:changed_in_state).
            with(:complete, :fields => [:score]).returns false
        end
      end
    end

    describe '#when there is no quiz submission' do
      let(:policy) { QuizSubmissionPolicy.new(nil) }
      specify { expect(policy.should_dispatch_submission_graded?).to be_falsey }
      specify { expect(policy.should_dispatch_submission_grade_changed?).to be_falsey }
    end

  end
end
