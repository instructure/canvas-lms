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
require File.expand_path(File.dirname(__FILE__) + '/support/id_answer_serializers_specs.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::MultipleDropdowns do

  include_examples 'Answer Serializers'

  let :input do
    {
      structure1: '4390',
      event2: '599'
    }.with_indifferent_access
  end

  let :output do
    {
      "question_5_#{AssessmentQuestion.variable_id 'structure1'}" => "4390",
      "question_5_#{AssessmentQuestion.variable_id 'event2'}" => "599"
    }.with_indifferent_access
  end

  # for auto specs
  def format(value)
    { structure1: value }
  end

  context 'validations' do
    include_examples 'Id Answer Serializers'

    it 'should reject an answer for an unknown blank' do
      rc = subject.serialize({ foobar: 123456 })
      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/unknown blank/i)
    end
  end
end
