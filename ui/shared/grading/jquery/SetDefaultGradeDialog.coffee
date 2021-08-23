#
# Copyright (C) 2011 - present Instructure, Inc.
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

import I18n from 'i18n!sharedSetDefaultGradeDialog'
import $ from 'jquery'
import setDefaultGradeDialogTemplate from '../jst/SetDefaultGradeDialog.handlebars'
import _ from 'underscore'
import '@canvas/jquery/jquery.disableWhileLoading'
import '@canvas/forms/jquery/jquery.instructure_forms'
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import 'jquery-tinypubsub'
import '@canvas/util/jquery/fixDialogButtons'

# this is a partial needed by the 'SetDefaultGradeDialog' template
# since you cant declare a dependency in a handlebars file, we need to do it here
import '../jst/_grading_box.handlebars'

noop = ->
alertProxy = (message) -> alert(message)

export default class SetDefaultGradeDialog
  constructor: ({@assignment, @students, @context_id, @selected_section, @onClose = noop, @page_size = 50, @alert = alertProxy}) ->

  show: (onClose = @onClose) =>
    templateLocals =
      assignment: @assignment
      showPointsPossible: (@assignment.points_possible || @assignment.points_possible == '0') && @assignment.grading_type != "gpa_scale"
      url: "/courses/#{@context_id}/gradebook/update_submission"
      inputName: 'default_grade'
    templateLocals["assignment_grading_type_is_#{@assignment.grading_type}"] = true
    @$dialog = $(setDefaultGradeDialogTemplate(templateLocals))
    @$dialog.dialog(
      resizable: false
      width: 350
    ).fixDialogButtons()
    @$dialog.on 'dialogclose', =>
      onClose()
      @$dialog.remove()

    $form = @$dialog
    $(".ui-dialog-titlebar-close").focus()
    $form.submit (e) =>
      e.preventDefault()
      formData = $form.getFormData()
      if @gradeIsExcused(formData.default_grade)
        $.flashError I18n.t('Default grade cannot be set to %{ex}', { ex: 'EX' })
      else
        submittingDfd = $.Deferred()
        $form.disableWhileLoading(submittingDfd)

        students = getStudents()
        pages = (students.splice 0, @page_size while students.length)

        postDfds = pages.map (page) =>
          studentParams = getParams(page, formData.default_grade)
          params = _.extend {}, studentParams,
            dont_overwrite_grades: not formData.overwrite_existing_grades
          $.ajaxJSON $form.attr("action"), "POST", params

        $.when(postDfds...).then (responses...) =>
          responses = [responses] if postDfds.length == 1
          submissions = getSubmissions(responses)
          $.publish 'submissions_updated', [submissions]
          @alert(I18n.t 'alerts.scores_updated'
          ,
            one: '1 Student score updated'
            other: '%{count} Student scores updated'
          ,
            count: submissions.length)
          submittingDfd.resolve()
          @$dialog.dialog('close')

    getStudents = =>
      if @selected_section
        _(@students).filter (s) =>
          _.includes(s.sections, @selected_section)
      else
        _(@students).values()

    getParams = (page, grade) =>
      _.chain(page)
        .map (s) =>
          prefix = "submissions[submission_#{s.id}]"
          [["#{prefix}[assignment_id]", @assignment.id],
          ["#{prefix}[user_id]", s.id],
          ["#{prefix}[grade]", grade]]
        .flatten(true)
        .object()
        .value()

    getSubmissions = (responses) =>
      # uniq on id is required because for group assignments the api will
      # return all submission in a group assignment leading to duplicates
      _.chain(responses)
        .map ([response, __]) ->
          [s.submission for s in response]
        .flatten()
        .uniq('id')
        .value()

  gradeIsExcused: (grade) ->
    _.isString(grade) && grade.toUpperCase() == 'EX'
