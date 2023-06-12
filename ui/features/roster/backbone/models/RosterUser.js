//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import User from '@canvas/users/backbone/models/User'
import secondsToTime from '../../util/secondsToTime'

class RosterUser extends User {
  html_url() {
    return this.get('enrollments')[0]?.html_url
  }

  sections() {
    if (!(this.collection instanceof Object)) return []
    const {sections} = this.collection
    if (sections === null || typeof sections === 'undefined') return []
    const user_sections = []
    for (const {course_section_id} of this.get('enrollments')) {
      const user_section = sections.get(course_section_id)
      if (user_section) user_sections.push(user_section.attributes)
    }
    return user_sections
  }

  total_activity_string() {
    const times = this.get('enrollments').map(e => e.total_activity_time)
    const maxTime = Math.max(...times)
    return maxTime ? secondsToTime(maxTime) : ''
  }
}

RosterUser.prototype.defaults = {avatar_url: '/images/messages/avatar-50.png'}

RosterUser.prototype.computedAttributes = [
  'sections',
  'total_activity_string',
  {name: 'html_url', deps: ['enrollments']},
]

export default RosterUser
