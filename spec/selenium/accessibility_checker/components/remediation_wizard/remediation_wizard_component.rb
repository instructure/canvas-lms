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

require_relative "../../../common"
require_relative "wizard_header_component"
require_relative "wizard_footer_component"
require_relative "problem_area_component"
require_relative "alt_text_controls_component"
require_relative "caption_controls_component"
require_relative "radio_input_controls_component"

class RemediationWizardComponent
  include SeleniumDependencies

  def wizard_tray_selector
    "[role='dialog'][aria-label]"
  end

  def success_view_selector
    "[role='dialog'] header *:contains('You have fixed all accessibility issues on this page.')"
  end

  def unsaved_changes_modal_selector
    "[data-testid='unsaved-changes-modal']"
  end

  def wizard_tray
    f(wizard_tray_selector)
  end

  def wizard_tray_exists?
    element_exists?(wizard_tray_selector)
  end

  def wizard_tray_open?
    wizard_tray_exists? && wizard_tray.displayed?
  end

  def success_view_exists?
    !fj(success_view_selector).nil?
  rescue
    false
  end

  def unsaved_changes_modal_visible?
    element_exists?(unsaved_changes_modal_selector) && f(unsaved_changes_modal_selector).displayed?
  rescue
    false
  end

  def issue_message_visible?(message)
    !fj("[role='dialog'] *:contains(\"#{message}\")").nil?
  rescue
    false
  end

  def visible?
    wizard_tray_open?
  end

  def wait_for_form_to_render
    wait_for_ajaximations
    # Wait for problem area to be rendered (present for all issue types)
    keep_trying_until(15) do
      problem_area.visible?
    end
  end

  def apply_fix
    apply_button&.click
    wait_for_ajaximations
  end

  def apply_button_disabled?
    apply_button.attribute("disabled") == "true"
  end

  def save_and_next
    footer.click_save_and_next_button
    wait_for_ajaximations
  end

  def skip_issue
    footer.click_skip_button
    wait_for_ajaximations
  end

  def apply_button
    f("[data-testid='apply-button']")
  end

  def undo_button
    f("[data-testid='undo-button']")
  end

  def undo_button_enabled?
    undo_button.attribute("disabled").nil? && undo_button.attribute("aria-disabled") != "true"
  rescue
    false
  end

  def fix_applied_message_visible?(message)
    !fj("[role='dialog'] *:contains('#{message}')").nil?
  rescue
    false
  end

  def click_undo
    undo_button.click
    wait_for_ajaximations
  end

  def header
    @header ||= WizardHeaderComponent.new
  end

  def footer
    @footer ||= WizardFooterComponent.new
  end

  def problem_area
    @problem_area ||= ProblemAreaComponent.new
  end

  def alt_text_controls
    @alt_text_controls ||= AltTextControlsComponent.new
  end

  def caption_controls
    @caption_controls ||= CaptionControlsComponent.new
  end

  def radio_input_controls
    @radio_input_controls ||= RadioInputControlsComponent.new
  end
end
