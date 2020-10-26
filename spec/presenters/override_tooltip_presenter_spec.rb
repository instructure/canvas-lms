# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe OverrideTooltipPresenter do
  describe '#selector' do
    it 'returns a unique selector for the assignment' do
      assignment = Assignment.new
      assignment.context = course_factory
      assignment.save

      presenter = OverrideTooltipPresenter.new(assignment)

      expect(presenter.selector).to eq "assignment_#{assignment.id}"
    end

    it 'returns a unique selector for the quiz' do
      quiz = Quizzes::Quiz.new(title: 'some quiz')
      quiz.context = course_factory
      quiz.save

      presenter = OverrideTooltipPresenter.new(quiz)

      expect(presenter.selector).to eq "quiz_#{quiz.id}"
    end
  end
end
