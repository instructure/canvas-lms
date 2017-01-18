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
    def initialize(course, user)
      @course = course
      @user = user
    end
    attr_reader :course, :user

    def epub_export
      unless @_epub_export
        @_epub_export = course.epub_exports.visible_to(user).running.first
        @_epub_export ||= course.epub_exports.build({
          user: user
        })
      end
      @_epub_export
    end

    def already_running?
      !epub_export.new_record?
    end

    def save
      if !already_running? && epub_export.save
        # Queuing jobs always returns nil, yay
        epub_export.export
        true
      else
        false
      end
    end
  end
end
