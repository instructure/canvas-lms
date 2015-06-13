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
      expect(quiz.unpublished_changes?).to be_falsey

      Timecop.freeze(5.minutes.from_now) do
        group.update_attribute :question_points, 10.0
        expect(quiz.reload.unpublished_changes?).to be_truthy
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
        expect(group.quiz_questions.active.size).to eq 2

        expect(group.pick_count).to eq 3
        expect(group.actual_pick_count).to eq 2
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
        expect(@bank.assessment_questions.count).to eq 2
        expect(@group.pick_count).to eq 3
        expect(@group.actual_pick_count).to eq 2

        @bank.assessment_questions.create!(:question_data => {'name' => 'test question 3', 'answers' => [{'id' => 3}, {'id' => 4}]})
        @group.reload
        expect(@group.actual_pick_count).to eq 3
      end

      it "should emit the correct data" do
        data = @group.data
        expect(data[:pick_count]).to eq 3
        expect(data[:assessment_question_bank_id]).to eq @bank.id
        expect(data[:questions]).to eq []
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
      expect(g.name).to eql("question group")
      expect(g.pick_count).to eql(2)
      expect(g.question_points).to eql(5.0)
      g.save!

      data = g.data
      expect(data[:name]).to eql("question group")
      expect(data[:pick_count]).to eql(2)
      expect(data[:question_points]).to eql(5.0)
      expect(data[:questions]).not_to be_empty
      expect(data[:questions].length).to eql(2)
      data[:questions].sort_by! { |q| q[:id] }
      expect(data[:questions][0][:name]).to eql("test question")
      expect(data[:questions][1][:name]).to eql("test question 2")
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
      expect(before).to eq group_positions(@quiz.reload)
    end

    it "should update positions for groups" do
      @group3.position = 1
      @group1.position = 2
      @group2.position = 3

      Quizzes::QuizGroup.update_all_positions!([@group3, @group1, @group2])
      expect(group_positions(@quiz.reload)).to eq [@group3.id, @group1.id, @group2.id]
    end
  end
end
