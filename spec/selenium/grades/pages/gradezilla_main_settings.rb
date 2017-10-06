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

require_relative '../../common'
module MainSettings
  class Controls
    class << self
      include SeleniumDependencies

      def cancel_button
        f('#gradebook-settings-cancel-button')
      end

      def update_button
        f('#gradebook-settings-update-button')
      end

      def click_cancel_button
        cancel_button.click
      end

      def click_update_button
        update_button.click
        wait_for_animations
      end
    end
  end
end
