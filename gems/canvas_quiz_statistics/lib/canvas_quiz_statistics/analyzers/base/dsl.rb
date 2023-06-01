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
#

# A custom DSL for writing metric calculators.
#
# Here's a full example showing how to define a context-free metric calculator,
# and a stateful one that requires a shared, pre-calculated variable:
#
#  module CanvasQuizStatistics::Analyzers
#    class MultipleChoice < Base
#      # A basic metric calculator. Your calculator block will be passed the
#      # set of responses, and needs to return the value of the metric.
#      #
#      # The key you specify will be written to the output, e.g:
#      # { "missing_answers": 1 }
#      metric :missing_answers do |responses|
#        responses.select { |r| r[:text].blank? }.length
#      end
#
#      # Let's say you need some pre-calculated variable for a bunch of metrics,
#      # call it "grades", we can prepare it in the special #build_context
#      # method and explicitly declare it as a dependency of each metric:
#      def build_context(responses)
#        ctx = {}
#        ctx[:grades] = responses.map { |r| r[:grade] }
#        ctx
#      end
#
#      # Notice how our metric definition now states that it requires the
#      # "grades" context variable to run, and it receives it as a block arg:
#      metric :graded_correctly => [ :grades ] do |responses, grades|
#        grades.select { |grade| grade == 'correct' }.length
#      end
#    end
#  end
module CanvasQuizStatistics::Analyzers::Base::DSL
  def metric(key, &calculator)
    deps = []

    if key.is_a?(Hash)
      deps, key = key.values.flatten, key.keys.first
    end

    metrics[question_type] << {
      key: key.to_sym,
      context: deps,
      calculator:
    }
  end

  # You will need to do this if you're subclassing a concrete analyzer and would
  # like to inherit the metric calculators it defined, as the calculators are
  # scoped per question type and not the Ruby class.
  #
  # Example:
  #
  #   module CanvasQuizStatistics::Analyzers
  #     class TrueFalse < MultipleChoice
  #       inherit_metrics :multiple_choice_question
  #     end
  #   end
  #
  def inherit_metrics(question_type)
    metrics[self.question_type] += metrics_for(question_type).clone
  end

  # Inherit one or more metrics from another question type.
  #
  # @param [Array<Symbol>] metric_keys
  # The keys of the metrics as they were defined in the origin question.
  #
  # @param [Hash] options
  # @param [Symbol] options[:from]
  # The origin analyzer class you want to inherit from.
  #
  # Example:
  #
  #   module CanvasQuizStatistics::Analyzers
  #     class Matching < Base
  #       inherit :correct, :incorrect, from: :fill_in_multiple_blanks
  #     end
  #   end
  #
  def inherit(*metric_keys, options)
    metrics = metrics_for(options[:from])

    return inherit_metrics(options[:from]) if metric_keys.first == :all

    metric_keys.each do |metric_key|
      metric = metrics.detect { |m| m[:key] == metric_key }

      unless metric.present?
        raise "Metric #{metric_key} could not be found in #{options[:from]}"
      end

      self.metrics[question_type] << metric
    end
  end

  def metrics
    @@metrics ||= Hash.new { |hsh, key| hsh[key] = [] }
  end

  protected

  def metrics_for(question_type)
    target = question_type.to_s
    target = "#{target}_question" unless /_question$/.match?(target)

    metrics[target.to_sym]
  end
end
