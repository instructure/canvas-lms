/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import messageStudents from '@canvas/message-students-dialog/jquery/message_students'
import AssignmentDetailsDialog from './AssignmentDetailsDialog'
import AssignmentMuter from './AssignmentMuter'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import SetDefaultGradeDialog from '@canvas/grading/jquery/SetDefaultGradeDialog'
import CurveGradesDialog from '@canvas/grading/jquery/CurveGradesDialog'
import gradebookHeaderMenuTemplate from '../jst/GradebookHeaderMenu.handlebars'
import re_upload_submissions_form from '@canvas/grading/jst/re_upload_submissions_form.handlebars'
import {map, filter} from 'lodash'
import authenticity_token from '@canvas/authenticity-token'
import MessageStudentsWhoHelper from '@canvas/grading/messageStudentsWhoHelper'
import React from 'react'
import ReactDOM from 'react-dom'
import MessageStudentsWithObserversDialog from '@canvas/message-students-dialog/react/MessageStudentsWhoDialog'
import {ApolloProvider} from 'react-apollo'
import {createClient} from '@canvas/apollo'
import '@canvas/jquery/jquery.instructure_forms'
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import 'jquery-kyle-menu'
import replaceTags from '@canvas/util/replaceTags'

const I18n = useI18nScope('gradebookHeaderMenu')

const isAdmin = function () {
  return ENV.current_user_is_admin
}

export default class GradebookHeaderMenu {
  constructor(assignment1, $trigger, gradebook) {
    this.showAssignmentDetails = this.showAssignmentDetails.bind(this)
    this.messageStudentsWho = this.messageStudentsWho.bind(this)
    this.setDefaultGrade = this.setDefaultGrade.bind(this)
    this.curveGrades = this.curveGrades.bind(this)
    this.downloadSubmissions = this.downloadSubmissions.bind(this)
    this.reuploadSubmissions = this.reuploadSubmissions.bind(this)
    this.canUnmute = this.canUnmute.bind(this)
    this.assignment = assignment1
    this.$trigger = $trigger
    this.gradebook = gradebook
    const templateLocals = {
      assignmentUrl: `${this.gradebook.options.context_url}/assignments/${this.assignment.id}`,
      speedGraderUrl: `${this.gradebook.options.context_url}/gradebook/speed_grader?assignment_id=${this.assignment.id}`,
    }
    if (!this.gradebook.options.speed_grader_enabled) {
      templateLocals.speedGraderUrl = null
    }
    this.gradebook.allSubmissionsLoaded.done(() => {
      // Reset the cache in case the user clicked on the menu while waiting for data
      return (this.allSubmissionsLoaded = true)
    })
    this.$menu = $(gradebookHeaderMenuTemplate(templateLocals)).insertAfter(this.$trigger)
    this.$trigger.kyleMenu({
      noButton: true,
    })
    // need it to be a child of #gradebook_grid (not the header cell) to get over overflow:hidden obstacles.
    this.$menu
      .appendTo('#gradebook_grid')
      .on('click', 'a', event => {
        const action = this[$(event.target).data('action')]
        if (action) {
          action()
          return false
        }
      })
      .bind('popupopen popupclose', event => {
        this.$trigger.toggleClass('ui-menu-trigger-menu-is-open', event.type === 'popupopen')
        if (
          event.type === 'popupclose' &&
          event.originalEvent != null &&
          event.originalEvent.type !== 'focusout'
        ) {
          // defer because there seems to make sure this occurs after all of the jquery ui events
          return setTimeout(() => {
            return this.gradebook.grid.editActiveCell()
          }, 0)
        }
      })
      .bind('popupopen', () => {
        return this.menuPopupOpenHandler(this.$menu)
      })
      .popup('open')
    new AssignmentMuter(
      this.$menu.find('[data-action=toggleMuting]'),
      this.assignment,
      `${this.gradebook.options.context_url}/assignments/${this.assignment.id}/mute`,
      (a, _z, status) => {
        a.muted = status
        return this.gradebook.setAssignmentWarnings()
      },
      {
        canUnmute: this.canUnmute(),
      }
    ).show()
  }

