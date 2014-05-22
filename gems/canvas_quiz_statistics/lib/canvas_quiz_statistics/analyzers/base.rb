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
require 'canvas_quiz_statistics/analyzers/base/dsl'
require 'canvas_quiz_statistics/analyzers/base/constants'

module CanvasQuizStatistics::Analyzers
  class Base
    extend DSL

    attr_reader :question_data

    def initialize(question_data)
      @question_data = question_data
      @metrics = self.class.metrics[self.class.question_type]
    end

    def run(responses)
      context = build_context(responses)

      {}.tap do |stats|
        @metrics.map do |metric|
          params = [ responses ]

          if metric[:context].any?
            params += metric[:context].map { |var| context[var] }
          end

          stats[metric[:key]] = instance_exec(*params, &metric[:calculator])
        end
      end
    end

    def self.question_type
      (self.name.demodulize.underscore + '_question').to_sym
    end

    private

    # This is the place to prepare any shared context that's needed by the
    # metric calculations. See DSL for more info on stateful metrics.
    #
    # @return [Hash] You must return a Hash with symbolized keys for a context.
    def build_context(responses)
      {}
    end
  end
end
