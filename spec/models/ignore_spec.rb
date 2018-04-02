#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe Ignore do
  before :once do
    course_with_student(active_all: true)
    assignment_model(course: @course)
    quiz_model(course: @course)
    reviewer = @student
    reviewee = student_in_course(course: @course).user
    submission = @assignment.submissions.where(user: reviewee).take
    @ar = submission.assessment_requests.create!(assessor: reviewer, user: reviewee, assessor_asset: reviewer)
    @ignore_assign = Ignore.create!(asset: @assignment, user: @student, purpose: 'submitting')
    @ignore_quiz = Ignore.create!(asset: @quiz, user: @student, purpose: 'submitting')
    @ignore_ar = Ignore.create!(asset: @ar, user: @student, purpose: 'reviewing')
  end

  describe '#cleanup' do
    it 'should delete ignores for deleted assignments' do
      @assignment.update_attributes!(workflow_state: 'deleted', updated_at: 2.months.ago)
      assignment2 = assignment_model(course: @course)
      ignore2 = Ignore.create!(asset: assignment2, user: @student, purpose: 'submitting')
      assignment2.destroy_permanently!
      Ignore.cleanup
      expect {@ignore_assign.reload}.to raise_error ActiveRecord::RecordNotFound
      expect {ignore2.reload}.to raise_error ActiveRecord::RecordNotFound
    end

    it 'should delete ignores for deleted quizzes' do
      @quiz.update_attributes!(workflow_state: 'deleted', updated_at: 2.months.ago)
      quiz2 = quiz_model(course: @course)
      ignore2 = Ignore.create!(asset: quiz2, user: @student, purpose: 'submitting')
      quiz2.destroy_permanently!
      Ignore.cleanup
      expect {@ignore_quiz.reload}.to raise_error ActiveRecord::RecordNotFound
      expect {ignore2.reload}.to raise_error ActiveRecord::RecordNotFound
    end

    it 'should delete ignores for deleted assessment requests' do
      @ar.delete
      Ignore.cleanup
      expect {@ignore_ar.reload}.to raise_error ActiveRecord::RecordNotFound
    end

    it 'should not delete ignores for recently deleted (and recoverable) assets' do
      @assignment.destroy!
      @quiz.destroy!
      Ignore.cleanup
      expect(@ignore_assign.reload).to eq @ignore_assign
      expect(@ignore_quiz.reload).to eq @ignore_quiz
    end

    it 'should delete ignores for users with enrollments concluded for six months' do
      @enrollment.update_attributes!(workflow_state: 'completed', completed_at: 7.months.ago)
      Ignore.cleanup
      expect {@ignore_assign.reload}.to raise_error ActiveRecord::RecordNotFound
      expect {@ignore_quiz.reload}.to raise_error ActiveRecord::RecordNotFound
      expect {@ignore_ar.reload}.to raise_error ActiveRecord::RecordNotFound
    end

    it 'should not delete ignores for users with enrollments concluded less than six months ago' do
      @enrollment.conclude
      Ignore.cleanup
      expect(@ignore_assign.reload).to eq @ignore_assign
      expect(@ignore_quiz.reload).to eq @ignore_quiz
      expect(@ignore_ar.reload).to eq @ignore_ar
    end

    it 'should delete ignores for users with deleted enrollments' do
      @enrollment.update_attributes!(workflow_state: 'deleted', updated_at: 2.months.ago)
      Ignore.cleanup
      expect {@ignore_assign.reload}.to raise_error ActiveRecord::RecordNotFound
      expect {@ignore_quiz.reload}.to raise_error ActiveRecord::RecordNotFound
      expect {@ignore_ar.reload}.to raise_error ActiveRecord::RecordNotFound
    end

    it 'should not delete ignores for users with recently deleted (and recoverable) enrollments' do
      @enrollment.destroy!
      Ignore.cleanup
      expect(@ignore_assign.reload).to eq @ignore_assign
      expect(@ignore_quiz.reload).to eq @ignore_quiz
      expect(@ignore_ar.reload).to eq @ignore_ar
    end

    it 'should not delete ignores for users with active assets and in progress enrollments' do
      Ignore.cleanup
      expect(@ignore_assign.reload).to eq @ignore_assign
      expect(@ignore_quiz.reload).to eq @ignore_quiz
      expect(@ignore_ar.reload).to eq @ignore_ar
    end
  end
end
