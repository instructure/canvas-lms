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

require_relative "../../common"

class UploadModalComponent
  include SeleniumDependencies

  def initialize(modal_title)
    @modal_title = modal_title
    @upload_modal = upload_modal
  end

  def upload_modal
    f(%(form[aria-label="#{@modal_title}"]))
  end

  def url_tab
    fj('[role="tab"]:contains("URL")', @upload_modal)
  end

  def url_input
    f('input[name$="url"]', @upload_modal)
  end

  def submit_button
    fj('button:contains("Submit")', @upload_modal)
  end
end
