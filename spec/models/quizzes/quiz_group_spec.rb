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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::QuizGroup do

  describe "saving a group" do
    it "should mark its quiz as having unpublished changes when updated" do
      course
      quiz = @course.quizzes.create!(:title => "some quiz")
      group = quiz.quiz_groups.create!(:name => "question group", :pick_count => 1, :question_points => 5.0)
      group.quiz_questions.create!(:quiz=>quiz, :question_data => {'name' => 'test question', 'answers' => [{'id' => 1}, {'id' => 2}]})
      quiz.published_at = Time.now
      quiz.publish!
      quiz.unpublished_changes?.should be_false

      Timecop.freeze(5.minutes.from_now) do
        group.update_attribute :question_points, 10.0
        quiz.reload.unpublished_changes?.should be_true
      end
    end
  end

  describe "#actual_pick_count" do
    context "with a question bank" do
      it "should return the correct pick count if there aren't enough questions" do
        course
        quiz = @course.quizzes.create!(:title => "some quiz")
        group = quiz.quiz_groups.create!(:name => "question group", :pick_count => 3, :question_points => 5.0)
        group.quiz_questions.create!(:quiz=>quiz, :question_data => {'name' => 'test question', 'answers' => [{'id' => 1}, {'id' => 2}]})
        group.quiz_questions.create!(:quiz=>quiz, :question_data => {'name' => 'test question 2', 'answers' => [{'id' => 3}, {'id' => 4}]})
        group.quiz_questions.active.size.should == 2

        group.pick_count.should == 3
        group.actual_pick_count.should == 2
      end
    end

    context "with a question bank" do
      before(:once) do
        course
        @bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
        @bank.assessment_questions.create!(:question_data => {'name' => 'test question', 'answers' => [{'id' => 1}, {'id' => 2}]})
        @bank.assessment_questions.create!(:question_data => {'name' => 'test question 2', 'answers' => [{'id' => 3}, {'id' => 4}]})
        @quiz = @course.quizzes.create!(:title => "some quiz")
        @group = @quiz.quiz_groups.create!(:name => "question group", :pick_count => 3, :question_points => 5.0)
        @group.assessment_question_bank = @bank
        @group.save
      end

      it "should return the correct pick count for question bank" do
        @bank.assessment_questions.count.should == 2
        @group.pick_count.should == 3
        @group.actual_pick_count.should == 2

        @bank.assessment_questions.create!(:question_data => {'name' => 'test question 3', 'answers' => [{'id' => 3}, {'id' => 4}]})
        @group.reload
        @group.actual_pick_count.should == 3
      end

      it "should emit the correct data" do
        data = @group.data
        data[:pick_count].should == 3
        data[:assessment_question_bank_id].should == @bank.id
        data[:questions].should == []
      end
    end
  end

  describe "#data" do
    it "should generate valid data" do
      course
      quiz = @course.quizzes.create!(:title => "some quiz")
      g = quiz.quiz_groups.create(:name => "question group", :pick_count => 2, :question_points => 5.0)
      g.quiz_questions << quiz.quiz_questions.create!(:question_data => {'name' => 'test question', 'answers' => [{'id' => 1}, {'id' => 2}]})
      g.quiz_questions << quiz.quiz_questions.create!(:question_data => {'name' => 'test question 2', 'answers' => [{'id' => 3}, {'id' => 4}]})
      g.name.should eql("question group")
      g.pick_count.should eql(2)
      g.question_points.should eql(5.0)
      g.save!

      data = g.data
      data[:name].should eql("question group")
      data[:pick_count].should eql(2)
      data[:question_points].should eql(5.0)
      data[:questions].should_not be_empty
      data[:questions].length.should eql(2)
      data[:questions].sort_by! { |q| q[:id] }
      data[:questions][0][:name].should eql("test question")
      data[:questions][1][:name].should eql("test question 2")
    end
  end

  describe ".update_all_positions!" do
    def group_positions(quiz)
      quiz.quiz_groups.sort_by{|g| g.position }.map {|g| g.id }
    end

    before :once do
      course
      @quiz = @course.quizzes.create!(:title => "some quiz")
      @group1 = @quiz.quiz_groups.create(:name => "question group 1")
      @group2 = @quiz.quiz_groups.create(:name => "question group 2")
      @group3 = @quiz.quiz_groups.create(:name => "question group 2")
    end

    it "should noop if list of items is empty" do
      before = group_positions(@quiz)

      Quizzes::QuizGroup.update_all_positions!([])
      before.should == group_positions(@quiz.reload)
    end

    it "should update positions for groups" do
      @group3.position = 1
      @group1.position = 2
      @group2.position = 3

      Quizzes::QuizGroup.update_all_positions!([@group3, @group1, @group2])
      group_positions(@quiz.reload).should == [@group3.id, @group1.id, @group2.id]
    end
  end
end
