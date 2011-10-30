#
# Copyright (C) 2011 Instructure, Inc.
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

describe AssessmentQuestionBank do
  before(:each) do
    course
    @bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
    @bank.assessment_questions.create!(:question_data => {'name' => 'test question', 'answers' => [{'id' => 1}, {'id' => 2}]})
    @bank.assessment_questions.create!(:question_data => {'name' => 'test question 2', 'answers' => [{'id' => 3}, {'id' => 4}]})
    @bank.assessment_questions.create!(:question_data => {'name' => 'test question 3', 'answers' => [{'id' => 3}, {'id' => 4}]})
    @bank.assessment_questions.create!(:question_data => {'name' => 'test question 4', 'answers' => [{'id' => 3}, {'id' => 4}]})
    @quiz = @course.quizzes.create!(:title => "some quiz")
    @group = @quiz.quiz_groups.create!(:name => "question group", :pick_count => 3, :question_points => 5.0)
    @group.assessment_question_bank = @bank
    @group.save
  end

  it "should return the desired count of questions" do
    @bank.select_for_submission(0).length.should == 0
    @bank.select_for_submission(2).length.should == 2
    @bank.select_for_submission(4).length.should == 4
    @bank.select_for_submission(5).length.should == 4
  end

  it "should exclude specified questions" do
    questions = @bank.assessment_questions
    @bank.select_for_submission(4, [questions.first.id, questions.last.id]).sort_by(&:id).should eql questions[1, 2]
  end

  it "should allow user read access through question bank users" do
    user
    @bank.assessment_question_bank_users.create!(:user => user)
    @course.grants_right?(@user, :manage_assignments).should be_false
    @bank.grants_right?(@user, :read).should be_true
  end
end
