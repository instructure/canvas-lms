#
# Copyright (C) 2014 Instructure, Inc.
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
require 'canvas_quiz_statistics/answer_analyzers/util'
require 'canvas_quiz_statistics/answer_analyzers/base'
require 'canvas_quiz_statistics/answer_analyzers/essay'

module CanvasQuizStatistics::AnswerAnalyzers
  # Convenient access to analyzer for a given question type, e.g:
  #
  #   AnswerAnalyzers['multiple_choice_question'].new
  #
  # If the question type is not supported, you will be given the Base
  # analyzer which really does nothing.
  def self.[](question_type)
    AVAILABLE_ANALYZERS[question_type] || Base
  end

  private

  # for fast lookup without having to use #constantize or anything
  AVAILABLE_ANALYZERS = {
    'essay_question' => Essay
  }
end
