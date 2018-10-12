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
  '../../DialogBaseView'
  './RosterDialogMixin'
  'jst/courses/roster/LinkToStudentsView'
  'jquery.disableWhileLoading'
], (I18n, $, _, DialogBaseView, RosterDialogMixin, linkToStudentsViewTemplate) ->

  class LinkToStudentsView extends DialogBaseView

    @mixin RosterDialogMixin

    dialogOptions:
      id: 'link_students'
      title: I18n.t 'titles.link_to_students', 'Link to Students'

    render: ->
      data = @model.toJSON()
      data.studentsUrl = ENV.SEARCH_URL
      @$el.html linkToStudentsViewTemplate data

      @students = []
      @$('#student_input').contextSearch
        contexts: ENV.CONTEXTS
        placeholder: I18n.t 'link_students_placeholder', 'Enter a student name'
        change: (tokens) =>
          @students = tokens
        onNewToken: @onNewToken
        selector:
          baseData:
            type: 'user'
            context: "course_#{ENV.course.id}_students"
            exclude: [@model.get('id')]
            skip_visibility_checks: true
          noExpand: true
          browser:
            data:
              per_page: 100
              types: ['user']
      input = @$('#student_input').data('token_input')
      input.$fakeInput.css('width', '100%')

      for e in @model.allEnrollmentsByType('ObserverEnrollment')
        if e.observed_user && _.any(e.observed_user.enrollments)
          input.addToken
            value: e.observed_user.id
            text: e.observed_user.name
            data: e.observed_user

      this

    onNewToken: ($token) =>
      $link = $token.find('a')
      $link.attr('href', '#')
      $link.attr('title', I18n.t("Remove linked student %{name}", name: $token.find('div').attr('title')))
      $screenreader_span = $('<span class="screenreader-only"></span>').text(
        I18n.t("Remove linked student %{name}", name: $token.find('div').attr('title')))
      $link.append($screenreader_span)

    getUserData: (id) ->
      $.getJSON("/api/v1/courses/#{ENV.course.id}/users/#{id}", include:['enrollments'])

    update: (e) =>
      e.preventDefault()

      dfds = []
      enrollments = @model.allEnrollmentsByType('ObserverEnrollment')
      enrollment = enrollments[0]
      unlinkedEnrolls = _.filter enrollments, (en) -> !en.associated_user_id # keep the original observer enrollment around
      currentLinks = _.compact _.pluck(enrollments, 'associated_user_id')
      newLinks = _.difference @students, currentLinks
      removeLinks = _.difference currentLinks, @students
      newEnrollments = []

      if newLinks.length
        newDfd = $.Deferred()
        dfds.push newDfd.promise()
        dfdsDone = 0

      # create new links
      for id in newLinks
        @getUserData(id).done (user) =>
          udfds = []
          sections = _.map user.enrollments, (en) -> en.course_section_id
          for sId in sections
            url = "/api/v1/sections/#{sId}/enrollments"
            data =
              enrollment:
                user_id: @model.get('id')
                associated_user_id: user.id
                type: enrollment.type
                limit_privileges_to_course_section: enrollment.limit_priveleges_to_course_section
            if enrollment.role != enrollment.type
              data.enrollment.role_id = enrollment.role_id
            udfds.push $.ajaxJSON url, 'POST', data, (newEnrollment) =>
              newEnrollment.observed_user = user
              newEnrollments.push newEnrollment
          $.when(udfds...).done ->
            dfdsDone += 1
            if dfdsDone == newLinks.length
              newDfd.resolve()

      # delete old links
      enrollmentsToRemove = _.filter enrollments, (en) -> _.include removeLinks, en.associated_user_id
      for en in enrollmentsToRemove
        url = "#{ENV.COURSE_ROOT_URL}/unenroll/#{en.id}"
        dfds.push $.ajaxJSON url, 'DELETE'

      @disable($.when(dfds...)
        .done =>
          @updateEnrollments newEnrollments, enrollmentsToRemove
          $.flashMessage I18n.t('flash.links', 'Student links successfully updated')
        .fail ->
          $.flashError I18n.t('flash.linkError', "Something went wrong updating the user's student links. Please try again later.")
        .always => @close())
