//
// Copyright (C) 2012 - present Instructure, Inc.
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
//

// #
// sectionEnrollmentPresenter
//
// this function expects JSON input from /sections/:course_id/enrollments and
// returns an array of enrollments meant for display on /courses/:course_id/sections/:id.

import {useScope as useI18nScope} from '@canvas/i18n'
import {map} from 'lodash'
import {underscoreString} from '@canvas/convert-case'

const I18n = useI18nScope('section')

// declare all used i18n keys here to cluttering up the logic
const keys = {
  limited: {
    get TeacherEnrollment() {
      return I18n.t('enrolled_as_limited_teacher', 'enrolled as: Teacher with section-only access')
    },
    get TaEnrollment() {
      return I18n.t('enrolled_as_limited_ta', 'enrolled as: TA with section-only access')
    },
    get ObserverEnrollment() {
      return I18n.t(
        'enrolled_as_limited_observer',
        'enrolled as: Observer with section-only access'
      )
    },
    get DesignerEnrollment() {
      return I18n.t(
        'enrolled_as_limited_designer',
        'enrolled as: Designer with section-only access'
      )
    },
    get StudentEnrollment() {
      return I18n.t('enrolled_as_limited_student', 'enrolled as: Student with section-only access')
    },
  },
  standard: {
    get TeacherEnrollment() {
      return I18n.t('enrolled_as_teacher', 'enrolled as: Teacher')
    },
    get TaEnrollment() {
      return I18n.t('enrolled_as_ta', 'enrolled as: TA')
    },
    get ObserverEnrollment() {
      return I18n.t('enrolled_as_observer', 'enrolled as: Observer')
    },
    get DesignerEnrollment() {
      return I18n.t('enrolled_as_designer', 'enrolled as: Designer')
    },
    get StudentEnrollment() {
      return I18n.t('enrolled_as_student', 'enrolled as: Student')
    },
  },
}

// #
// begin returned function here
// @param {array} array of enrollments returned from /courses/:course_id/enrollments
export default data =>
  map(data, enrollment => {
    const scope = enrollment.limit_privileges_to_course_section ? 'limited' : 'standard'
    const customLimited = I18n.t('enrolled as: %{enrollment_type} with section-only access', {
      enrollment_type: `${enrollment.role}`,
    })
    const customStandard = I18n.t('enrolled as: %{enrollment_type}', {
      enrollment_type: `${enrollment.role}`,
    })
    const customLabel = scope === 'limited' ? customLimited : customStandard

    // add extra fields to enrollments
    enrollment.typeLabel = keys[scope][enrollment.role] || customLabel
    enrollment.typeClass = underscoreString(enrollment.type)

    return enrollment
  })
