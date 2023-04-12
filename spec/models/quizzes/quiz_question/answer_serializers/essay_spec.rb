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

describe Quizzes::QuizQuestion::AnswerSerializers::Essay do
  let :output do
    {
      question_5: "Hello World!"
    }.with_indifferent_access
  end
  let :input do
    "Hello World!"
  end

  include_examples "Answer Serializers"

  it "returns nil when un-answered" do
    expect(subject.deserialize({})).to be_nil
  end

  context "validations" do
    include_examples "Textual Answer Serializers"
  end
end
