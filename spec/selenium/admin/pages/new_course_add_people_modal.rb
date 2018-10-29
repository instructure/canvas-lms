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

module NewCourseAddPeopleModal


  # ---------------------- Controls ----------------------
  def add_people_modal
    f('#add_people_modal')
  end

  def add_people_header
    f('#add_people_modal h2')
  end

  def role_options
    ff('#peoplesearch_select_role option', add_people_modal).map(&:text)
  end

  def section_options
    ff('#peoplesearch_select_section option', add_people_modal).map(&:text)
  end
end
