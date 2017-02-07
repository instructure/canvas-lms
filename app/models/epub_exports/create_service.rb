#
# Copyright (C) 2011 Instructure, Inc.
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
module EpubExports
  class CreateService
    def initialize(course, user, export_type)
      @course = course
      @user = user
      @export_type = export_type
    end
    attr_reader :course, :user, :export_type

    def offline_export
      unless @_offline_export
        @_offline_export = course.send(export_type.to_s.pluralize).visible_to(user).running.first
        @_offline_export ||= course.send(export_type.to_s.pluralize).build({
          user: user
        })
      end
      @_offline_export
    end

    def already_running?
      !offline_export.new_record?
    end

    def save
      if !already_running? && offline_export.save
        # Queuing jobs always returns nil, yay
        offline_export.export
        true
      else
        false
      end
    end
  end
end
