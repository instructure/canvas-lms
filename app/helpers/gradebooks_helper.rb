#
# Copyright (C) 2014 Instructure, Inc.
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

module GradebooksHelper
  def display_grade(grade)
    grade.blank? ? "--" : grade
  end

  def gradebook_url_for(user, context, assignment=nil)
    gradebook_version = user.try(:preferred_gradebook_version, context) || '2'

    if !context.feature_enabled?(:screenreader_gradebook) && (gradebook_version == "2" || !context.old_gradebook_visible?)
      return polymorphic_url([context, 'gradebook2'])
    elsif gradebook_version == "1" && assignment
      return polymorphic_url([context, 'gradebook']) + "#assignment/#{assignment.id}"
    end

    polymorphic_url([context, 'gradebook'])
  end
end
