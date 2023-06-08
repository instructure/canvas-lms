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

require_relative "support/answer_serializers_specs"

describe Quizzes::QuizQuestion::AnswerSerializers::Numerical do
  context "English" do
    let :inputs do
      [25.3, 25e-6, "0.12", "3", "17,000", "6,200,000.13"]
    end

    let :outputs do
      [
        { question_5: 0.253e2 }.with_indifferent_access,
        { question_5: 25e-6 }.with_indifferent_access,
        { question_5: 0.12 }.with_indifferent_access,
        { question_5: 3.0 }.with_indifferent_access,
        { question_5: 17_000.0 }.with_indifferent_access,
        { question_5: 6_200_000.13 }.with_indifferent_access
      ]
    end

    include_examples "Answer Serializers"

    it "returns nil when un-answered" do
      expect(subject.deserialize({})).to be_nil
    end

    context "validations" do
      it "turns garbage into 0.0" do
        ["foobar", nil, { foo: "bar" }, "25 00012"].each do |garbage|
          rc = subject.serialize(garbage)
          expect(rc.error).to be_nil
          expect(rc.answer).to eq({
            question_5: 0.0
          }.with_indifferent_access)
        end
      end
    end
  end

  context "Italian" do
    around do |example|
      I18n.with_locale(:it, &example)
    end

    let :inputs do
      [25.3, 25e-6, "0,12", "3", "17.000", "6.200.000,13"]
    end

    let :outputs do
      [
        { question_5: 25.3 }.with_indifferent_access,
        { question_5: 0.000025 }.with_indifferent_access,
        { question_5: 0.12 }.with_indifferent_access,
        { question_5: 3.0 }.with_indifferent_access,
        { question_5: 17_000.0 }.with_indifferent_access,
        { question_5: 6_200_000.13 }.with_indifferent_access
      ]
    end

    include_examples "Answer Serializers"
  end

  context "French" do
    around do |example|
      I18n.with_locale(:fr, &example)
    end

    let :inputs do
      [25.3, 25e-6, "0,12", "3", "17 000", "6 200 000,13"]
    end

    let :outputs do
      [
        { question_5: 25.3 }.with_indifferent_access,
        { question_5: 0.000025 }.with_indifferent_access,
        { question_5: 0.12 }.with_indifferent_access,
        { question_5: 3.0 }.with_indifferent_access,
        { question_5: 17_000.0 }.with_indifferent_access,
        { question_5: 6_200_000.13 }.with_indifferent_access
      ]
    end

    include_examples "Answer Serializers"
  end

  def sanitize(value)
    if value.is_a? String
      Quizzes::QuizQuestion::AnswerSerializers::Util.i18n_to_decimal value.to_s
    else
      Quizzes::QuizQuestion::AnswerSerializers::Util.to_decimal value.to_s
    end
  end
end
