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

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import setDefaultGradeDialogTemplate from '../jst/SetDefaultGradeDialog.handlebars'
import {isString, values, filter, chain, includes} from 'lodash'
import '@canvas/jquery/jquery.disableWhileLoading'
import '@canvas/jquery/jquery.instructure_forms'
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import 'jquery-tinypubsub'
import '@canvas/util/jquery/fixDialogButtons'
import React from 'react'
import {createRoot} from 'react-dom/client'
import {windowAlert} from '@canvas/util/globalUtils'

// # this is a partial needed by the 'SetDefaultGradeDialog' template
// # since you cant declare a dependency in a handlebars file, we need to do it here
import '../jst/_grading_box.handlebars'
import CheckpointsGradeInputs from '@canvas/grading/react/CheckpointsGradeInputs'
import {CheckpointsDefaultGradeInfo} from '@canvas/grading/react/CheckpointsDefaultGradeInfo'

const I18n = createI18nScope('sharedSetDefaultGradeDialog')

const REPLY_TO_TOPIC = 'reply_to_topic'
const REPLY_TO_ENTRY = 'reply_to_entry'
const DEFAULT_GRADE_WITH_CHECKPOINTS_MOUNT_POINT = 'default_grade_with_checkpoints_mount_point'
const DEFAULT_GRADE_WITH_CHECKPOINTS_INFO_MOUNT_POINT =
  'default_grade_with_checkpoints_info_mount_point'

const noop = function () {}
const slice = [].slice

function SetDefaultGradeDialog(arg) {
  let ref, ref1, ref2
  this.assignment = arg.assignment
  this.students = arg.students
  this.context_id = arg.context_id
  this.missing_shortcut_enabled = arg.missing_shortcut_enabled
  this.selected_section = arg.selected_section
  this.onClose = (ref = arg.onClose) != null ? ref : noop
  this.page_size = (ref1 = arg.page_size) != null ? ref1 : 50
  this.alert = (ref2 = arg.alert) != null ? ref2 : windowAlert
  this.show = this.show.bind(this)
}

