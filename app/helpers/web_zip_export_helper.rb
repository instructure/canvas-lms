#
# Copyright (C) 2017 Instructure, Inc.
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

module WebZipExportHelper
  def course_allow_web_export_download?
    @context.account.enable_offline_web_export? && @context.enable_offline_web_export?
  end

  def allow_web_export_for_course_user?
    @context.enrollments.not_inactive_by_date.where(user_id: @current_user).exists? ||
      @context.grants_any_right?(@current_user, :read_as_admin)
  end

  def allow_web_export_download?
    course_allow_web_export_download? && allow_web_export_for_course_user?
  end
end
