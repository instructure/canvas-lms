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

module Lti
  class ResourcePlacement < ActiveRecord::Base

    RESOURCE_SELECTION = 'resource_selection'
    ACCOUNT_NAVIGATION = 'account_navigation'
    COURSE_NAVIGATION = 'course_navigation'

    PLACEMENT_LOOKUP = {
      'Canvas.placements.account-nav' => ACCOUNT_NAVIGATION,
      'Canvas.placements.course-nav' => COURSE_NAVIGATION
    }.freeze

    attr_accessible :placement, :resource_handler

    belongs_to :resource_handler, class_name: 'Lti::ResourceHandler'
    validates_presence_of :resource_handler, :placement

    validates_inclusion_of :placement, :in => [RESOURCE_SELECTION, ACCOUNT_NAVIGATION, COURSE_NAVIGATION]

  end
end