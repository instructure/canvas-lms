#
# Copyright (C) 2013 - present Instructure, Inc.
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

module DataFixup
  class FixBlankCourseSectionNames

    def self.time_format(section)
      Time.use_zone(section.root_account.try(:default_time_zone) || 'UTC') do
        section.created_at.strftime("%Y-%m-%d").to_s
      end
    end

    def self.run
      CourseSection.where("name IS NULL OR name = ' ' OR name = ''").find_each do |section|
        if section.default_section
          section.name = section.course.name
        else
          section.name = "#{section.course.name} #{time_format(section)}"
        end
        section.save!
      end
    end

  end
end
