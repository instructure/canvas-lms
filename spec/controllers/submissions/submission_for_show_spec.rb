# Copyright (C) 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Submissions::SubmissionForShow do
  before :once do
    course_with_student(active_all: true)
    assignment_model(course: @course)
    @options = {
      assignment_id: @assignment.id,
      id: @student.id
    }
  end
  subject { Submissions::SubmissionForShow.new(@course, @options) }

  describe '#assignment' do
    it 'returns assignment found with provided assignment_id' do
      expect(subject.assignment).to eq @assignment
    end
  end

  describe '#user' do
    it 'returns user found with provided id' do
      expect(subject.user).to eq @user
    end
  end

  describe '#submission' do
    it 'instantiates a new submission when one is not present' do
      expect(subject.submission).to be_new_record
    end

    context 'when submission exists' do
      before :once do
        submission_model({
          assignment: @assignment,
          body: 'here my assignment',
          submission_type: 'online_text_entry',
          user: @student
        })
        @submission.submitted_at = 3.hours.ago
        @submission.save
      end

      it 'returns existing submission when present' do
        expect(subject.submission).to eq @submission
      end

      # Note that submission_history returns a zero-indexed array,
      # and even though I couldn't believe it, that is what is passed
      # to the controller as the version query param.
      context 'when version & preview params are provided' do
        before :once do
          @options = @options.merge({ preview: true, version: 0 })
        end

        it 'returns version from submission history' do
          expect {
            @submission.with_versioning(explicit: true) do
              @submission.submitted_at = 1.hour.ago
              @submission.save
            end
          }.to change(@submission.versions, :count), 'precondition'
          expect(@submission.version_number).to eq(2), 'precondition'

          expect(subject.submission.version_number).to eq 1
        end

        context 'when assignment is a quiz' do
          before :once do
            quiz_with_submission
            @assignment = @quiz.assignment
            submission = @quiz.assignment.submissions.where(user_id: @student).first
            submission.quiz_submission.with_versioning(true) do
              submission.quiz_submission.update_attribute(:finished_at, 1.hour.ago)
            end
            @options = @options.merge({ preview: true, version: submission.quiz_submission.versions.last.number, assignment_id: @assignment.id })
          end

          it 'ignores version params' do
            expect(subject.submission.version_number).not_to eq @options[:version]
          end
        end
      end
    end
  end
end
