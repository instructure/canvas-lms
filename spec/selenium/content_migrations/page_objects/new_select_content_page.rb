# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class SelectContentPage
  class << self
    include SeleniumDependencies

    # Selectors
    def outcome_parent
      f('[data-testid="checkbox-copy[all_learning_outcomes]"]')
    end

    def outcome_options(index)
      ff('li[data-type="learning_outcomes"] a')[index].click
      wait_for_ajax_requests
    end

    def outcome_checkboxes(index)
      ff('li[data-type="learning_outcomes"] input')[index].click
      wait_for_ajax_requests
    end

    def submit_button
      f(".selectContentDialog input[type=submit]").click
      wait_for_ajax_requests
    end
  end
end
