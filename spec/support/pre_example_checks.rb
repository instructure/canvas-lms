# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module PreExampleChecks
  @log_entries = []

  class << self
    def log(message)
      @log_entries << message
    end

    attr_reader :log_entries

    def append_before_example_hooks(example)
      checks = PreExampleChecks::Base.descendants.select { |c| c.run_types.include?(:before_example) }
      example.example_group.before do
        checks.each(&:check_and_log)
      end
    end

    def append_after_example_hooks(example)
      checks = PreExampleChecks::Base.descendants.select { |c| c.run_types.include?(:after_example) }
      example.example_group.after do
        checks.each(&:check_and_log)
      end
    end
  end
end
