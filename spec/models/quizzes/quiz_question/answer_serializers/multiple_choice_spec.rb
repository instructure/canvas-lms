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
require_relative "support/id_answer_serializers_specs"

describe Quizzes::QuizQuestion::AnswerSerializers::MultipleChoice do
  let :output do
    {
      question_5: "2405"
    }.with_indifferent_access
  end
  let :input do
    "2405"
  end

  include_examples "Answer Serializers"

  context "validations" do
    include_examples "Id Answer Serializers"
  end
end
