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
require 'active_support/core_ext'

module CanvasQuizStatistics::Analyzers
  class << self
    attr_accessor :available_analyzers

    # Convenient access to analyzer for a given question type, e.g:
    #
    #   Analyzers['multiple_choice_question'].new
    #
    # If the question type is not supported, you will be given the Base
    # analyzer which really does nothing.
    def [](question_type)
      self.available_analyzers ||= {}
      self.available_analyzers[question_type.to_sym] || Base
    end
  end

  class Base
    def self.inherited(klass)
      namespace = CanvasQuizStatistics::Analyzers
      namespace.available_analyzers ||= {}
      namespace.available_analyzers[klass.question_type] = klass
    end
  end

  require 'canvas_quiz_statistics/analyzers/base'
  require 'canvas_quiz_statistics/analyzers/essay'
  require 'canvas_quiz_statistics/analyzers/fill_in_multiple_blanks'
end
