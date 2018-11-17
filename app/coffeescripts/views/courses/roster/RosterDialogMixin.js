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

import I18n from 'i18n!roster'
import _ from 'underscore'
import 'jquery.disableWhileLoading'

const RosterDialogMixin = {
  disable(dfds) {
    return this.$el.disableWhileLoading(dfds, {
      buttons: {'.btn-primary .ui-button-text': I18n.t('updating', 'Updating...')}
    })
  },

  updateEnrollments(addEnrollments, removeEnrollments) {
    let enrollments = this.model.get('enrollments')
    enrollments = enrollments.concat(addEnrollments)
    const removeIds = _.pluck(removeEnrollments, 'id')
    enrollments = _.reject(enrollments, en => _.include(removeIds, en.id))
    const sectionIds = _.pluck(enrollments, 'course_section_id')
    const sections = _.select(ENV.SECTIONS, s => _.include(sectionIds, s.id))
    return this.model.set({enrollments, sections})
  }
}

export default RosterDialogMixin
