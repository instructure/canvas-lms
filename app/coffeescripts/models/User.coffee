#
# Copyright (C) 2012-2013 Instructure, Inc.
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

define [
  'i18n!user'
  'underscore'
  'Backbone'
], (I18n, _, Backbone) ->

  class User extends Backbone.Model
    modelType: 'user'
    resourceName: 'users'

    errorMap:
      name:
        blank:        I18n.t("errors.required", "Required")
        too_long:     I18n.t("errors.too_long", "Can't exceed %{max} characters", {max: 255})
      self_enrollment_code:
        blank:        I18n.t("errors.required", "Required")
        invalid:      I18n.t("errors.invalid_code", "Invalid code")
        already_enrolled: I18n.t("errors.already_enrolled", "You are already enrolled in this course")
        full:         I18n.t("errors.course_full", "This course is full")
      terms_of_use:
        accepted:     I18n.t("errors.terms", "You must agree to the terms")

    # first: optional boolean to return only the first match
    enrollments: (attrs, first) ->
      _.where @get('enrollments'), attrs, first

    hasEnrollmentType: (type) ->
      !! @enrollments {type}, true

    hasEnrollmentRole: (role) ->
      !! @enrollments {role}, true

    findEnrollmentByRole: (role) ->
      @enrollments {role}, true

    allEnrollmentsByType: (type) ->
      @enrollments {type}

    allEnrollmentsByRole: (role) ->
      @enrollments {role}

    pending: (role) ->
      _.any @get('enrollments'), (e) -> e.role == role && e.enrollment_state in ['creation_pending', 'invited']

    sectionEditableEnrollments: ->
      _.select @get('enrollments'), (e) -> not _.include(['DesignerEnrollment', 'ObserverEnrollment'], e.type)

