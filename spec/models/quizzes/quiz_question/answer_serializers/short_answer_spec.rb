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
require_relative "support/textual_answer_serializers_specs"

describe Quizzes::QuizQuestion::AnswerSerializers::ShortAnswer do
  let :output do
    {
      question_5: "hello world!"
    }.with_indifferent_access
  end
  let :input do
    "hello world!"
  end

  include_examples "Answer Serializers"

  it "returns nil when un-answered" do
    expect(subject.deserialize({})).to be_nil
  end

  it "gracefully sanitizes its text" do
    expect(subject.serialize("Hello World!").answer).to eq({
      question_5: "hello world!"
    }.with_indifferent_access)
  end

  context "validations" do
    include_examples "Textual Answer Serializers"
  end
end
