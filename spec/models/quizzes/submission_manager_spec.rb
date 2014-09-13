#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::SubmissionManager do
  describe '#find_or_create_submission' do
    let(:test_user) { user }

    before(:each) do
      course
      @course.root_account.disable_feature!(:draft_state)
      @quiz = @course.quizzes.create! :title => "hello"
    end

    context 'for a masquerading user' do
      it 'uses to_s on the user to query the db when temporary is set to false' do
        @quiz.quiz_submissions.create!(temporary_user_code: "asdf")
        stub_user = stub(to_s: "asdf")

        s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(stub_user, false)

        s.temporary_user_code.should == "asdf"
      end

      it 'uses to_s on the user to query the db when temporary is set to true' do
        @quiz.quiz_submissions.create!(temporary_user_code: "asdf")
        stub_user = stub(to_s: "asdf")

        s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(stub_user, true)

        s.temporary_user_code.should == "asdf"
      end
    end

    context 'for a temporary user' do
      it 'uses a temporary user code to query the db' do
        @quiz.quiz_submissions.create!(temporary_user_code: "user_#{test_user.id}")

        s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(test_user, true)

        s.temporary_user_code.should == "user_#{test_user.id}"
      end
    end


    context 'for a non-temporary user' do
      it 'uses the user id to query the db' do
        submission = @quiz.quiz_submissions.create!(user: test_user)

        s = nil
        expect {
          s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(test_user)
        }.to_not change { Quizzes::QuizSubmission.count }

        s.user.should == test_user
        s.should == submission
      end
    end

    context 'for existing submissions' do
      it 'fetches the submission from the db and does not change an existing workflow state' do
        submission = @quiz.quiz_submissions.create!(user: test_user)
        submission.update_attribute :workflow_state, 'graded'
        Quizzes::QuizSubmission.any_instance.expects(:save!).never
        s = nil
        expect {
          s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(test_user)
        }.to_not change { Quizzes::QuizSubmission.count }
        s.should == submission
        s.workflow_state.should == 'graded'
      end
    end

    context 'for a non-existant submissions' do
      it 'creates new submission and set the workflow state' do
        s = nil
        expect {
          s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(test_user, false, "preview")
        }.to change { Quizzes::QuizSubmission.count }.by(1)
        s.workflow_state.should == "preview"
      end

      it 'defaults workflow state to untaken if not set' do
        s = nil
        expect {
          s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(test_user)
        }.to change { Quizzes::QuizSubmission.count }.by(1)
        s.workflow_state.should == "untaken"
      end
    end
  end
  describe "outstanding submissions by quiz" do
    before do
      course
      @quiz = @course.quizzes.create!(:title => "Outstanding")
      @quiz.quiz_questions.create!(:question_data => multiple_choice_question_data)
      @quiz.generate_quiz_data
      @quiz.save
      @submission = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@user, false)
      @submission.end_at = 20.minutes.ago
      @submission.save
    end
    it 'should be overdue and need_grading' do
      @submission.overdue?.should be true
      @submission.needs_grading?.should be true
    end
    it "should #find_outstanding_submissions_in_quiz" do
      subs = Quizzes::SubmissionManager.find_outstanding_submissions_in_quiz(@quiz)
      subs.size.should == 1
      subs.first.id.should == @submission.id
    end
    it 'should force grading to close the submission' do
      subs = Quizzes::SubmissionManager.find_outstanding_submissions_in_quiz(@quiz)
      Quizzes::SubmissionManager.grade_outstanding_submissions_in_quiz(subs)
      subs = Quizzes::SubmissionManager.find_outstanding_submissions_in_quiz(@quiz)
      subs.size.should == 0
    end
  end
  describe '#grade_outstanding_submissions_in_course' do
    it 'should work' do
      student = student_in_course(active_all: true).user
      quizzes = 2.times.map { @course.quizzes.create! }

      ungraded_qs = quizzes[0].generate_submission(student).tap do |qs|
        qs.submission_data = {}
        qs.end_at = 5.minutes.ago
        qs.save!
      end

      graded_qs = quizzes[1].generate_submission(student).tap do |qs|
        qs.complete!({})
      end

      ungraded_qs.needs_grading?.should be true
        graded_qs.needs_grading?.should be false

      described_class.grade_outstanding_submissions_in_course(student.id,
        @course.id, @course.class.to_s)

      ungraded_qs.reload
      ungraded_qs.needs_grading?.should be false
    end
  end
end
