#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe LearningOutcome do
  context "one question from an aligned bank in multiple quizzes" do
    before do
      # create a course in an account
      user(active_all: true)

      # create an outcome
      @account = Account.default
      @outcome = @account.created_learning_outcomes.create!(title: "outcome")
      @account.root_outcome_group.add_outcome(@outcome)

      # create a question in a question bank aligned to that outcome
      @bank = @account.assessment_question_banks.create!
      @bank.alignments = {@outcome.id => 1}
      @question = @bank.assessment_questions.create!

      # put the same question into quizzes from two separate courses
      @course1 = course(active_all: true)
      @quiz1 = @course1.quizzes.create!
      @quiz1.add_assessment_questions([@question])
      @quiz1.publish!

      @course2 = course(active_all: true)
      @quiz2 = @course2.quizzes.create!
      @quiz2.add_assessment_questions([@question])
      @quiz2.publish!
    end

    it "should create multiple LORs for the multiple instances of the question" do
      # enroll one student in both courses
      student_in_course(course: @course1, active_all: true)
      student_in_course(course: @course2, user: @student, active_all: true)

      # have the student take both quizzes
      @submission1 = @quiz1.generate_submission(@student)
      @submission1.grade_submission

      @submission2 = @quiz2.generate_submission(@student)
      @submission2.grade_submission

      # there should be two LORs for the outcome, both for the same student and
      # question, but for the different quizzes
      @results = @outcome.learning_outcome_results.all
      @results.size.should == 2
      @results.map{ |r| r.user }.should == [@student, @student]
      @results.map{ |r| r.associated_asset }.should == [@question, @question]
      @results.map{ |r| r.association_type }.should == ['Quiz', 'Quiz']
      @results.map{ |r| r.association_id }.sort == [@quiz1.id, @quiz2.id].sort
    end
  end
end
