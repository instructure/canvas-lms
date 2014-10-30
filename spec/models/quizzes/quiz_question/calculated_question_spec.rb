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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizQuestion::CalculatedQuestion do

  let(:question_data) do
    {:answer_tolerance => 2.0, :answers => [{:id => 1, :answer => 10}]}
  end

  let(:question) do
    Quizzes::QuizQuestion::CalculatedQuestion.new(question_data)
  end

  describe "#initialize" do
    it "assign question data" do
      expect(question.question_id).to eq question_data[:id]
    end
  end

  describe "#correct_answer_parts with point tolerance" do
    let(:question_id)     { 1 }
    let(:points_possible) { 100 }

    it "should calculate if answer is too far below of the answer tolerance" do
      answer_data = {:"question_#{question_id}" => "7.5"}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      expect(question.correct_answer_parts(user_answer)).to be_falsey
    end

    it "should calculate if answer is too far above of the answer tolerance" do
      answer_data = {:"question_#{question_id}" => "12.5"}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      expect(question.correct_answer_parts(user_answer)).to be_falsey
    end

    it "should calculate if answer is below the answer but within tolerance" do
      answer_data = {:"question_#{question_id}" => "9"}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      expect(question.correct_answer_parts(user_answer)).to be_truthy
    end

    it "should calculate if answer is above the the answer but within tolerance answer tolerance" do
      answer_data = {:"question_#{question_id}" => "11"}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      expect(question.correct_answer_parts(user_answer)).to be_truthy
    end
  end

  describe "#correct_answer_parts with percentage tolerance" do
    let(:question_data) do
      {:answer_tolerance => "20.0%", :answers => [{:id => 1, :answer => 10}]}
    end

    let(:question_id)     { 1 }
    let(:points_possible) { 100 }

    it "should calculate if answer is too far below of the answer tolerance" do
      answer_data = {:"question_#{question_id}" => "7.5"}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)
      
      expect(question.correct_answer_parts(user_answer)).to be_falsey
    end

    it "should calculate if answer is too far above of the answer tolerance" do
      answer_data = {:"question_#{question_id}" => "12.5"}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      expect(question.correct_answer_parts(user_answer)).to be_falsey
    end

    it "should calculate if answer is below the answer but within tolerance" do
      answer_data = {:"question_#{question_id}" => "9"}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      expect(question.correct_answer_parts(user_answer)).to be_truthy
    end

    it "should calculate if answer is above the the answer but within tolerance answer tolerance" do
      answer_data = {:"question_#{question_id}" => "11"}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      expect(question.correct_answer_parts(user_answer)).to be_truthy
    end
  end

  describe "#correct_answer_parts with percentage tolerance and negative answer" do
    let(:question_data) do
      {:answer_tolerance => "20.0%", :answers => [{:id => 1, :answer => -10}]}
    end

    let(:question_id)     { 1 }
    let(:points_possible) { 100 }

    it "should calculate if negative answer is below the answer but within tolerance" do
      answer_data = {:"question_#{question_id}" => "-9"}
      
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      expect(question.correct_answer_parts(user_answer)).to be_truthy
    end

    it "should calculate if negative answer is above the the answer but within tolerance answer tolerance" do
      answer_data = {:"question_#{question_id}" => "-11"}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      expect(question.correct_answer_parts(user_answer)).to be_truthy
    end
  end
end
