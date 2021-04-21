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

require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer do

  ASes = Quizzes::QuizQuestion::AnswerSerializers

  it 'automatically registers answer serializers' do
    serializer = nil

    qq = { question_type: 'uber_hax_question' }

    expect(ASes.serializer_for(qq)).to be_kind_of(Quizzes::QuizQuestion::AnswerSerializers::Unknown)

    class Quizzes::QuizQuestion::AnswerSerializers::UberHax < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer
    end

    begin
      expect { serializer = ASes.serializer_for(qq) }.to_not raise_error
      expect(serializer.is_a?(ASes::AnswerSerializer)).to be_truthy
    ensure
      Quizzes::QuizQuestion::AnswerSerializers.send(:remove_const, :UberHax)
    end
  end

  it 'has Error constant' do
    expect{Quizzes::QuizQuestion::AnswerSerializers::Error.new('message')}.to_not raise_error
  end
end
