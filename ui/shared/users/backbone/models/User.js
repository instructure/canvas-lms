/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import _ from 'underscore'
import Backbone from '@canvas/backbone'

const I18n = useI18nScope('user')

export default (function (superClass) {
  extend(User, superClass)

  function User() {
    return User.__super__.constructor.apply(this, arguments)
  }

  User.prototype.modelType = 'user'

  User.prototype.resourceName = 'users'

  User.prototype.errorMap = {
    name: {
      blank: I18n.t('errors.required', 'Required'),
      too_long: I18n.t('errors.too_long', "Can't exceed %{max} characters", {
        max: 255,
      }),
    },
    self_enrollment_code: {
      blank: I18n.t('errors.required', 'Required'),
      invalid: I18n.t('errors.invalid_code', 'Invalid code'),
      already_enrolled: I18n.t(
        'errors.already_enrolled',
        'You are already enrolled in this course'
      ),
      concluded: I18n.t('This course has concluded'),
      full: I18n.t('errors.course_full', 'This course is full'),
    },
    terms_of_use: {
      accepted: I18n.t('errors.terms', 'You must agree to the terms'),
    },
  }

  // first: optional boolean to return only the first match
  User.prototype.enrollments = function (attrs, first) {
    return _.where(this.get('enrollments'), attrs, first)
  }

  User.prototype.hasEnrollmentType = function (type) {
    return !!this.enrollments(
      {
        type,
      },
      true
    )
  }

  User.prototype.hasEnrollmentRole = function (role) {
    return !!this.enrollments(
      {
        role,
      },
      true
    )
  }

  User.prototype.findEnrollmentByRole = function (role) {
    return this.enrollments(
      {
        role,
      },
      true
    )
  }

  User.prototype.allEnrollmentsByType = function (type) {
    return this.enrollments({
      type,
    })
  }

  User.prototype.allEnrollmentsByRole = function (role) {
    return this.enrollments({
      role,
    })
  }

  User.prototype.pending = function (role) {
    return _.some(this.get('enrollments'), function (e) {
      let ref
      return (
        e.role === role && ((ref = e.enrollment_state) === 'creation_pending' || ref === 'invited')
      )
    })
  }

  User.prototype.inactive = function () {
    return _.every(this.get('enrollments'), function (e) {
      return e.enrollment_state === 'inactive'
    })
  }

  User.prototype.sectionEditableEnrollments = function () {
    return _.select(this.get('enrollments'), function (e) {
      return e.type !== 'ObserverEnrollment'
    })
  }

  return User
})(Backbone.Model)
