# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

RSpec::Matchers.define :have_answer do |expected|
  match do |actual|
    expected = Regexp.new(expected, "i") if expected.is_a? String
    actual.detect { |a| a[:text] =~ expected || a[:html] =~ expected || a[:comments] =~ expected || a[:answer] =~ expected }
  end
end

shared_examples_for "All answer parsers" do
  before do
    question = Quizzes::QuizQuestion::QuestionData.new(question_params)
    question.answers = Quizzes::QuizQuestion::AnswerGroup.new(raw_answers)
    parser = parser_class.new(question.answers)
    question = parser.parse(question)
    @answer_data = question.answers
  end

  it "seeds the question with the answers" do
    expect(@answer_data.answers.size).to eq raw_answers.size
  end

  it "formats the answers" do
    expect(@answer_data).to be_a(Quizzes::QuizQuestion::AnswerGroup)
    raw_answers.each do |raw|
      expect(@answer_data.answers).to have_answer raw[:answer_text]
    end
  end

  it "provides IDs for the answers" do
    ids = @answer_data.answers.pluck(:id)
    ids.each { |id| expect(id).to be_a(Integer) }
  end

  it "sanitizes answer comments" do
    expect(@answer_data.first[:comments_html]).to include("<img")
    expect(@answer_data.first[:comments_html]).not_to include("onerror")
  end
end
