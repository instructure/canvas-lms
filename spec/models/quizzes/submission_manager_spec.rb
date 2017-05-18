#
# Copyright (C) 2014 - present Instructure, Inc.
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
    let(:test_user) { user_factory }

    before(:each) do
      course_factory
      @quiz = @course.quizzes.create! :title => "hello"
    end

    context 'for a masquerading user' do
      it 'uses to_s on the user to query the db when temporary is set to false' do
        @quiz.quiz_submissions.create!(temporary_user_code: "asdf")
        stub_user = stub(to_s: "asdf")

        s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(stub_user, false)

        expect(s.temporary_user_code).to eq "asdf"
      end

      it 'uses to_s on the user to query the db when temporary is set to true' do
        @quiz.quiz_submissions.create!(temporary_user_code: "asdf")
        stub_user = stub(to_s: "asdf")

        s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(stub_user, true)

        expect(s.temporary_user_code).to eq "asdf"
      end
    end

    context 'for a temporary user' do
      it 'uses a temporary user code to query the db' do
        @quiz.quiz_submissions.create!(temporary_user_code: "user_#{test_user.id}")

        s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(test_user, true)

        expect(s.temporary_user_code).to eq "user_#{test_user.id}"
      end
    end


    context 'for a non-temporary user' do
      it 'uses the user id to query the db' do
        submission = @quiz.quiz_submissions.create!(user: test_user)

        s = nil
        expect {
          s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(test_user)
        }.to_not change { Quizzes::QuizSubmission.count }

        expect(s.user).to eq test_user
        expect(s).to eq submission
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
        expect(s).to eq submission
        expect(s.workflow_state).to eq 'graded'
      end
    end

    context 'for a non-existant submissions' do
      it 'creates new submission and set the workflow state' do
        s = nil
        expect {
          s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(test_user, false, "preview")
        }.to change { Quizzes::QuizSubmission.count }.by(1)
        expect(s.workflow_state).to eq "preview"
      end

      it 'defaults workflow state to untaken if not set' do
        s = nil
        expect {
          s = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(test_user)
        }.to change { Quizzes::QuizSubmission.count }.by(1)
        expect(s.workflow_state).to eq "untaken"
      end
    end
  end
end