SetDefaultGradeDialog.prototype.show = function (onClose) {
  let getParams, getStudents, getSubmissions
  if (onClose == null) {
    onClose = this.onClose
  }

  const hasCheckpoints = this.assignment.has_sub_assignments
  const templateLocals = {
    assignment: this.assignment,
    hasCheckpoints,
    showPointsPossible:
      (this.assignment.points_possible || this.assignment.points_possible === '0') &&
      this.assignment.grading_type !== 'gpa_scale',
    url: '/courses/' + this.context_id + '/gradebook/update_submission',
    inputName: 'default_grade',
  }
  templateLocals['assignment_grading_type_is_' + this.assignment.grading_type] = true
  this.$dialog = $(setDefaultGradeDialogTemplate(templateLocals))
  this.$dialog
    .dialog({
      resizable: false,
      width: 350,
      modal: true,
      zIndex: 1000,
    })
    .fixDialogButtons()
  this.$dialog.on(
    'dialogclose',
    (function (_this) {
      return function () {
        onClose()
        return _this.$dialog.remove()
      }
    })(this),
  )
  const $form = this.$dialog
  $('.ui-dialog-titlebar-close').focus()
  $form.submit(
    (function (_this) {
      return async function (e) {
        let pages, postDfds, students, submittingDfd
        e.preventDefault()
        const formData = $form.getFormData()
        const defaultGrade = formData.default_grade
        if (_this.gradeIsExcused(defaultGrade)) {
          return $.flashError(
            I18n.t('Default grade cannot be set to %{ex}', {
              ex: 'EX',
            }),
          )
        } else {
          submittingDfd = $.Deferred()
          $form.disableWhileLoading(submittingDfd)
          students = getStudents()
          pages = function () {
            const results = []
            while (students.length) {
              results.push(students.splice(0, this.page_size))
            }
            return results
          }.call(_this)

          const makeRequests = (grade, subAssignmentTag = null) => {
            return pages.map(function (page) {
              let finalGrade = grade

              if (isString(grade)) {
                finalGrade = grade.toLowerCase()
              }

              const studentParams = getParams(page, finalGrade)
              const params = {
                ...studentParams,
                dont_overwrite_grades: !formData.overwrite_existing_grades,
                ...(subAssignmentTag ? {sub_assignment_tag: subAssignmentTag} : {}),
              }
              return $.ajaxJSON($form.attr('action'), 'POST', params)
            })
          }

          if (hasCheckpoints) {
            const replyToTopicGrade = formData.reply_to_topic_input
            const replyToEntryGrade = formData.reply_to_entry_input

            await makeRequests(replyToTopicGrade, REPLY_TO_TOPIC)[0].promise()
            // We only get the results of the last set of requests, that should have the submissions with both updates.
            postDfds = makeRequests(replyToEntryGrade, REPLY_TO_ENTRY)
          } else {
            postDfds = makeRequests(defaultGrade)
          }

          return $.when.apply($, postDfds).then(function () {
            let responses = arguments.length >= 1 ? slice.call(arguments, 0) : []
            if (postDfds.length === 1) {
              responses = [responses]
            }
            const submissions = getSubmissions(responses)
            $.publish('submissions_updated', [submissions])
            if (_this.gradeIsMissingShortcut(defaultGrade)) {
              _this.alert(
                I18n.t(
                  {
                    one: '1 student marked as missing',
                    other: '%{count} students marked as missing',
                  },
                  {
                    count: submissions.length,
                  },
                ),
              )
            } else {
              _this.alert(
                I18n.t(
                  {
                    one: '1 student score updated',
                    other: '%{count} student scores updated',
                  },
                  {
                    count: submissions.length,
                  },
                ),
              )
            }
            submittingDfd.resolve()
            return _this.$dialog.dialog('close')
          })
        }
      }
    })(this),
  )
  getStudents = (function (_this) {
    return function () {
      if (_this.selected_section) {
        return filter(_this.students, function (s) {
          return includes(s.sections, _this.selected_section)
        })
      } else {
        return values(_this.students)
      }
    }
  })(this)
  getParams = (function (_this) {
    return function (page, grade) {
      return chain(page)
        .map(function (s) {
          const prefix = 'submissions[submission_' + s.id + ']'
          const params = [
            [prefix + '[assignment_id]', _this.assignment.id],
            [prefix + '[user_id]', s.id],
            [prefix + '[set_by_default_grade]', true],
          ]
          if (_this.gradeIsMissingShortcut(grade)) {
            params.push([prefix + '[late_policy_status]', 'missing'])
          } else {
            params.push([prefix + '[grade]', grade])
          }
          return params
        })
        .flatten()
        .fromPairs()
        .value()
    }
  })(this)

  const mountPoint = document.getElementById(DEFAULT_GRADE_WITH_CHECKPOINTS_MOUNT_POINT)

  if (mountPoint) {
    const root = createRoot(mountPoint)
    root.render(<CheckpointsGradeInputs assignment={this.assignment} canEdit={true} />)
  }

  const overwriteExitingGrades = document.getElementsByName('overwrite_existing_grades')[0]
  const infoMountPoint = document.getElementById(DEFAULT_GRADE_WITH_CHECKPOINTS_INFO_MOUNT_POINT)
  const infoRoot = infoMountPoint ? createRoot(infoMountPoint) : null

  overwriteExitingGrades.addEventListener(
    'change',
    () => {
      if (!infoRoot) {
        return
      }

      infoRoot.render(overwriteExitingGrades.checked ? <CheckpointsDefaultGradeInfo /> : <span />)
    },
    false,
  )

  // # uniq on id is required because for group assignments the api will
  // # return all submission in a group assignment leading to duplicates
  return (getSubmissions = (function (_this) {
    return function (responses) {
      return chain(responses)
        .map(function (arg) {
          let s
          const response = arg[0]
          return [
            (function () {
              let i, len
              const results = []
              for (i = 0, len = response.length; i < len; i++) {
                s = response[i]
                results.push(s.submission)
              }
              return results
            })(),
          ]
        })
        .flattenDeep()
        .uniqBy('id')
        .value()
    }
  })(this))
}

SetDefaultGradeDialog.prototype.gradeIsExcused = function (grade) {
  return isString(grade) && grade.toUpperCase() === 'EX'
}

SetDefaultGradeDialog.prototype.gradeIsMissingShortcut = function (grade) {
  return this.missing_shortcut_enabled && (grade != null ? grade.toUpperCase() : void 0) === 'MI'
}

export default SetDefaultGradeDialog
