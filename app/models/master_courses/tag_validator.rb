# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

class MasterCourses::TagValidator < ActiveModel::Validator
  # never used one of these before, not really sure why i'm starting now

  def validate(record)
    if record.new_record?
      unless MasterCourses::ALLOWED_CONTENT_TYPES.include?(record.content_type)
        record.errors[:content] << "Invalid content"
      end
    elsif record.content_id_changed? || record.content_type_changed? # apparently content_changed? didn't work at all - i must have been smoking something
      record.errors[:content] << "Cannot change content" # don't allow changes to content after creation
    end
  end
end
