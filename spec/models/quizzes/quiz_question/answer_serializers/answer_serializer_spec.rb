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

describe Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer do
  it "automatically registers answer serializers" do
    ases = Quizzes::QuizQuestion::AnswerSerializers

    qq = { question_type: "uber_hax_question" }

    expect(ases.serializer_for(qq)).to be_a(Quizzes::QuizQuestion::AnswerSerializers::Unknown)

    stub_const("Quizzes::QuizQuestion::AnswerSerializers::UberHax",
               Class.new(Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer))

    serializer = nil
    expect { serializer = ases.serializer_for(qq) }.to_not raise_error
    expect(serializer.is_a?(ases::AnswerSerializer)).to be_truthy
  end

  it "has Error constant" do
    expect { Quizzes::QuizQuestion::AnswerSerializers::Error.new("message") }.to_not raise_error
  end
end
