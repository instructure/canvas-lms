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

require_relative '../../../common'

module Gradezilla
  module Settings
    extend SeleniumDependencies

    def self.tab(label:)
      # only works if not currently active
      ff('[data-uid="Tab"][role="presentation"]').find do |el|
        el.text == label
      end
    end

    def self.click_advanced_tab
      tab(label: 'Advanced').click
    end

    def self.click_late_policy_tab
      tab(label: 'Late Policies').click
    end

    def self.cancel_button
      f('#gradebook-settings-cancel-button')
    end

    def self.update_button
      f('#gradebook-settings-update-button')
    end

    def self.click_cancel_button
      cancel_button.click
    end

    def self.click_update_button
      update_button.click
      wait_for_ajaximations
    end
  end
end
