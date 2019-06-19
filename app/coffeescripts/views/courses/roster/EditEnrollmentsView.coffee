#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'compiled/views/DialogBaseView'
  'compiled/views/courses/roster/RosterDialogMixin'
  'jst/courses/roster/EditEnrollmentsView'
  'str/htmlEscape'
  'compiled/jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], (I18n, $, _, DialogBaseView, RosterDialogMixin, editEnrollmentsViewTemplate, h) ->

  class EditEnrollmentsView extends DialogBaseView

    @mixin RosterDialogMixin

    dialogOptions:
      id: 'edit_enrollment_placement'
      title: 'Custom Placement'

    render: ->
      @$el.html editEnrollmentsViewTemplate
        context_modules: @context_modules
      this

    update: (e) =>
      e.preventDefault()

      return unless confirm(' Please confirm that you want to custom place this user.')

      contentTagId = $('select#content_tag_id').val()

      deferreds = []

      url = "/api/v1/courses/#{@enrollment.course_id}/enrollments/#{@enrollment.id}/custom_placement"
      data =
        content_tag:
          id: contentTagId

      deferreds.push $.ajaxJSON url, 'POST', data

      @disable($.when(deferreds...)
        .done =>
          $.flashMessage 'Custom placement process started. You can check progress by viewing the course as the student.'
        .fail ->
          $.flashError "Something went wrong attempting to custom place the user. Please try again later."
        .always => @close())
