# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Analyzers
  class BaseAnalyzer < GraphQL::Analysis::Analyzer
    protected

    def argument_value(node, visitor, argument)
      field_defn = visitor.field_definition
      arguments = visitor.arguments_for(node, field_defn)

      input = arguments[:input]
      unless input.respond_to?(:to_h)
        log_to_sentry("Base Analyzer: unable to process input", input:)
        return
      end

      input.to_h[argument]
    end

    def log_to_sentry(message, extra = {})
      extra = extra.merge(additional_context)
      Sentry.with_scope do |scope|
        scope.set_context("graphql", extra)
        Sentry.capture_message(message, level: :warning)
      end
    end

    private

    def additional_context
      # subject is either a query or a multiplex, and the parent class constructor assigns the subject to @query or
      # @multiplex after a class check
      { operation_name: (@query ? @query.operation_name : @multiplex.map(&:operation_name).join(", ")) }
    end
  end
end
