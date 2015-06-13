#
# Copyright (C) 2013 Instructure, Inc.
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

module Canvas::Migration::Validators::ZipImporterValidator
  def self.has_error(options, user, course)
    if !options || !options[:folder_id]
      return I18n.t :zip_argument_error, 'A .zip upload requires a folder to upload to.'
    end
    if !course.folders.where(id: options[:folder_id]).first
      return I18n.t :zip_no_folder_error, "The specified folder couldn't be found in this course."
    end

    false
  end
end
