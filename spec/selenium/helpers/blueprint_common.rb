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

require File.expand_path(File.dirname(__FILE__) + '/../common')

module BlueprintCourseCommon
    # call this via change_blueprint_settings(course, content: false, points: false, due_dates: false, availability_dates: false)
    def change_blueprint_settings(course, master_blueprint_settings={})
        template = MasterCourses::MasterTemplate.full_template_for(course)
        template.update(default_restrictions: master_blueprint_settings)
        course.reload
    end
end
