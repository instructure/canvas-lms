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

class CaptionControlsComponent
  include SeleniumDependencies

  def caption_input
    f("[role='dialog'] [data-testid='text-input-form']")
  end

  def enter_caption(text)
    caption_input.clear
    caption_input.send_keys(text)
    wait_for_ajaximations
  end

  def clear_caption
    caption_input.send_keys([:control, "a"], :backspace)
    wait_for_ajaximations
  end

  def caption_input_value
    caption_input.attribute("value")
  end

  def caption_input_disabled?
    caption_input.attribute("disabled") == "true"
  end

  def caption_required_message_visible?
    !!fj("[role='dialog'] span:contains('Caption cannot be empty.')")&.displayed?
  rescue
    false
  end
end
