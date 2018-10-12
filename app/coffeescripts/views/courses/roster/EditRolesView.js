#
# Copyright (C) 2015 - present Instructure, Inc.
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

define [
  'i18n!course_settings'
  'jquery'
  'underscore'
  '../../DialogBaseView'
  './RosterDialogMixin'
  'jst/courses/roster/editRolesView'
  '../../../jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], (I18n, $, _, DialogBaseView, RosterDialogMixin, template) ->

  class EditRolesView extends DialogBaseView

    @mixin RosterDialogMixin

    template: template

    dialogOptions:
      width: '300px'
      id: 'edit_roles'
      title: I18n.t 'Edit Course Role'

    toJSON: ->
      json = {}

      role_ids = _.uniq(_.map(@model.enrollments(), (en) -> en.role_id))
      if role_ids.length > 1
        json.has_multiple_roles = true
      else
        @role_id = role_ids[0]
        json.role_id = @role_id

      json.roles = ENV.ALL_ROLES
      json

    update: (e) =>
      e.preventDefault()

      new_role_id = @$el.find('#role_id').val()
      if new_role_id == @role_id
        @close() # nothing changed
        return

      enrollments = @model.enrollments()

      # section ids that already have the new role
      existing_section_ids = _.map(_.filter(enrollments, (en) -> en.role_id == new_role_id), (en) -> en.course_section_id)

      new_enrollments = []
      deleted_enrollments = []

      deferreds = []

      # limit to sections if all enrollments are limited
      section_limited = _.all(enrollments, (en) -> en.limit_privileges_to_course_section)

      for en in enrollments
        unless en.role_id == new_role_id # leave alone if it already has the new role

          deleted_enrollments.push(en)
          deferreds.push($.ajaxJSON("#{ENV.COURSE_ROOT_URL}/unenroll/#{en.id}", 'DELETE')) # delete the enrollment

          unless _.include(existing_section_ids, en.course_section_id)
            # create a new enrollment unless there's alrady one with the new role and the same course section
            existing_section_ids.push(en.course_section_id)
            data = {
              enrollment:
                user_id: @model.get('id')
                role_id: new_role_id
                limit_privileges_to_course_section: section_limited
                enrollment_state: en.enrollment_state
            }
            deferreds.push($.ajaxJSON("/api/v1/sections/#{en.course_section_id}/enrollments", 'POST', data, (new_enrollment) =>
              _.extend(new_enrollment, { can_be_removed: true })
              new_enrollments.push(new_enrollment)
            ))

      @disable($.when(deferreds...)
      .done =>
        @updateEnrollments new_enrollments, deleted_enrollments
        $.flashMessage I18n.t("Role successfully updated")
      .fail ->
        $.flashError I18n.t("Something went wrong updating the user's role. Please try again later.")
      .always => @close())

