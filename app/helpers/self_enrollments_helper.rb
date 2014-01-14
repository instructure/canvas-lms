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
  def self_enrollment_url
    api_v1_course_enrollments_url(@course, enrollment: {self_enrollment_code: params[:self_enrollment_code], user_id: "self"})
  end

  def registration_summary
    # allow plugins to display additional content
    if @registration_summary
      markdown(@registration_summary, :never) rescue nil
    end
  end
end
