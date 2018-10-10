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
  'jst/courses/roster/EditSectionsView'
  'jst/courses/roster/section'
  '../../../widget/ContextSearch'
  'str/htmlEscape'
  '../../../jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], (I18n, $, _, DialogBaseView, RosterDialogMixin, editSectionsViewTemplate, sectionTemplate, ContextSearch, h) ->

  class EditSectionsView extends DialogBaseView

    @mixin RosterDialogMixin

    events:
      'click #user_sections li a': 'removeSection'

    dialogOptions:
      id: 'edit_sections'
      title: I18n.t 'titles.section_enrollments', 'Section Enrollments'

    render: ->
      @$el.html editSectionsViewTemplate
        sectionsUrl: ENV.SEARCH_URL
      @setupContextSearch()
      this

    setupContextSearch: ->
      @$('#section_input').contextSearch
        contexts: ENV.CONTEXTS
        placeholder: I18n.t 'edit_sections_placeholder', 'Enter a section name'
        title: I18n.t 'edit_sections_title', 'Section name'
        onNewToken: @onNewToken
        added: (data, $token, newToken) =>
          @$('#user_sections').append $token
        selector:
          baseData:
            type: 'section'
            context: "course_#{ENV.course.id}_sections"
            exclude: _.map(@model.sectionEditableEnrollments(), (e) -> "section_#{e.course_section_id}").concat(ENV.CONCLUDED_SECTIONS)
          noExpand: true
          browser:
            data:
              per_page: 100
              types: ['section']
              search_all_contexts: true
      @input = @$('#section_input').data('token_input')
      @input.$fakeInput.css('width', '100%')
      @input.tokenValues = =>
        input.value for input in @$('#user_sections input')

      $sections = @$('#user_sections')
      for e in @model.sectionEditableEnrollments()
        if section = ENV.CONTEXTS['sections'][e.course_section_id]
          $sections.append sectionTemplate(id: section.id, name: section.name, role: e.role, can_be_removed: e.can_be_removed)

    onNewToken: ($token) =>
      $link = $token.find('a')
      $link.attr('href', '#')
      $link.attr('title', I18n.t("remove_user_from_course_section", "Remove user from %{course_section}", course_section: $token.find('div').attr('title')))
      $screenreader_span = $('<span class="screenreader-only"></span>').append(h(I18n.t("remove_user_from_course_section",
        "Remove user from %{course_section}", course_section: h($token.find('div').attr('title')))))
      $link.append($screenreader_span)

    update: (e) =>
      e.preventDefault()

      enrollment = @model.findEnrollmentByRole(@model.currentRole)
      currentIds = _.map @model.sectionEditableEnrollments(), (en) -> en.course_section_id
      sectionIds = _.map $('#user_sections').find('input'), (i) -> $(i).val().split('_')[1]
      newSections = _.reject sectionIds, (i) => _.include currentIds, i
      newEnrollments = []
      deferreds = []
      # create new enrollments
      for id in newSections
        url = "/api/v1/sections/#{id}/enrollments"
        data =
          enrollment:
            user_id: @model.get('id')
            type: enrollment.type
            limit_privileges_to_course_section: enrollment.limit_privileges_to_course_section
        unless @model.pending(@model.currentRole)
          data.enrollment.enrollment_state = 'active'
        if enrollment.role != enrollment.type
          data.enrollment.role_id = enrollment.role_id
        deferreds.push $.ajaxJSON url, 'POST', data, (newEnrollment) =>
          _.extend newEnrollment, { can_be_removed: true }
          newEnrollments.push newEnrollment

      # delete old section enrollments
      sectionsToRemove = _.difference currentIds, sectionIds
      enrollmentsToRemove = _.filter @model.sectionEditableEnrollments(), (en) -> _.include sectionsToRemove, en.course_section_id
      for en in enrollmentsToRemove
        url = "#{ENV.COURSE_ROOT_URL}/unenroll/#{en.id}"
        deferreds.push $.ajaxJSON url, 'DELETE'

      @disable($.when(deferreds...)
        .done =>
          @updateEnrollments newEnrollments, enrollmentsToRemove
          $.flashMessage I18n.t('flash.sections', 'Section enrollments successfully updated')
        .fail ->
          $.flashError I18n.t('flash.sectionError', "Something went wrong updating the user's sections. Please try again later.")
        .always => @close())

    removeSection: (e) ->
      e.preventDefault()
      $token = $(e.currentTarget).closest('li')
      if $token.closest('ul').children().length > 1
        $token.remove()
      @input.$input.focus()
