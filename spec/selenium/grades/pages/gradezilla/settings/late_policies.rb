#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../../../../common'
require_relative '../settings'

module Gradezilla
  module Settings
    module LatePolicies
      extend SeleniumDependencies

      def self.missing_policy_checkbox
        fj('label:contains("Automatically apply grade for missing submissions")')
      end

      def self.missing_policy_percent_input
        f('#missing-submission-grade')
      end

      def self.late_policy_checkbox
        fj('label:contains("Automatically apply deduction to late submissions")')
      end

      def self.late_policy_deduction_input
        f('#late-submission-deduction')
      end

      def self.late_policy_increment_combobox(increment)
        click_option(f('#late-submission-interval'), increment)
      end

      def self.lowest_grade_percent_input
        f('#late-submission-minimum-percent')
      end

      def self.select_late_policy_tab
        late_policy_tab.click
      end

      def self.create_missing_policy(percent_per_assignment)
        unless missing_policy_checkbox.attribute('checked')
          missing_policy_checkbox.click
        end
        set_value(missing_policy_percent_input, percent_per_assignment)
      end

      def self.disable_missing_policy
        if missing_policy_checkbox.attribute('checked')
          missing_policy_checkbox.click
        end
      end

      def self.disable_late_policy
        if late_policy_checkbox.attribute('checked')
          late_policy_checkbox.click
        end
      end

      def self.create_late_policy(percentage, time_increment, lowest_percentage = nil)
        late_policy_checkbox.click
        set_value(late_policy_deduction_input, percentage)
        late_policy_increment_combobox(time_increment)
        if lowest_percentage
          set_value(lowest_grade_percent_input, lowest_percentage)
        end
      end
    end
  end
end
