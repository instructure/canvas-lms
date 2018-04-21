#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../spec_helper.rb'

describe 'FixPointsPossibleSumsInQuizzes' do
  question_count = 18
  question_points = 0.544
  question_sum = 9.792

  before :once do
    course_factory(active_all: true)
    q = @course.quizzes.create!(title: 'floating quiz')
    question_data = { points_possible: question_points, question_type: 'multiple_choice_question' }
    question_count.times do |i|
      q.quiz_questions.build(question_data: question_data.merge(name: "root #{i}"))
    end
    q.save!
    @quiz = q
  end

  before :each do
    # creates rounding error just like the real thing!
    points = Array.new(question_count){ question_points }.inject(:+) # .sum uses the native ruby 2.4 sum if the first element is numeric in rails 5.1 ...and doesn't quite give the same answer :/
    allow(Quizzes::Quiz).to receive(:count_points_possible).and_return(points)
  end

  context 'for unpublished quiz' do
    before :each do
      @quiz.generate_quiz_data
      @quiz.save!
      @quiz.reload
      allow(Quizzes::Quiz).to receive(:count_points_possible).and_call_original
    end

    it "should repair quiz points_possible from questions" do
      expect(@quiz.points_possible).to be > question_sum
      DataFixup::FixPointsPossibleSumsInQuizzes.run
      expect(@quiz.reload.points_possible).to eq question_sum
    end

    it "should not require regrade for repaired quizzes" do
      broken_version = @quiz.versions.current.number
      DataFixup::FixPointsPossibleSumsInQuizzes.run
      @quiz.reload
      expect(@quiz.changed_significantly_since?(broken_version)).to eq false
      expect(@quiz.versions.current.number).to eq(broken_version + 1)
    end

    it "should only select quizzes that appear to have rounding error" do
      healthy_quiz = @course.quizzes.create!(title: 'decimal quiz')
      a = Assignment.new
      a.course = @course
      a.points_possible = 10.5
      a.quiz = healthy_quiz
      a.save!

      nil_quiz = @course.quizzes.create!(title: 'no points quiz', quiz_type: 'survey')

      affected = DataFixup::FixPointsPossibleSumsInQuizzes.affected_quizzes
      expect(affected).to include @quiz
      expect(affected).not_to include healthy_quiz
      expect(affected).not_to include nil_quiz
    end
  end

  context 'for published quiz' do
    before :each do
      @quiz.publish!
      @quiz.reload
      allow(Quizzes::Quiz).to receive(:count_points_possible).and_call_original
    end

    it "should repair quiz points_possible from questions" do
      expect(@quiz.points_possible).to be > question_sum
      DataFixup::FixPointsPossibleSumsInQuizzes.run
      expect(@quiz.reload.points_possible).to eq question_sum
    end

    it "should not require regrade for repaired quizzes" do
      broken_version = @quiz.versions.current.number
      DataFixup::FixPointsPossibleSumsInQuizzes.run
      @quiz.reload
      expect(@quiz.changed_significantly_since?(broken_version)).to eq false
      expect(@quiz.versions.current.number).to eq(broken_version + 1)
    end
  end
end
