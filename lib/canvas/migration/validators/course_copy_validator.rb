#
# Copyright (C) 2013 - 2014 Instructure, Inc.
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

module Canvas::Migration::Validators::CourseCopyValidator
  def self.has_error(options, user, course)
    if !options || !options[:source_course_id]
      return I18n.t :course_copy_argument_error, 'A course copy requires a source course.'
    end
    source = Course.where(id: options[:source_course_id]).first
    if source
      if !(source.grants_right?(user, :read_as_admin) && source.grants_right?(user, :read))
        return I18n.t :course_copy_not_allowed_error, 'You are not allowed to copy the source course.'
      end
    else
      return I18n.t :course_copy_no_course_error, 'The source course was not found.'
    end

    false
  end
end
