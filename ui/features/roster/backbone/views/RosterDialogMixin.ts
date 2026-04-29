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

import {useScope as createI18nScope} from '@canvas/i18n'
import {map, reject, includes, filter} from 'es-toolkit/compat'
import '@canvas/jquery/jquery.disableWhileLoading'

const I18n = createI18nScope('RosterDialogMixin')

interface Enrollment {
  id: string
  course_section_id: string
  [key: string]: unknown
}

interface Section {
  id: string
  name: string
  [key: string]: unknown
}

interface RosterDialogMixinType {
  $el: JQuery
  model: {
    get: (key: string) => unknown
    set: (attrs: Record<string, unknown>) => unknown
  }
  disable: (dfds: unknown) => JQuery
  updateEnrollments: (addEnrollments: Enrollment[], removeEnrollments: Enrollment[]) => unknown
}

const RosterDialogMixin: Omit<RosterDialogMixinType, '$el' | 'model'> = {
  disable(this: RosterDialogMixinType, dfds: unknown) {
    return this.$el.disableWhileLoading(dfds, {
      buttons: {'.btn-primary .ui-button-text': I18n.t('updating', 'Updating...')},
    })
  },

  updateEnrollments(
    this: RosterDialogMixinType,
    addEnrollments: Enrollment[],
    removeEnrollments: Enrollment[],
  ) {
    let enrollments = this.model.get('enrollments') as Enrollment[]
    enrollments = enrollments.concat(addEnrollments)
    const removeIds = map(removeEnrollments, 'id')
    enrollments = reject(enrollments, en => includes(removeIds, en.id))
    const sectionIds = map(enrollments, 'course_section_id')
    const sections = (
      filter(ENV.SECTIONS as Section[], s => includes(sectionIds, s.id)) as Section[]
    ).sort((a, b) => a.name.localeCompare(b.name))
    return this.model.set({enrollments, sections})
  },
}

export default RosterDialogMixin
