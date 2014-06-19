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
  end

  describe "#select_for_submission" do
    before do
      # create a bunch of questions to make it more likely that they'll shuffle randomly
      @q1  = @bank.assessment_questions.create!(:question_data => {'name' => 'test question 1',  'answers' => [{'id' => 1}, {'id' => 2}]})
      @q2  = @bank.assessment_questions.create!(:question_data => {'name' => 'test question 2',  'answers' => [{'id' => 3}, {'id' => 4}]})
      @q3  = @bank.assessment_questions.create!(:question_data => {'name' => 'test question 3',  'answers' => [{'id' => 3}, {'id' => 4}]})
      @q4  = @bank.assessment_questions.create!(:question_data => {'name' => 'test question 4',  'answers' => [{'id' => 3}, {'id' => 4}]})
      @q5  = @bank.assessment_questions.create!(:question_data => {'name' => 'test question 5',  'answers' => [{'id' => 3}, {'id' => 4}]})
      @q6  = @bank.assessment_questions.create!(:question_data => {'name' => 'test question 6',  'answers' => [{'id' => 3}, {'id' => 4}]})
      @q7  = @bank.assessment_questions.create!(:question_data => {'name' => 'test question 7',  'answers' => [{'id' => 3}, {'id' => 4}]})
      @q8  = @bank.assessment_questions.create!(:question_data => {'name' => 'test question 8',  'answers' => [{'id' => 3}, {'id' => 4}]})
      @q9  = @bank.assessment_questions.create!(:question_data => {'name' => 'test question 9',  'answers' => [{'id' => 3}, {'id' => 4}]})
      @q10 = @bank.assessment_questions.create!(:question_data => {'name' => 'test question 10', 'answers' => [{'id' => 3}, {'id' => 4}]})
      @quiz = @course.quizzes.create!(:title => "some quiz")
      @group = @quiz.quiz_groups.create!(:name => "question group", :pick_count => 3, :question_points => 5.0)
      @group.assessment_question_bank = @bank
      @group.save
    end

    it "should return the desired count of questions" do
      @bank.select_for_submission(0).length.should == 0
      @bank.select_for_submission(2).length.should == 2
      @bank.select_for_submission(4).length.should == 4
      @bank.select_for_submission(11).length.should == 10
    end

    it "should exclude specified questions" do
      original = [@q1.id, @q2.id, @q3.id, @q4.id, @q5.id, @q6.id, @q7.id, @q8.id, @q9.id, @q10.id]
      selected_ids = @bank.select_for_submission(10, [@q1.id, @q10.id]).map {|q| q.id }

      selected_ids.include?(@q1.id).should be_false
      selected_ids.include?(@q10.id).should be_false
      selected_ids.include?(@q2.id).should be_true
      selected_ids.include?(@q9.id).should be_true
    end

    it "should return the questions in a random order" do
      original = [@q1.id, @q2.id, @q3.id, @q4.id, @q5.id, @q6.id, @q7.id, @q8.id, @q9.id, @q10.id]

      selected1 = @bank.select_for_submission(10).map {|q| q.id }
      selected2 = @bank.select_for_submission(10).map {|q| q.id }

      # make sure at least one is shuffled
      is_shuffled1 = (original != selected1)
      is_shuffled2 = (original != selected2)

      # it's possible but unlikely that shuffled version is same as original
      (is_shuffled1 || is_shuffled2).should be_true
    end
  end

  it "should allow user read access through question bank users" do
    user
    @bank.assessment_question_bank_users.create!(:user => user)
    @course.grants_right?(@user, :manage_assignments).should be_false
    @bank.grants_right?(@user, :read).should be_true
  end

  it "should remove outcome alignments when deleted" do
    outcome_model(:context => @course)
    @bank.alignments = { @outcome.id => 0.5 }

    @bank.reload
    @bank.learning_outcome_alignments.should be_present
    @bank.learning_outcome_alignments.first.learning_outcome_id.should == @outcome.id

    # regular save shouldn't mess with alignments
    @bank.save!
    @bank.reload
    @bank.learning_outcome_alignments.should be_present
    @bank.learning_outcome_alignments.first.learning_outcome_id.should == @outcome.id

    @bank.destroy
    @bank.reload
    @bank.learning_outcome_alignments.should be_empty
  end
end
