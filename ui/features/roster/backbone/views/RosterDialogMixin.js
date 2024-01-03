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

import {useScope as useI18nScope} from '@canvas/i18n'
import {map, reject, includes, filter} from 'lodash'
import '@canvas/jquery/jquery.disableWhileLoading'

const I18n = useI18nScope('RosterDialogMixin')

const RosterDialogMixin = {
  disable(dfds) {
    return this.$el.disableWhileLoading(dfds, {
      buttons: {'.btn-primary .ui-button-text': I18n.t('updating', 'Updating...')},
    })
  },

  updateEnrollments(addEnrollments, removeEnrollments) {
    let enrollments = this.model.get('enrollments')
    enrollments = enrollments.concat(addEnrollments)
    const removeIds = map(removeEnrollments, 'id')
    enrollments = reject(enrollments, en => includes(removeIds, en.id))
    const sectionIds = map(enrollments, 'course_section_id')
    const sections = filter(ENV.SECTIONS, s => includes(sectionIds, s.id))
    return this.model.set({enrollments, sections})
  },
}

export default RosterDialogMixin
