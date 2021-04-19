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

import User from '@canvas/users/backbone/models/User.coffee'
import secondsToTime from '../../util/secondsToTime'
import _ from 'underscore'

export default class RosterUser extends User

  defaults:
    avatar_url: '/images/messages/avatar-50.png'

  computedAttributes: [
    'sections'
    'total_activity_string'
    {name: 'html_url', deps: ['enrollments']}
  ]

  html_url: ->
    @get('enrollments')[0]?.html_url

  sections: ->
    return [] unless @collection?.sections?
    {sections} = @collection
    user_sections = []
    for {course_section_id} in @get('enrollments')
      user_section = sections.get(course_section_id)
      user_sections.push(user_section.attributes) if user_section
    user_sections

  total_activity_string: ->
    if time = _.max(_.map(@get('enrollments'), (e) -> e.total_activity_time))
      secondsToTime(time)
    else
      ''

