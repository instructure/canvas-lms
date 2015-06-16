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

describe Quizzes::OutstandingQuizSubmissionManager do

  describe "outstanding submissions by quiz" do
    before do
      course
      @user = student_in_course.user
      @quiz = @course.quizzes.create!(:title => "Outstanding")
      @quiz.quiz_questions.create!(:question_data => multiple_choice_question_data)
      @quiz.generate_quiz_data
      @quiz.save
      @submission = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(@user, false)
      @submission.end_at = 20.minutes.ago
      @submission.save!
      @outstanding = Quizzes::OutstandingQuizSubmissionManager.new(@quiz)
    end
    it 'should be overdue and need_grading' do
      expect(@submission.overdue?).to be true
      expect(@submission.needs_grading?).to be true
    end
    it "should #find_by_quiz" do
      subs = @outstanding.find_by_quiz
      expect(subs.size).to eq 1
      expect(subs.first.id).to eq @submission.id
    end
    it 'should force grading to close the submission' do
      subs = @outstanding.find_by_quiz
      @outstanding.grade_by_ids(subs.map(&:id))
      subs = @outstanding.find_by_quiz
      expect(subs.size).to eq 0
    end
    it 'should grade multiple submissions' do
      sub_count = @outstanding.find_by_quiz.size
      student_count = 2
      students = student_count.times.map { student_in_course(active_all: true).user }
      submissions = students.map do |student|
        submission = Quizzes::SubmissionManager.new(@quiz).find_or_create_submission(student, false)
        submission.end_at = 20.minutes.ago
        submission.save
        submission
      end
      subs = @outstanding.find_by_quiz
      expect(subs.size).to eq(sub_count + student_count)
      @outstanding.grade_by_ids(subs.map(&:id))
      expect(@outstanding.find_by_quiz.size).to eq 0
    end
  end
  describe '#grade_by_course' do
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

      expect(ungraded_qs.needs_grading?).to be true
        expect(graded_qs.needs_grading?).to be false

      described_class.grade_by_course(@course)

      ungraded_qs.reload
      expect(ungraded_qs.needs_grading?).to be false
    end
  end
end
