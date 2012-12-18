#
# Copyright (C) 2012 Instructure, Inc.
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
#

module SelfEnrollmentsHelper
  def registration_summary
    # allow plugins to display additional content
    if @registration_summary
      markdown(@registration_summary, :never) rescue nil
    end
  end

  def agree_to_terms
    @agree_to_terms ||
    t("#self_enrollments.agree_to_terms",
      "You agree to the *terms of use*.",
      :wrapper => link_to('\1', "http://www.instructure.com/terms-of-use", :target => "_new"))
  end
end