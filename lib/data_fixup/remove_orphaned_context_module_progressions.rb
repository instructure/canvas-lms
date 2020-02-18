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

module DataFixup::RemoveOrphanedContextModuleProgressions
  def self.run
    scope = ContextModuleProgression.
        joins(:context_module).
        where(context_modules: { context_type: 'Course' }).
        where("requirements_met=? OR requirements_met IS NULL", [].to_yaml).
        where("NOT EXISTS (?)", Enrollment.where("course_id=context_id AND enrollments.user_id=context_module_progressions.user_id"))
    scope.find_ids_in_ranges do |first, last|
      ContextModuleProgression.where(id: first..last).delete_all
    end
  end
end
