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

module CanvasQuizStatistics
  require 'canvas_quiz_statistics/version'
  require 'canvas_quiz_statistics/util'
  require 'canvas_quiz_statistics/analyzers'

  def self.can_analyze?(question_data)
    Analyzers[question_data[:question_type]] != Analyzers::Base
  end

  def self.analyze(question_data, responses)
    analyzer = Analyzers[question_data[:question_type]].new(question_data)
    analyzer.run(responses)
  end
end
