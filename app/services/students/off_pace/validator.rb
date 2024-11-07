# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Students
  module OffPace
    class Validator < ApplicationService
      def initialize(student:)
        super()
        @student = student
      end

      def call
        @student.submissions.each do |submission|
          return true if submission.assignment.due_at < current_time_midnight && !submission.has_submission?
        end
        false
      end

      private

      attr_reader :student

      def current_time_midnight
        @current_time_midnight ||= Time.current.midnight
      end
    end
  end
end
