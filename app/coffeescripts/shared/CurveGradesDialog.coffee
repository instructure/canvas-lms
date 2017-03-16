#
# Copyright (C) 2011 - 2017 Instructure, Inc.
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
  'i18n!gradebook'
  'jsx/shared/helpers/numberHelper'
  'jquery'
  'jst/CurveGradesDialog'
  'str/htmlEscape'
  'jquery.disableWhileLoading'
  'jquery.instructure_forms'
  'jqueryui/dialog'
  'jquery.instructure_misc_plugins'
  'compiled/jquery/fixDialogButtons'
  'vendor/jquery.ba-tinypubsub'
], (I18n, numberHelper, $, curveGradesDialogTemplate, htmlEscape) ->
  class CurveGradesDialog
    constructor: ({@assignment, @students, @context_url}) ->

    show: =>
      locals =
        assignment: @assignment
        action: "#{@context_url}/gradebook/update_submission"
        middleScore: I18n.n((@assignment.points_possible || 0) * 0.6)
        showOutOf: @assignment.points_possible >= 0
        formattedOutOf: I18n.n @assignment.points_possible
      # the dialog will be shared across all instantiation, so make it a prototype property
      @$dialog = $(curveGradesDialogTemplate(locals))
      @$dialog
        .formSubmit
          disableWhileLoading: true
          processData: (data) =>
            if !@assignment.points_possible || @assignment.points_possible == "0"
              errorBox = @$dialog.errorBox I18n.t("errors.no_points_possible", "Cannot curve without points possible")
              setTimeout((-> errorBox.fadeOut(-> errorBox.remove())), 3500)
              return false
            cnt = 0
            curves = @curve()
            for idx of curves
              pre = "submissions[submission_" + idx + "]"
              data[pre + "[assignment_id]"] = data.assignment_id
              data[pre + "[user_id]"] = idx
              if @assignment.grading_type == "gpa_scale"
                percent = (curves[idx]/@assignment.points_possible)*100
                data[pre + "[grade]"] = "#{I18n.n percent, percentage: true}"
              else
                data[pre + "[grade]"] = curves[idx]
              cnt++
            if cnt == 0
              errorBox = @$dialog.errorBox I18n.t("errors.none_to_update", "None to Update")
              setTimeout((-> errorBox.fadeOut(-> errorBox.remove())), 3500)
              return false
            data
          success: (data) =>
            @$dialog.dialog('close')
            #need to get rid of root object becuase it is coming from old, pre-api xhr
            submissions = (datum.submission for datum in data)
            $.publish 'submissions_updated', [submissions]
            alert I18n.t(
              {
                one: "1 Student score updated",
                other: "%{studentCount} Student scores updated"
              },
              {
                count: data.length,
                studentCount: I18n.n(data.length)
              }
            )
            $("#set_default_grade").focus()
        .dialog
          width: 350
          modal: true
          resizable: false
          open: @curve
          close: => @$dialog.remove()
        .fixDialogButtons()

      @$dialog.parent().find('.ui-dialog-titlebar-close').focus()
      @$dialog.find("#middle_score").bind "blur change keyup focus", @curve
      @$dialog.find("#assign_blanks").change @curve

    curve: =>
      idx                  = 0
      scores               = {}
      users_for_score      = []
      scoreCount           = 0
      middleScore          = numberHelper.parse($("#middle_score").val())
      middleScore          = (middleScore / @assignment.points_possible)
      should_assign_blanks = $('#assign_blanks').prop('checked')

      return  if isNaN(middleScore)

      for idx, student of @students
        sub = student["assignment_#{@assignment.id}"]
        score = sub?.score
        score = @assignment.points_possible if score > @assignment.points_possible
        score = 0 if score < 0 or !score? and should_assign_blanks
        users_for_score[parseInt(score, 10)] = users_for_score[parseInt(score, 10)] or []
        users_for_score[parseInt(score, 10)].push [ idx, (score or 0) ]
        scoreCount++

      breaks = [ 0.006, 0.012, 0.028, 0.040, 0.068, 0.106, 0.159, 0.227, 0.309, 0.401, 0.500, 0.599, 0.691, 0.773, 0.841, 0.894, 0.933, 0.960, 0.977, 0.988, 1.000 ]
      interval = (1.0 - middleScore) / Math.floor(breaks.length / 2)
      breakScores = []
      breakPercents = []
      idx = 0

      while idx < breaks.length
        breakPercents.push 1.0 - (interval * idx)
        breakScores.push Math.round((1.0 - (interval * idx)) * @assignment.points_possible)
        idx++
      tally = 0
      finalScores = {}
      currentBreak = 0
      $("#results_list").empty()
      $("#results_values").empty()
      final_users_for_score = []
      idx = users_for_score.length - 1

      while idx >= 0
        users = users_for_score[idx] or []
        score = Math.round(breakScores[currentBreak])
        for user in users
          finalScores[user[0]] = score
          finalScores[user[0]] = 0  if user[1] == 0
          finalScore = finalScores[user[0]]
          final_users_for_score[finalScore] = final_users_for_score[finalScore] or []
          final_users_for_score[finalScore].push user[0]
        tally += users.length
        while tally > (breaks[currentBreak] * scoreCount)
          currentBreak++
        idx--
      maxCount = 0
      idx = final_users_for_score.length - 1

      while idx >= 0
        cnt = (final_users_for_score[idx] or []).length
        maxCount = cnt  if cnt > maxCount
        idx--
      width = 15
      skipCount = 0
      idx = final_users_for_score.length - 1

      while idx >= 0
        users = final_users_for_score[idx]
        pct = 0
        cnt = 0
        if users or skipCount > (@assignment.points_possible / 10)
          if users
            pct = (users.length / maxCount)
            cnt = users.length
          color = (if idx == 0 then "#a03536" else "#007ab8")

          title = I18n.t(
            {
              one: "1 student will get %{num} points",
              other: "%{studentCount} students will get %{num} points"
            },
            {
              count: cnt,
              num: I18n.n(idx),
              studentCount: I18n.n(cnt)
            }
          )
          $("#results_list").prepend(
            "<td style='padding: 1px;'><div title='" + htmlEscape(title) +
            "' style='border: 1px solid #888; background-color: " + htmlEscape(color) +
            "; width: " + htmlEscape(width) + "px; height: " + htmlEscape(100 * pct) +
            "px; margin-top: " + htmlEscape(100 * (1 - pct)) + "px;'>&nbsp;</div></td>"
          )
          $("#results_values").prepend(
            "<td style='text-align: center;'>" + htmlEscape(I18n.n idx) + "</td>"
          )
          skipCount = 0
        else
          skipCount++
        idx--
      $("#results_list").prepend(
        "<td><div style='height: 100px; position: relative; width: 30px; font-size: 0.8em;'>" +
        "<img src='/images/number_of_students.png' alt='" + htmlEscape(I18n.t "# of students") +
        "'/><div style='position: absolute; top: 0; right: 3px;'>" + htmlEscape(I18n.n maxCount) +
        "</div><div style='position: absolute; bottom: 0; right: 3px;'>" + htmlEscape(I18n.n 0) +
        "</div></div></td>"
      )
      $("#results_values").prepend "<td>&nbsp;</td>"
      finalScores
