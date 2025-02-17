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

class NewSelectContentPage
  class << self
    include SeleniumDependencies

    # Selectors
    def outcome_parent
      fxpath("//*[contains(text(), 'Learning Outcomes')]/ancestor::button")
    end

    def outcome_option_caret_by_name(name)
      option_caret_by_name(name)
    end

    def outcome_option_checkbox_by_name(name)
      option_checkbox_by_name(name)
    end

    def module_parent
      fxpath("//*[contains(text(), 'Modules')]/ancestor::button")
    end

    def module_option_caret_by_name(name)
      option_caret_by_name(name)
    end

    def module_option_checkbox_by_name(name)
      option_checkbox_by_name(name)
    end

    def option_caret_by_name(name)
      fxpath("//*[contains(text(), '#{name}')]/ancestor::button")
    end

    def import_as_standalone_module_switch_by_name(name)
      fxpath("//*[contains(text(), '#{name}')]/ancestor::span//*[contains(text(), 'Import as a standalone module')]")
    end

    def option_checkbox_by_name(name)
      fxpath("//*[contains(text(), '#{name}')]/ancestor::label//span[@aria-hidden='true']")
    end

    def submit_button
      fxpath("//*[@aria-label='Select Content for Import']//button[2]")
    end
  end
end
