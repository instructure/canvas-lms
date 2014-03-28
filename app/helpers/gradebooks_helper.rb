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

module GradebooksHelper
  def display_grade(grade)
    grade.blank? ? "--" : grade
  end

  def gradebook_url_for(user, context, assignment=nil)
    if context
      gradebook_version = get_gradebook_version(user, context)
      gradebook_url = polymorphic_url([context, gradebook_version])

      if assignment && gradebook_version == 'gradebook'
        gradebook_url += "#assignment/#{assignment.id}"
      end
    end

    gradebook_url
  end

  def get_gradebook_version(user, context)
    if user.nil? || user.prefers_gradebook2?(context)
      'gradebook2'
    elsif context.feature_enabled?(:screenreader_gradebook) && user.gradebook_preference == 'srgb'
      'screenreader_gradebook'
    elsif context.old_gradebook_visible?
      'gradebook'
    else
      'gradebook2'
    end
  end

end
