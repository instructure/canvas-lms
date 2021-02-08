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
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::Numerical do

  include_examples 'Answer Serializers'

  let :inputs do
    [ 25.3, 25e-6, '0.12', '3' ]
  end

  let :outputs do
    [
      { question_5: "25.3" }.with_indifferent_access,
      { question_5: "0.000025" }.with_indifferent_access,
      { question_5: "0.12" }.with_indifferent_access,
      { question_5: "3.0" }.with_indifferent_access
    ]
  end

  def sanitize(value)
    Quizzes::QuizQuestion::AnswerSerializers::Util.to_decimal value
  end

  it 'should return nil when un-answered' do
    expect(subject.deserialize({})).to eq nil
  end

  context 'validations' do
    it 'should turn garbage into 0.0' do
      [ 'foobar', nil, { foo: 'bar' } ].each do |garbage|
        rc = subject.serialize(garbage)
        expect(rc.error).to be_nil
        expect(rc.answer).to eq({
          question_5: "0.0"
        }.with_indifferent_access)
      end
    end
  end
end