  menuPopupOpenHandler(menu) {
    // Hide any menu options that haven't had their dependencies met yet
    this.hideMenuActionsWithUnmetDependencies(menu)
    // Disable menu options if needed
    return this.disableUnavailableMenuActions(menu)
  }

  hideMenuActionsWithUnmetDependencies(menu) {
    let action, condition
    const ref = {
      showAssignmentDetails: this.allSubmissionsLoaded,
      messageStudentsWho: this.allSubmissionsLoaded,
      setDefaultGrade: this.allSubmissionsLoaded,
      curveGrades:
        this.allSubmissionsLoaded &&
        this.assignment.grading_type !== 'pass_fail' &&
        this.assignment.points_possible,
      downloadSubmissions:
        `${this.assignment.submission_types}`.match(
          /(online_upload|online_text_entry|online_url)/
        ) && this.assignment.has_submitted_submissions,
      reuploadSubmissions:
        this.gradebook.options.gradebook_is_editable && this.assignment.submissions_downloads > 0,
    }
    const results = []
    for (action in ref) {
      condition = ref[action]
      results.push(menu.find(`[data-action=${action}]`).showIf(condition))
    }
    return results
  }

  disableUnavailableMenuActions(menu) {
    let actionToDisable, actionsToDisable, i, len, menuItem, ref
    if (menu == null) {
      return
    }
    actionsToDisable = []
    if (((ref = this.assignment) != null ? ref.inClosedGradingPeriod : undefined) && !isAdmin()) {
      actionsToDisable = ['curveGrades', 'setDefaultGrade']
    }
    if (!this.canUnmute()) {
      actionsToDisable.push('toggleMuting')
    }
    const results = []
    for (i = 0, len = actionsToDisable.length; i < len; i++) {
      actionToDisable = actionsToDisable[i]
      menuItem = menu.find(`[data-action=${actionToDisable}]`)
      menuItem.addClass('ui-state-disabled')
      results.push(menuItem.attr('aria-disabled', true))
    }
    return results
  }

  showAssignmentDetails(
    opts = {
      assignment: this.assignment,
      students: this.gradebook.studentsThatCanSeeAssignment(
        this.gradebook.students,
        this.assignment
      ),
    }
  ) {
    const dialog = new AssignmentDetailsDialog(opts)
    return dialog.show()
  }

  messageStudentsWho(
    opts = {
      assignment: this.assignment,
      students: this.gradebook.studentsThatCanSeeAssignment(
        this.gradebook.students,
        this.assignment
      ),
      messageAttachmentUploadFolderId: this.gradebook.options.message_attachment_upload_folder_id,
    }
  ) {
    let {students} = opts
    const {assignment, messageAttachmentUploadFolderId} = opts
    students = filter(students, student => {
      return !student.isInactive && !student.isTestStudent
    })
    students = map(students, student => {
      const sub = student[`assignment_${assignment.id}`]
      return {
        excused: sub.excused,
        grade: sub.grade,
        id: student.id,
        latePolicyStatus: sub.late_policy_status,
        name: student.name,
        redoRequest: sub.redo_request,
        score: sub != null ? sub.score : undefined,
        // Both gradebooks share the Message Students dialog; prefer New Gradebook's casing
        sortableName: student.sortable_name,
        submittedAt: sub != null ? sub.submitted_at : undefined,
      }
    })

    if (opts.show_message_students_with_observers_dialog) {
      const mountPoint = document.querySelector(
        "[data-component='MessageStudentsWithObserversModal']"
      )
      const props = {
        assignment: {
          allowedAttempts: assignment.allowed_attempts,
          anonymizeStudents: assignment.anonymize_students,
          courseId: assignment.course_id,
          dueDate: assignment.due_at,
          htmlUrl: assignment.html_url,
          muted: assignment.muted,
          pointsPossible: assignment.points_possible,
          postManually: assignment.post_manually,
          published: assignment.published,
          gradingType: assignment.grading_type,
          id: assignment.id,
          name: assignment.name,
          submissionTypes: assignment.submission_types,
        },
        onClose: () => {
          ReactDOM.unmountComponentAtNode(mountPoint)
        },
        onSend: args => {
          return MessageStudentsWhoHelper.sendMessageStudentsWho(
            args.recipientsIds,
            args.subject,
            args.body,
            `course_${assignment.course_id}`,
            args.mediaFile,
            args.attachmentIds
          )
            .then(FlashAlert.showFlashSuccess(I18n.t('Message sent successfully')))
            .catch(FlashAlert.showFlashError(I18n.t('There was an error sending the message')))
        },
        messageAttachmentUploadFolderId,
        students,
        userId: opts.current_user_id,
      }
      ReactDOM.render(
        <ApolloProvider client={createClient()}>
          <MessageStudentsWithObserversDialog {...props} />
        </ApolloProvider>,
        mountPoint
      )
    } else {
      const settings = MessageStudentsWhoHelper.settings(assignment, students)
      return messageStudents(settings)
    }
  }

