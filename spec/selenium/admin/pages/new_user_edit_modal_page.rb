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

module NewUserEditModalPage

  # ---------------------- Controls ----------------------

  def modal_object
    f('[aria-label="Add a New User"]')
  end

  def full_name_input
    fj('label:contains("Full Name") input', modal_object)
  end

  def email_input
    fj('label:contains("Email") input', modal_object)
  end

  def sortable_name_input
    fj('label:contains("Sortable Name") input', modal_object)
  end

  def email_about_creation_check
    fj('label:contains("Email the user about this account creation")')
  end

  def modal_submit_button
    f('button[type="submit"]')
  end

  # ---------------------- Actions ----------------------

  def click_email_creation_check
    email_about_creation_check.click
  end

  def click_modal_submit
    modal_submit_button.click
    wait_for_ajaximations
  end
end
