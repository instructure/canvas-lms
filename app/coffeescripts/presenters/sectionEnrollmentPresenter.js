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

import I18n from 'i18n!section'
import _ from 'underscore'
import toUnderscore from '../str/underscore'

// declare all used i18n keys here to cluttering up the logic
const keys = {
  limited: {
    TeacherEnrollment: I18n.t('enrolled_as_limited_teacher', 'enrolled as a teacher with section-only access'),
    TaEnrollment: I18n.t('enrolled_as_limited_ta', 'enrolled as a TA with section-only access'),
    ObserverEnrollment: I18n.t('enrolled_as_limited_observer', 'enrolled as a observer with section-only access'),
    DesignerEnrollment: I18n.t('enrolled_as_limited_designer', 'enrolled as a designer with section-only access'),
    StudentEnrollment: I18n.t('enrolled_as_limited_student', 'enrolled as a student with section-only access'),
  },
  standard: {
    TeacherEnrollment: I18n.t('enrolled_as_teacher', 'enrolled as a teacher'),
    TaEnrollment: I18n.t('enrolled_as_ta', 'enrolled as a TA'),
    ObserverEnrollment: I18n.t('enrolled_as_observer', 'enrolled as a observer'),
    DesignerEnrollment: I18n.t('enrolled_as_designer', 'enrolled as a designer'),
    StudentEnrollment: I18n.t('enrolled_as_student', 'enrolled as a student'),
  },
}

// #
// begin returned function here
// @param {array} array of enrollments returned from /courses/:course_id/enrollments
export default data =>
  _.map(data, (enrollment) => {
    const scope = enrollment.limit_privileges_to_course_section ? 'limited' : 'standard'

    // add extra fields to enrollments
    enrollment.typeLabel = keys[scope][enrollment.type]
    enrollment.permissions = ENV.PERMISSIONS
    enrollment.typeClass = toUnderscore(enrollment.type)

    return enrollment
  })