  setDefaultGrade(
    opts = {
      assignment: this.assignment,
      students: this.gradebook.studentsThatCanSeeAssignment(
        this.gradebook.students,
        this.assignment
      ),
      context_id: this.gradebook.options.context_id,
      selected_section: this.gradebook.sectionToShow,
    }
  ) {
    if (isAdmin() || !opts.assignment.inClosedGradingPeriod) {
      return new SetDefaultGradeDialog(opts).show()
    } else {
      return $.flashError(
        I18n.t(
          'Unable to set default grade because this ' +
            'assignment is due in a closed grading period for at least one student'
        )
      )
    }
  }

  curveGrades(
    opts = {
      assignment: this.assignment,
      students: this.gradebook.studentsThatCanSeeAssignment(
        this.gradebook.students,
        this.assignment
      ),
      context_url: this.gradebook.options.context_url,
    }
  ) {
    let dialog
    if (isAdmin() || !opts.assignment.inClosedGradingPeriod) {
      dialog = new CurveGradesDialog(opts)
      return dialog.show()
    } else {
      return $.flashError(
        I18n.t(
          'Unable to curve grades because this ' +
            'assignment is due in a closed grading period for at least ' +
            'one student'
        )
      )
    }
  }

  downloadSubmissions() {
    let base
    const url = replaceTags(
      this.gradebook.options.download_assignment_submissions_url,
      'assignment_id',
      this.assignment.id
    )
    INST.downloadSubmissions(url)
    return (this.assignment.submissions_downloads =
      ((base = this.assignment).submissions_downloads != null
        ? base.submissions_downloads
        : (base.submissions_downloads = 0)) + 1)
  }

  reuploadSubmissions() {
    let locals
    if (!this.$re_upload_submissions_form) {
      locals = {
        authenticityToken: authenticity_token(),
      }
      GradebookHeaderMenu.prototype.$re_upload_submissions_form = $(
        re_upload_submissions_form(locals)
      )
        .dialog({
          width: 400,
          modal: true,
          resizable: false,
          autoOpen: false,
          zIndex: 1000,
        })
        .submit(function () {
          const data = $(this).getFormData()
          if (!data.submissions_zip) {
            return false
          } else if (!data.submissions_zip.match(/\.zip$/)) {
            $(this).formErrors({
              submissions_zip: I18n.t('errors.upload_as_zip', 'Please upload files as a .zip'),
            })
            return false
          }
        })
    }
    const url = replaceTags(
      this.gradebook.options.re_upload_submissions_url,
      'assignment_id',
      this.assignment.id
    )
    return this.$re_upload_submissions_form.attr('action', url).dialog('open')
  }

  canUnmute() {
    return !(
      this.assignment?.muted &&
      this.assignment?.moderated_grading &&
      !this.assignment?.grades_published
    )
  }
}
