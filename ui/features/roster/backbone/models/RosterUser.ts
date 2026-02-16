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
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('user')

type Identifier = string | number

interface RosterSection extends Record<string, unknown> {
  id: Identifier
  name: string
}

interface RosterEnrollment extends Record<string, unknown> {
  id?: Identifier
  course_section_id: Identifier
  enrollment_state: string
  html_url?: string
  total_activity_time?: number
}

interface RosterUserAttributes extends Record<string, unknown> {
  enrollments: RosterEnrollment[]
  avatar_url?: string
}

interface SectionCollectionLike {
  get: (id: Identifier) => {attributes: RosterSection} | undefined
}

interface RosterUserCollectionLike {
  sections?: SectionCollectionLike | null
}

class RosterUser extends User {
  declare attributes: RosterUserAttributes
  declare collection?: RosterUserCollectionLike
  declare defaults: {avatar_url: string}
  declare computedAttributes: Array<string | {name: string; deps: string[]}>
  declare get: <K extends keyof RosterUserAttributes>(key: K) => RosterUserAttributes[K]

  html_url(): string | undefined {
    return this.get('enrollments')[0]?.html_url
  }

  sections(): Array<Record<string, unknown>> {
    if (!(this.collection instanceof Object)) return []
    const {sections} = this.collection
    if (sections === null || typeof sections === 'undefined') return []
    const user_sections: Array<Record<string, unknown>> = []
    for (const {course_section_id, enrollment_state} of this.get('enrollments')) {
      const user_section = sections.get(course_section_id)
      if (user_section) {
        const section: Record<string, unknown> & {name?: string} = {
          ...user_section.attributes,
        }
        if (enrollment_state === 'inactive') {
          const sectionName = typeof section.name === 'string' ? section.name : ''
          section.name = I18n.t('%{section_name} - Inactive', {section_name: sectionName})
        }
        user_sections.push(section)
      }
    }
    return user_sections
  }

  total_activity_string(): string {
    const times = this.get('enrollments').map(e => Number(e.total_activity_time ?? 0))
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
