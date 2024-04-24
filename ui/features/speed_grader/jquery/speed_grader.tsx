/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import type JQuery from 'jquery'
import $ from 'jquery'
import type {
  Attachment,
  AttachmentData,
  CourseSection,
  DocumentPreviewOptions,
  Grade,
  GradingError,
  GradingPeriod,
  CommentRenderingOptions,
  ProvisionalCrocodocUrl,
  ProvisionalGrade,
  RubricAssessment,
  ScoringSnapshot,
  SpeedGrader,
  HistoricalSubmission,
  SpeedGraderResponse,
  SpeedGraderStore,
  Submission,
  StudentWithSubmission,
  SubmissionComment,
  SubmissionHistoryEntry,
} from './speed_grader.d'
import type {SubmissionOriginalityData} from '@canvas/grading/grading.d'
import React from 'react'
import ReactDOM from 'react-dom'
import {IconButton} from '@instructure/ui-buttons'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import OutlierScoreHelper from '@canvas/grading/OutlierScoreHelper'
import QuizzesNextSpeedGrading from '../QuizzesNextSpeedGrading'
import StatusPill from '@canvas/grading-status-pill'
import JQuerySelectorCache from '../JQuerySelectorCache'
import numberHelper from '@canvas/i18n/numberHelper'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import AssessmentAuditButton from '../react/AssessmentAuditTray/components/AssessmentAuditButton'
import AssessmentAuditTray from '../react/AssessmentAuditTray/index'
import CommentArea from '../react/CommentArea'
import GradeLoadingSpinner from '../react/GradeLoadingSpinner'
import RubricAssessmentTrayWrapper from '../react/RubricAssessmentTrayWrapper'
import ScreenCaptureIcon from '../react/ScreenCaptureIcon'
import {originalityReportSubmissionKey} from '@canvas/grading/originalityReportHelper'
import PostPolicies from '../react/PostPolicies/index'
import SpeedGraderProvisionalGradeSelector from '../react/SpeedGraderProvisionalGradeSelector'
import SpeedGraderStatusMenu from '../react/SpeedGraderStatusMenu'
import {isPostable, similarityIcon} from '@canvas/grading/SubmissionHelper'
// @ts-expect-error
import studentViewedAtTemplate from '../jst/student_viewed_at.handlebars'
// @ts-expect-error
import submissionsDropdownTemplate from '../jst/submissions_dropdown.handlebars'
// @ts-expect-error
import speechRecognitionTemplate from '../jst/speech_recognition.handlebars'
// @ts-expect-error
import unsubmittedCommentsTemplate from '../jst/unsubmitted_comment.handlebars'
import useStore from '../stores/index'
import {Tooltip} from '@instructure/ui-tooltip'
import {
  IconUploadLine,
  IconWarningLine,
  IconCheckMarkIndeterminateLine,
} from '@instructure/ui-icons'
import {Pill} from '@instructure/ui-pill'
import {
  determineSubmissionSelection,
  makeSubmissionUpdateRequest,
} from '../SpeedGraderStatusMenuHelpers'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import round from '@canvas/round'
import {map, keyBy, values, find, includes, reject, some, isEqual, filter} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import natcompare from '@canvas/util/natcompare'
import qs from 'qs'
import * as tz from '@canvas/datetime'
import userSettings from '@canvas/user-settings'
import htmlEscape from '@instructure/html-escape'
import rubricAssessment from '@canvas/rubrics/jquery/rubric_assessment'
import SpeedgraderSelectMenu from './speed_grader_select_menu'
import type {SelectOptionDefinition} from './speed_grader_select_menu'
import SpeedgraderHelpers from './speed_grader_helpers'
import {
  allowsReassignment,
  anonymousName,
  configureRecognition,
  extractStudentIdFromHash,
  getSelectedAssessment,
  hideMediaRecorderContainer,
  isStudentConcluded,
  renderDeleteAttachmentLink,
  renderPostGradesMenu,
  renderSettingsMenu,
  renderStatusMenu,
  rubricAssessmentToPopulate,
  setupAnonymizableAuthorId,
  setupAnonymizableId,
  setupAnonymizableStudentId,
  setupAnonymizableUserId,
  setupAnonymousGraders,
  setupIsAnonymous,
  setupIsModerated,
  speedGraderJSONErrorFn,
  tearDownAssessmentAuditTray,
  teardownHandleStatePopped,
  teardownSettingsMenu,
  unexcuseSubmission,
  unmountCommentTextArea,
} from './speed_grader.utils'
import SpeedGraderAlerts from '../react/SpeedGraderAlerts'
// @ts-expect-error
import turnitinInfoTemplate from '../jst/_turnitinInfo.handlebars'
// @ts-expect-error
import turnitinScoreTemplate from '@canvas/grading/jst/_turnitinScore.handlebars'
// @ts-expect-error
import vericiteInfoTemplate from '../jst/_vericiteInfo.handlebars'
// @ts-expect-error
import vericiteScoreTemplate from '@canvas/grading/jst/_vericiteScore.handlebars'
import 'jqueryui/draggable'
import '@canvas/jquery/jquery.ajaxJSON' /* getJSON, ajaxJSON */
import '@canvas/jquery/jquery.instructure_forms' /* ajaxJSONFiles */
import {loadDocPreview} from '@instructure/canvas-rce/es/enhance-user-content/doc_previews'
import '@canvas/datetime/jquery' /* datetimeString */
import 'jqueryui/dialog'
import 'jqueryui/menu'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, showIf, hasScrollbar */
import '@canvas/jquery-keycodes'
import '@canvas/loading-image'
import '@canvas/util/templateData'
import '@canvas/media-comments'
import '@canvas/media-comments/jquery/mediaCommentThumbnail'
import '@canvas/rails-flash-notifications'
import 'jquery-scroll-to-visible/jquery.scrollTo'
import 'jquery-selectmenu'
import '@canvas/jquery/jquery.disableWhileLoading'
import '@canvas/util/jquery/fixDialogButtons'
import {isPreviewable} from '@instructure/canvas-rce/es/rce/plugins/shared/Previewable'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import type {EnvGradebookSpeedGrader} from '@canvas/global/env/EnvGradebook'
import replaceTags from '@canvas/util/replaceTags'
import type {GradeStatusUnderscore} from '@canvas/grading/accountGradingStatus'
import type {RubricUnderscoreType} from '../react/RubricAssessmentTrayWrapper/utils'

declare global {
  interface Window {
    jsonData: SpeedGraderStore
  }
}

// @ts-expect-error
if (!('INST' in window)) window.INST = {}

// Allow unchecked access to module-specific ENV variables
declare const ENV: GlobalEnv & EnvGradebookSpeedGrader

const I18n = useI18nScope('speed_grader')

const selectors = new JQuerySelectorCache()
const SPEED_GRADER_COMMENT_TEXTAREA_MOUNT_POINT = 'speed_grader_comment_textarea_mount_point'
const SPEED_GRADER_SUBMISSION_COMMENTS_DOWNLOAD_MOUNT_POINT =
  'speed_grader_submission_comments_download_mount_point'
const SPEED_GRADER_HIDDEN_SUBMISSION_PILL_MOUNT_POINT =
  'speed_grader_hidden_submission_pill_mount_point'
const SPEED_GRADER_EDIT_STATUS_MENU_MOUNT_POINT = 'speed_grader_edit_status_mount_point'
const SPEED_GRADER_EDIT_STATUS_MENU_SECONDARY_MOUNT_POINT =
  'speed_grader_edit_status_secondary_mount_point'
const ASSESSMENT_AUDIT_BUTTON_MOUNT_POINT = 'speed_grader_assessment_audit_button_mount_point'
const ASSESSMENT_AUDIT_TRAY_MOUNT_POINT = 'speed_grader_assessment_audit_tray_mount_point'
const SCREEN_CAPTURE_ICON_MOUNT_POINT = 'screen-capture-icon-mount-point'

let isAnonymous: boolean
let anonymousGraders: boolean
let anonymizableId: 'anonymous_id' | 'id'
let anonymizableUserId: 'anonymous_id' | 'user_id'
let anonymizableStudentId: 'anonymous_id' | 'student_id'
let anonymizableAuthorId: 'anonymous_id' | 'author_id'
let isModerated: boolean

let commentSubmissionInProgress: boolean
let reassignAssignmentInProgress: boolean
let vericiteAsset
let turnitinAsset

// eslint-disable-next-line no-undef
let $window: JQuery<Window & typeof globalThis>
let $full_width_container: JQuery
let $vericiteScoreContainer: JQuery
let $vericiteInfoContainer: JQuery
let $turnitinInfoContainer: JQuery
let $left_side: JQuery
let $resize_overlay: JQuery
let $right_side: JQuery
let $width_resizer: JQuery
let $gradebook_header: JQuery
let $grading_box_selected_grader: JQuery
let assignmentUrl: string
let $rightside_inner: JQuery
let $not_gradeable_message: JQuery
let $comments: JQuery
let $comment_blank: JQuery
let $comment_attachment_blank: JQuery
let $add_a_comment: JQuery
let $add_a_comment_submit_button: JQuery
let $add_a_comment_textarea: JQuery
let $comment_attachment_input_blank: JQuery
let $reassign_assignment: JQuery
let fileIndex: number
let $add_attachment: JQuery
let $submissions_container: JQuery
let $iframe_holder: JQuery
let $avatar_image: JQuery
let $x_of_x_students: JQuery
let $grded_so_far: JQuery
let $average_score: JQuery
let $this_student_does_not_have_a_submission: JQuery
let $this_student_has_a_submission: JQuery
let $grade_container: JQuery
let $grade: JQuery
let $score: JQuery
let $deduction_box: JQuery
let $points_deducted: JQuery
let $final_grade: JQuery
let $average_score_wrapper: JQuery
let $submission_details: JQuery
let $multiple_submissions: JQuery
let $submission_late_notice: JQuery
let $submission_not_newest_notice: JQuery
let $enrollment_inactive_notice: JQuery
let $enrollment_concluded_notice: JQuery
let $submission_files_container: JQuery
let $submission_files_list: JQuery
let $submission_attachment_viewed_at: JQuery
let $submission_file_hidden: JQuery
let $assignment_submission_turnitin_report_url: JQuery
let $assignment_submission_originality_report_url: JQuery
let $assignment_submission_vericite_report_url: JQuery
let $assignment_submission_resubmit_to_vericite_url: JQuery
let $rubric_holder: JQuery
let $new_screen_capture_indicator_wrapper: JQuery
let $no_annotation_warning: JQuery
let $comment_submitted: JQuery
let $comment_submitted_message: JQuery
let $comment_saved: JQuery
let $comment_saved_message: JQuery
let $reassignment_complete: JQuery
let $selectmenu: SpeedgraderSelectMenu | null
let $word_count: JQuery
let originalRubric: JQuery
let browserableCssClasses: RegExp
let snapshotCache: Record<string, ScoringSnapshot | null>
let sectionToShow: string
let header: Header
let studentLabel: string
let groupLabel: string
let gradeeLabel: string
let sessionTimer: number
let isAdmin: boolean
let showSubmissionOverride: (submission: Submission) => void
let externalToolLaunchOptions = {singleLtiLaunch: false}
let externalToolLoaded = false
let provisionalGraderDisplayNames: Record<string, string | null>
let EG: SpeedGrader

const customProvisionalGraderLabel = I18n.t('Custom')
const anonymousAssignmentDetailedReportTooltip = I18n.t(
  'Cannot view detailed reports for anonymous assignments until grades are posted.'
)

const HISTORY_PUSH = 'push'
const HISTORY_REPLACE = 'replace'

const {enhanced_rubrics} = ENV.FEATURES ?? {}

function setGradeLoading(studentId: string, loading: boolean) {
  useStore.setState(state => {
    const gradesLoading = {...state.gradesLoading, [studentId]: loading}
    return {...state, gradesLoading}
  })
}

function setupHandleStatePopped() {
  window.addEventListener('popstate', EG.handleStatePopped)
}

function setupBeforeLeavingSpeedgrader() {
  window.addEventListener('beforeunload', EG.beforeLeavingSpeedgrader)
}

function teardownBeforeLeavingSpeedgrader() {
  externalToolLaunchOptions = {singleLtiLaunch: false}
  externalToolLoaded = false
  window.removeEventListener('beforeunload', EG.beforeLeavingSpeedgrader)
}

function toggleGradeVisibility(show: boolean): void {
  const gradeInput = $('#grading')
  if (show) {
    gradeInput.show().height('auto')
  } else {
    gradeInput.hide()
  }
}

const utils = {
  getParam(name: string) {
    const pathRegex = new RegExp(`${name}/([^/]+)`)
    const searchRegex = new RegExp(`${name}=([^&]+)`)
    const match =
      window.location.pathname.match(pathRegex) || window.location.search.match(searchRegex)

    if (!match) return false
    return match[1]
  },
  shouldHideStudentNames() {
    // this is for backwards compatability, we used to store the value as
    // strings "true" or "false", but now we store boolean true/false values.
    const settingVal = userSettings.get('eg_hide_student_names')
    return settingVal === true || settingVal === 'true' || ENV.force_anonymous_grading
  },
  sortByCriteria() {
    const settingVal = userSettings.get('eg_sort_by')
    return settingVal || 'alphabetically'
  },
}

function sectionSelectionOptions(
  courseSections: CourseSection[],
  groupGradingModeEnabled = false,
  selectedSectionId: null | string = null
): SelectOptionDefinition[] {
  if (courseSections.length <= 1 || groupGradingModeEnabled) {
    return []
  }

  let selectedSectionName = I18n.t('All Sections')
  const sectionOptions: SelectOptionDefinition[] = [
    {
      [anonymizableId]: 'section_all',
      data: {
        'section-id': 'all',
      },
      name: I18n.t('Show all sections'),
      className: {
        raw: 'section_all',
      },
      anonymizableId,
    },
  ]

  courseSections.forEach(section => {
    if (section.id === selectedSectionId) {
      selectedSectionName = section.name
    }

    sectionOptions.push({
      [anonymizableId]: `section_${section.id}`,
      data: {
        'section-id': section.id,
      },
      name: I18n.t('Change section to %{sectionName}', {sectionName: section.name}),
      className: {
        raw: `section_${section.id} ${selectedSectionId === section.id ? 'selected' : ''}`,
      },
      anonymizableId,
    })
  })

  return [
    {
      name: `Showing: ${selectedSectionName}`,
      options: sectionOptions,
    },
  ]
}

function mergeStudentsAndSubmission() {
  const jsonData = window.jsonData

  jsonData.studentsWithSubmissions = jsonData.context.students
  jsonData.studentMap = {}
  jsonData.studentEnrollmentMap = {}
  jsonData.studentSectionIdsMap = {}
  jsonData.submissionsMap = {}

  jsonData.context.enrollments.forEach((enrollment: Record<string, string>) => {
    const enrollmentAnonymizableUserId = enrollment[anonymizableUserId]
    jsonData.studentEnrollmentMap[enrollmentAnonymizableUserId] =
      jsonData.studentEnrollmentMap[enrollmentAnonymizableUserId] || []
    jsonData.studentSectionIdsMap[enrollmentAnonymizableUserId] =
      jsonData.studentSectionIdsMap[enrollmentAnonymizableUserId] || {}

    jsonData.studentEnrollmentMap[enrollmentAnonymizableUserId].push(enrollment)
    jsonData.studentSectionIdsMap[enrollmentAnonymizableUserId][enrollment.course_section_id] = true
  })

  jsonData.submissions.forEach((submission: any) => {
    jsonData.submissionsMap[submission[anonymizableUserId]] = submission
  })

  window.jsonData.studentsWithSubmissions = window.jsonData.studentsWithSubmissions.reduce(
    (students: StudentWithSubmission[], student: StudentWithSubmission, index: number) => {
      const submission = window.jsonData.submissionsMap[student[anonymizableId]]
      // Hide students that don't have a submission object. This is legacy support
      // for when we used to not create submission objects for assigned concluded students.
      // For all new assignments, every assigned student (regardless of concluded/inactive
      // status) should have a submission object.
      if (submission) {
        student.enrollments = window.jsonData.studentEnrollmentMap[student[anonymizableId]]
        student.section_ids = Object.keys(
          window.jsonData.studentSectionIdsMap[student[anonymizableId]]
        )
        student.submission = submission
        student.submission_state = SpeedgraderHelpers.submissionState(student, ENV.grading_role)
        student.index = index
        students.push(student)
      }

      return students
    },
    []
  )

  // need to presort by anonymous_id for anonymous assignments so that the index property can be consistent
  if (isAnonymous)
    jsonData.studentsWithSubmissions.sort((a: StudentWithSubmission, b: StudentWithSubmission) =>
      a.anonymous_name_position > b.anonymous_name_position ? 1 : -1
    )

  // handle showing students only in a certain section.
  if (!jsonData.GROUP_GRADING_MODE) {
    sectionToShow = ENV.selected_section_id
  }

  // We have already have done the filtering by section on the server, so this
  // is redundant (but not the worst thing in the world since we still need to
  // send the user away if there are no students in the section).
  if (sectionToShow) {
    sectionToShow = sectionToShow.toString()

    const studentsInSection = jsonData.studentsWithSubmissions.filter(
      (student: StudentWithSubmission) => student.section_ids.includes(sectionToShow)
    )

    if (
      studentsInSection.length > 0 &&
      !(studentsInSection.length === 1 && studentsInSection[0].fake_student)
    ) {
      jsonData.studentsWithSubmissions = studentsInSection
    } else {
      // eslint-disable-next-line no-alert
      window.alert(
        I18n.t(
          'alerts.no_students_in_section',
          'Could not find any students in that section, falling back to showing all sections.'
        )
      )
      EG.changeToSection('all')
    }
  }

  jsonData.studentMap = keyBy(jsonData.studentsWithSubmissions, anonymizableId)

  switch (userSettings.get('eg_sort_by')) {
    case 'submitted_at': {
      jsonData.studentsWithSubmissions.sort(
        EG.compareStudentsBy(student => {
          const submittedAt = student && student.submission && student.submission.submitted_at
          if (submittedAt) {
            // @ts-expect-error
            return +tz.parse(submittedAt)
          } else {
            // puts the unsubmitted assignments at the bottom
            return Number.NaN
          }
        })
      )
      break
    }

    case 'submission_status': {
      const states = {
        not_graded: 1,
        resubmitted: 2,
        not_submitted: 3,
        graded: 4,
        not_gradeable: 5,
      }
      jsonData.studentsWithSubmissions.sort(
        EG.compareStudentsBy(
          student =>
            student && states[SpeedgraderHelpers.submissionState(student, ENV.grading_role)]
        )
      )
      break
    }

    // The list of students is sorted alphabetically on the server by student last name.
    default: {
      // sorting for isAnonymous occurred earlier before setting up studentMap
      if (!isAnonymous && utils.shouldHideStudentNames()) {
        window.jsonData.studentsWithSubmissions.sort(
          EG.compareStudentsBy((student: StudentWithSubmission) => {
            const studentIndex = student.index || 0
            // adding 1 to avoid issues with index 0 being given 'falsey treatment' in compareStudentsBy
            return studentIndex + 1
          })
        )
      }
    }
  }
}

function handleStudentOrSectionSelected(
  newStudentOrSection: string,
  historyBehavior: null | 'push' | 'replace' = null
) {
  if (newStudentOrSection && newStudentOrSection.match(/^section_(\d+|all)$/)) {
    const sectionId = newStudentOrSection.replace(/^section_/, '')
    EG.changeToSection(sectionId)
  } else {
    EG.handleStudentChanged(historyBehavior)
  }
}

function initDropdown() {
  const hideStudentNames = utils.shouldHideStudentNames()
  $('#hide_student_names').prop('checked', hideStudentNames)

  const optionsArray = window.jsonData.studentsWithSubmissions.map(
    (student: StudentWithSubmission) => {
      const {submission_state, submission} = student
      let {name} = student
      const className = SpeedgraderHelpers.classNameBasedOnStudent({submission_state, submission})
      if (hideStudentNames || isAnonymous) {
        name = anonymousName(student)
      }

      return {[anonymizableId]: student[anonymizableId], anonymizableId, name, className}
    }
  )

  const sectionSelectionOptionList = sectionSelectionOptions(
    window.jsonData.context.active_course_sections,
    window.jsonData.GROUP_GRADING_MODE,
    sectionToShow
  )

  $selectmenu = new SpeedgraderSelectMenu(sectionSelectionOptionList.concat(optionsArray))
  $selectmenu?.appendTo('#combo_box_container', (event: JQuery.ClickEvent) => {
    handleStudentOrSectionSelected(String($(event.target).val()), HISTORY_PUSH)
  })

  if (
    window.jsonData.context.active_course_sections.length &&
    window.jsonData.context.active_course_sections.length > 1 &&
    !window.jsonData.GROUP_GRADING_MODE
  ) {
    const $selectmenu_list = $selectmenu?.data('ui-selectmenu').list
    const $menu = $('#section-menu')

    $menu
      .find('ul')
      .append(
        $.map(
          window.jsonData.context.active_course_sections,
          section =>
            `<li><a class="section_${section.id}" data-section-id="${
              section.id
            }" href="#">${htmlEscape(section.name)}</a></li>`
        ).join('')
      )

    $menu
      .insertBefore($selectmenu_list)
      .bind('mouseenter mouseleave', function (event) {
        $(this)
          .toggleClass(
            'ui-selectmenu-item-selected ui-selectmenu-item-focus ui-state-hover',
            event.type === 'mouseenter'
          )
          .find('ul')
          .toggle(event.type === 'mouseenter')
      })
      .find('ul')
      .hide()
      .menu()
      .on('click mousedown', 'a', function (_event) {
        EG.changeToSection($(this).data('section-id'))
      })

    if (sectionToShow) {
      const text = $.map(window.jsonData.context.active_course_sections, section => {
        // eslint-disable-next-line eqeqeq
        if (section.id == sectionToShow) {
          return section.name
        }
      }).join(', ')

      $('#section_currently_showing').text(text)
      $menu
        .find('ul li a')
        .removeClass('selected')
        .filter(`[data-section-id=${sectionToShow}]`)
        .addClass('selected')
    }

    $selectmenu
      .selectmenu('option', 'open', () => {
        $selectmenu_list
          .find('li:first')
          .css('margin-top', `${$selectmenu_list.find('li').height()}px`)
        $menu.show().css({
          left: $selectmenu_list.css('left'),
          top: $selectmenu_list.css('top'),
          width: $selectmenu_list.width(),
          'z-index': Number($selectmenu_list.css('z-index')) + 1,
        })
      })
      .selectmenu('option', 'close', () => {
        $menu.hide()
      })
  }
}

function setupPostPolicies() {
  const gradesPublished =
    !window.jsonData.moderated_grading || window.jsonData.grades_published_at != null

  EG.postPolicies = new PostPolicies({
    assignment: {
      anonymousGrading: window.jsonData.anonymous_grading,
      gradesPublished,
      id: window.jsonData.id,
      name: window.jsonData.title,
    },
    sections: window.jsonData.context.active_course_sections,
    updateSubmission: EG.setOrUpdateSubmission,
    afterUpdateSubmission() {
      EG.showGrade()
    },
  })

  renderPostGradesMenu(EG)
}

type Header = ReturnType<typeof setupHeader>

function setupHeader() {
  const elements = {
    nav: $gradebook_header.find('#prev-student-button, #next-student-button'),
    settings: {form: $('#settings_form')},
  }

  return {
    elements,
    courseId: utils.getParam('courses'),
    assignmentId: utils.getParam('assignment_id'),
    init() {
      this.addEvents()
      this.createModals()
      return this
    },
    addEvents() {
      this.elements.nav.click($.proxy(this.toAssignment, this))
      this.elements.settings.form.submit(this.submitSettingsForm.bind(this))
    },
    createModals() {
      this.elements.settings.form
        .dialog({
          autoOpen: false,
          modal: true,
          resizable: false,
          width: 400,
          zIndex: 1000,
        })
        .fixDialogButtons()
      // FF hack - when reloading the page, firefox seems to "remember" the disabled state of this
      // button. So here we'll manually re-enable it.
      this.elements.settings.form.find('.submit_button').removeAttr('disabled')
    },

    toAssignment(e: JQuery.ClickEvent) {
      e.preventDefault()
      const classes = e.target.getAttribute('class').split(' ')
      if (classes.includes('prev')) {
        EG.prev()
      } else if (classes.includes('next')) {
        EG.next()
      }
    },

    keyboardShortcutInfoModal() {
      if (!ENV.disable_keyboard_shortcuts) {
        const questionMarkKeyDown = $.Event('keydown', {keyCode: 191, shiftKey: true})
        $(document).trigger(questionMarkKeyDown)
      }
    },

    submitSettingsForm(e: JQuery.SubmitEvent) {
      e.preventDefault()

      const sortBy = $('#eg_sort_by').val()
      const sortByChanged = sortBy !== utils.sortByCriteria()
      userSettings.set('eg_sort_by', sortBy)

      let hideNamesChanged = false
      if (!ENV.force_anonymous_grading) {
        const hideNames = $('#hide_student_names').prop('checked')
        hideNamesChanged = hideNames !== utils.shouldHideStudentNames()
        userSettings.set('eg_hide_student_names', hideNames)
      }

      const isClassicQuiz = !!window.jsonData.context.quiz
      const needsReload = hideNamesChanged || sortByChanged || isClassicQuiz
      if (needsReload) {
        $(e.target)
          .find('.submit_button')
          .prop('disabled', true)
          .text(I18n.t('buttons.saving_settings', 'Saving Settings...'))
      } else {
        this.elements.settings.form.dialog('close')
      }

      const gradeByQuestion = !!$('#enable_speedgrader_grade_by_question').prop('checked')
      if (gradeByQuestion !== ENV.GRADE_BY_QUESTION) {
        ENV.GRADE_BY_QUESTION = gradeByQuestion
        QuizzesNextSpeedGrading.postGradeByQuestionChangeMessage($iframe_holder, gradeByQuestion)
      }

      // eslint-disable-next-line promise/catch-or-return
      $.post(ENV.settings_url, {
        enable_speedgrader_grade_by_question: gradeByQuestion,
      }).then(() => {
        if (needsReload) {
          SpeedgraderHelpers.reloadPage()
        }
      })
    },

    showSettingsModal(event: Event) {
      if (event) {
        event.preventDefault()
      }
      this.elements.settings.form.dialog('open')
    },
  }
}

function renderProgressIcon(attachment: Attachment) {
  const mountPoint = document.getElementById('react_pill_container')
  if (!mountPoint) throw new Error('Could not find mount point for react_pill_container')
  const iconAndTipMap = {
    pending: {
      icon: <IconUploadLine />,
      tip: I18n.t('Uploading Submission'),
    },
    failed: {
      icon: <IconWarningLine />,
      tip: I18n.t('Submission Failed to Submit'),
    },
    default: {
      icon: <IconCheckMarkIndeterminateLine />,
      tip: I18n.t('No File Submitted'),
    },
  }

  if (attachment.upload_status === 'success') {
    ReactDOM.unmountComponentAtNode(mountPoint)
  } else {
    const {icon, tip} = iconAndTipMap[attachment.upload_status] || iconAndTipMap.default
    const tooltip = (
      <Tooltip renderTip={tip} on={['click', 'hover', 'focus']}>
        <IconButton
          renderIcon={icon}
          withBorder={false}
          withBackground={false}
          screenReaderLabel={I18n.t('Toggle tooltip')}
        />
      </Tooltip>
    )
    ReactDOM.render(tooltip, mountPoint)
  }
}

function renderHiddenSubmissionPill(submission: Submission) {
  const mountPoint = document.getElementById(SPEED_GRADER_HIDDEN_SUBMISSION_PILL_MOUNT_POINT)
  if (!mountPoint) throw new Error('hidden submission pill mount point not found')

  if (isPostable(submission)) {
    ReactDOM.render(
      <Pill color="warning" margin="0 0 small">
        {I18n.t('Hidden')}
      </Pill>,
      mountPoint
    )
  } else {
    ReactDOM.unmountComponentAtNode(mountPoint)
  }
}

function renderCommentTextArea() {
  // unmounting is a temporary workaround for INSTUI-870 to allow
  // for textarea minheight to be reset
  unmountCommentTextArea()
  function getTextAreaRef(textarea: HTMLTextAreaElement) {
    $add_a_comment_textarea = $(textarea)
  }

  ReactDOM.render(
    <CommentArea
      getTextAreaRef={getTextAreaRef}
      courseId={ENV.course_id}
      userId={ENV.current_user_id!}
    />,
    document.getElementById(SPEED_GRADER_COMMENT_TEXTAREA_MOUNT_POINT)
  )
}

function initCommentBox() {
  renderCommentTextArea()

  $('.media_comment_link').click(event => {
    event.preventDefault()
    if ($('.media_comment_link').hasClass('ui-state-disabled')) {
      return
    }
    $('#media_media_recording')
      .show()
      .find('.media_recording')
      .mediaComment(
        'create',
        'any',
        (id: string, type: string) => {
          $('#media_media_recording').data('comment_id', id).data('comment_type', type)
          EG.addSubmissionComment()
        },
        () => {
          EG.revertFromFormSubmit()
        },
        true
      )
  })

  $(document).on('click', '#media_recorder_container a', hideMediaRecorderContainer)

  // handle speech to text for browsers that can (right now only chrome)
  function browserSupportsSpeech() {
    return 'webkitSpeechRecognition' in window
  }

  if (browserSupportsSpeech()) {
    // eslint-disable-next-line new-cap
    const recognition = new window.webkitSpeechRecognition()
    const messages = {
      begin: I18n.t('begin_record_prompt', 'Click the "Record" button to begin.'),
      allow: I18n.t('allow_message', 'Click the "Allow" button to begin recording.'),
      recording: I18n.t('recording_message', 'Recording...'),
      recording_expired: I18n.t(
        'recording_expired_message',
        'Speech recognition has expired due to inactivity. Click the "Stop" button to use current text for comment or "Cancel" to discard.'
      ),
      mic_blocked: I18n.t(
        'mic_blocked_message',
        'Permission to use microphone is blocked. To change, go to chrome://settings/content/microphone'
      ),
      no_speech: I18n.t(
        'nodetect_message',
        'No speech was detected. You may need to adjust your microphone settings.'
      ),
    }

    configureRecognition(recognition, messages)

    const processSpeech = function ($this: JQuery<HTMLElement>) {
      if ($('#record_button').attr('recording') === 'true') {
        recognition.stop()
        const current_comment = $('#final_results').html() + $('#interim_results').html()
        $add_a_comment_textarea.val(formatComment(current_comment))
        $this.dialog('close').remove()
      } else {
        recognition.start()
        $('#dialog_message').text(messages.allow)
      }
    }

    const formatComment = function (current_comment: string) {
      return current_comment.replace(/<p><\/p>/g, '\n\n').replace(/<br>/g, '\n')
    }

    $('.speech_recognition_link').click(() => {
      if ($('.speech_recognition_link').hasClass('ui-state-disabled')) {
        return false
      }
      $(
        speechRecognitionTemplate({
          message: messages.begin,
        })
      ).dialog({
        title: I18n.t('titles.click_to_record', 'Speech to Text'),
        minWidth: 450,
        minHeight: 200,
        dialogClass: 'no-close',
        buttons: [
          {
            class: 'dialog_button',
            text: I18n.t('buttons.dialog_buttons', 'Cancel'),
            click() {
              recognition.stop()
              $(this).dialog('close').remove()
            },
          },
          {
            id: 'record_button',
            class: 'dialog_button',
            'aria-label': I18n.t('dialog_button.aria_record', 'Click to record'),
            recording: false,
            html: '<div></div>',
            click() {
              const $this = $(this)
              processSpeech($this)
            },
          },
        ],
        close() {
          recognition.stop()
          $(this).dialog('close').remove()
        },
        modal: true,
        zIndex: 1000,
      })
      return false
    })
    // show the div that contains the button because it is hidden from browsers that dont support speech
    $('.speech_recognition_link').closest('div.speech-recognition').show()
  }
}

function assessmentBelongsToCurrentUser(assessment: RubricAssessment) {
  if (!assessment) {
    return false
  }

  if (anonymousGraders) {
    return ENV.current_anonymous_id === assessment.anonymous_assessor_id
  } else {
    return ENV.current_user_id === assessment.assessor_id
  }
}

function handleSelectedRubricAssessmentChanged({validateEnteredData = true} = {}) {
  // This function is triggered both when we assess a student and when we switch
  // students. In the former case, we want populateNewRubricSummary to check the
  // data we entered and show an alert if the grader tried to assign more points
  // to an outcome than it allows (and the course does not allow extra credit).
  // In the latter case, because this function is called *before* the editing
  // data is switched over to the new student, we don't want to perform the
  // comparison since it could result in specious alerts being shown.
  const editingData = validateEnteredData
    ? rubricAssessment.assessmentData($('#rubric_full'))
    : null
  const selectedAssessment = getSelectedAssessment(EG)
  rubricAssessment.populateNewRubricSummary(
    $('#rubric_summary_holder .rubric_summary'),
    selectedAssessment,
    window.jsonData.rubric_association,
    editingData
  )

  let showEditButton = true
  if (isModerated) {
    showEditButton = !selectedAssessment || assessmentBelongsToCurrentUser(selectedAssessment)
  }
  $('#rubric_assessments_list_and_edit_button_holder .edit').showIf(showEditButton)

  if (enhanced_rubrics) {
    if (
      !selectedAssessment?.assessor_id ||
      ENV.RUBRIC_ASSESSMENT.assessor_id === selectedAssessment?.assessor_id
    ) {
      $('button.toggle_full_rubric').show()
    } else {
      $('button.toggle_full_rubric').hide()
    }
  }
}

function initRubricStuff() {
  $('#rubric_summary_container .button-container')
    .appendTo('#rubric_assessments_list_and_edit_button_holder')
    .find('.edit')
    .text(I18n.t('edit_view_rubric', 'View Rubric'))

  $('.toggle_full_rubric, .hide_rubric_link').click(e => {
    e.preventDefault()
    EG.toggleFullRubric()
  })

  $('#rubric_assessments_select').on('change', () => {
    handleSelectedRubricAssessmentChanged()
  })

  $('.save_rubric_button').click(function () {
    const $rubric = $(this).parents('#rubric_holder').find('.rubric')
    const data = rubricAssessment.assessmentData($rubric)
    EG.saveRubricAssessment(data, $rubric)
  })
}

function initKeyCodes() {
  if (ENV.disable_keyboard_shortcuts) {
    return
  }
  const keycodeOptions = {
    keyCodes: 'j k p n c r g',
    ignore: 'input, textarea, embed, object',
  }

  $window.keycodes(keycodeOptions, event => {
    event.preventDefault()
    event.stopPropagation()
    const {keyString} = event

    if (keyString === 'k' || keyString === 'p') {
      EG.prev() // goto Previous Student
    } else if (keyString === 'j' || keyString === 'n') {
      EG.next() // goto Next Student
    } else if (keyString === 'c') {
      $add_a_comment_textarea.focus() // add comment
    } else if (keyString === 'g') {
      $grade.focus() // focus on grade
    } else if (keyString === 'r') {
      EG.toggleFullRubric() // focus rubric
    }
  })
}

function initGroupAssignmentMode() {
  if (window.jsonData.GROUP_GRADING_MODE) {
    gradeeLabel = groupLabel
  }
}

function refreshGrades(
  callback: (submission: Submission) => void,
  retry?: (submission: Submission, originalSubmission: Submission, numRequests: number) => boolean,
  retryDelay?: number
) {
  const courseId = ENV.course_id
  const originalSubmission = {...EG.currentStudent.submission}
  const assignmentId = originalSubmission.assignment_id
  const studentId = originalSubmission[anonymizableUserId]
  const resourceSegment = isAnonymous ? 'anonymous_submissions' : 'submissions'
  const params = {'include[]': 'submission_history'}
  const url = `/api/v1/courses/${courseId}/assignments/${assignmentId}/${resourceSegment}/${studentId}.json`
  const currentStudentIDAsOfAjaxCall = EG.currentStudent[anonymizableId]
  const onSuccess = (submission: Submission) => {
    const studentToRefresh = window.jsonData.studentMap[currentStudentIDAsOfAjaxCall]
    EG.setOrUpdateSubmission(submission)

    EG.updateSelectMenuStatus(studentToRefresh)
    if (studentToRefresh === EG.currentStudent) {
      EG.showGrade()
    }

    if (callback) {
      callback(submission)
    }
  }

  let numRequests = 0
  const fetchSubmission = () => {
    numRequests += 1
    $.getJSON(url, params, submission => {
      if (retry?.(submission, originalSubmission, numRequests)) {
        setGradeLoading(currentStudentIDAsOfAjaxCall, true)
        retryDelay ? setTimeout(fetchSubmission, retryDelay) : fetchSubmission()
      } else {
        setGradeLoading(currentStudentIDAsOfAjaxCall, false)
        onSuccess(submission)
      }
    })
  }

  fetchSubmission()
}

$.extend(INST, {
  refreshGrades,
  refreshQuizSubmissionSnapshot(data: ScoringSnapshot) {
    snapshotCache[`${data.user_id}_${data.version_number}`] = data
    if (data.last_question_touched) {
      INST.lastQuestionTouched = data.last_question_touched
    }
  },
  clearQuizSubmissionSnapshot(data: {user_id: string; version_number: string}) {
    snapshotCache[`${data.user_id}_${data.version_number}`] = null
  },
  getQuizSubmissionSnapshot(user_id: string, version_number: string) {
    return snapshotCache[`${user_id}_${version_number}`]
  },
})

function renderSubmissionCommentsDownloadLink(submission: HistoricalSubmission) {
  const mountPoint = document.getElementById(SPEED_GRADER_SUBMISSION_COMMENTS_DOWNLOAD_MOUNT_POINT)
  if (!mountPoint) throw new Error('SpeedGrader: mount point not found')
  if (isAnonymous) {
    mountPoint.innerHTML = ''
  } else {
    mountPoint.innerHTML = `<a href="/submissions/${htmlEscape(
      submission.id || ''
    )}/comments.pdf" target="_blank">${htmlEscape(I18n.t('Download Submission Comments'))}</a>`
  }
  return mountPoint
}

function availableMountPointForStatusMenu() {
  const elementId = $submission_details.is(':hidden')
    ? SPEED_GRADER_EDIT_STATUS_MENU_SECONDARY_MOUNT_POINT
    : SPEED_GRADER_EDIT_STATUS_MENU_MOUNT_POINT
  return document.getElementById(elementId)
}

function statusMenuComponent(submission: Submission) {
  return (
    <SpeedGraderStatusMenu
      key={submission.id}
      lateSubmissionInterval={ENV.late_policy?.late_submission_interval || 'day'}
      locale={ENV.LOCALE}
      secondsLate={submission.seconds_late || 0}
      selection={determineSubmissionSelection(submission)}
      updateSubmission={updateSubmissionAndPageEffects}
      cachedDueDate={submission.cached_due_date}
      customStatuses={(ENV.custom_grade_statuses as GradeStatusUnderscore[])?.filter(
        status => status.applies_to_submissions
      )}
    />
  )
}

function updateSubmissionAndPageEffects(data?: {
  excuse?: boolean
  latePolicyStatus?: string
  secondsLateOverride?: number
  customGradeStatusId?: string
}) {
  const submission = EG.currentStudent.submission

  makeSubmissionUpdateRequest(submission, isAnonymous, ENV.course_id, data)
    .then(() => {
      refreshGrades(() => {
        EG.showSubmissionDetails()
        if (availableMountPointForStatusMenu()) {
          const mountPoint = availableMountPointForStatusMenu()
          if (!mountPoint) throw new Error('SpeedGrader: mount point for status menu not found')
          renderStatusMenu(statusMenuComponent(submission), mountPoint)
        }
      })
    })
    .catch(showFlashError())
}

// Public Variables and Methods
EG = {
  // @ts-expect-error
  currentStudent: null,
  refreshGrades,

  domReady() {
    function makeFullWidth() {
      $full_width_container.addClass('full_width')
      $left_side.css('width', '')
      $right_side.css('width', '')
    }
    $(document).mouseup(_event => {
      $resize_overlay.hide()
    })
    // it should disappear before it's clickable, but just in case...
    $resize_overlay.click(function (this: HTMLElement, _event) {
      $(this).hide()
    })
    $width_resizer
      .mousedown(_event => {
        $resize_overlay.show()
      })
      .draggable({
        axis: 'x',
        cursor: 'crosshair',
        scroll: false,
        containment: '#full_width_container',
        snap: '#full_width_container',
        appendTo: '#full_width_container',
        helper() {
          return $width_resizer.clone().addClass('clone')
        },
        snapTolerance: 200,
        drag(event: Event, ui) {
          const offset = ui.offset
          const windowWidth = $window.width() as number
          $left_side.width(`${(offset.left / windowWidth) * 100}%`)
          $right_side.width(`${100 - (offset.left / windowWidth) * 100}%`)
          $width_resizer.css('left', '0')
          if (windowWidth - offset.left < $(this).draggable('option', 'snapTolerance')) {
            makeFullWidth()
          } else {
            $full_width_container.removeClass('full_width')
          }
          if (offset.left < $(this).draggable('option', 'snapTolerance')) {
            $left_side.width('0%')
            $right_side.width('100%')
          }
        },
        stop(event: Event, _ui) {
          event.stopImmediatePropagation()
          $resize_overlay.hide()
        },
      })
      .click(function (this: HTMLElement, event) {
        event.preventDefault()
        if ($full_width_container.hasClass('full_width')) {
          $full_width_container.removeClass('full_width')
        } else {
          makeFullWidth()
          $(this).addClass('highlight', 100, function (this: HTMLElement) {
            $(this).removeClass('highlight', 4000)
          })
        }
      })

    $grade.change(EG.handleGradeSubmit)

    $multiple_submissions.change(_e => {
      // @ts-expect-error
      if (typeof EG.currentStudent.submission === 'undefined') EG.currentStudent.submission = {}
      const i =
        $('#submission_to_view').val() || EG.currentStudent.submission.submission_history.length - 1
      EG.currentStudent.submission.currentSelectedIndex = parseInt(String(i), 10)
      EG.handleSubmissionSelectionChange()
    })

    initRubricStuff()

    if (ENV.can_comment_on_submission) {
      initCommentBox()
    }

    EG.initComments()
    header.init()
    initKeyCodes()

    $('.dismiss_alert').click(function (e) {
      e.preventDefault()
      $(this).closest('.alert').hide()
    })

    $('#eg_sort_by').val(userSettings.get('eg_sort_by') || '')
    $('#submit_same_score').click((e: JQuery.ClickEvent) => {
      // By passing true as the second argument, we're telling
      // handleGradeSubmit to use the existing previous submission score
      // for the current grade.
      EG.handleGradeSubmit(e, true)
      e.preventDefault()
    })

    setupBeforeLeavingSpeedgrader()
  },

  jsonReady() {
    isAnonymous = setupIsAnonymous(window.jsonData)
    isModerated = setupIsModerated(window.jsonData)
    anonymousGraders = setupAnonymousGraders(window.jsonData)
    anonymizableId = setupAnonymizableId(isAnonymous)
    anonymizableUserId = setupAnonymizableUserId(isAnonymous)
    anonymizableStudentId = setupAnonymizableStudentId(isAnonymous)
    anonymizableAuthorId = setupAnonymizableAuthorId(isAnonymous)

    mergeStudentsAndSubmission()

    if (window.jsonData.GROUP_GRADING_MODE && !window.jsonData.studentsWithSubmissions.length) {
      if (SpeedgraderHelpers.getHistory().length === 1) {
        // eslint-disable-next-line no-alert
        window.alert(
          I18n.t(
            'alerts.no_students_in_groups_close',
            "Sorry, submissions for this assignment cannot be graded in Speedgrader because there are no assigned users. Please assign users to this group set and try again. Click 'OK' to close this window."
          )
        )
        window.close()
      } else {
        // eslint-disable-next-line no-alert
        window.alert(
          I18n.t(
            'alerts.no_students_in_groups_back',
            "Sorry, submissions for this assignment cannot be graded in Speedgrader because there are no assigned users. Please assign users to this group set and try again. Click 'OK' to go back."
          )
        )
        SpeedgraderHelpers.getHistory().back()
      }
    } else if (!window.jsonData.studentsWithSubmissions.length) {
      // If we're trying to load a section with no students, we already showed
      // a "could not find any students in that section" alert and arranged
      // for a reload of the page, so don't show a second alert--but also don't
      // execute the else clause below this one since we don't want to set up
      // the rest of SpeedGrader
      if (sectionToShow == null) {
        // eslint-disable-next-line no-alert
        window.alert(
          I18n.t(
            'alerts.no_active_students',
            'Sorry, there are either no active students in the course or none are gradable by you.'
          )
        )
        SpeedgraderHelpers.getHistory().back()
      }
    } else {
      // unmount spinner
      const spinnerMount = document.getElementById('speed_grader_loading')
      if (spinnerMount) ReactDOM.unmountComponentAtNode(spinnerMount)
      $('#speed_grader_loading').hide()
      $('#gradebook_header, #full_width_container').show()
      initDropdown()
      initGroupAssignmentMode()
      setupHandleStatePopped()

      if (ENV.student_group_reason_for_change != null) {
        SpeedGraderAlerts.showStudentGroupChangeAlert({
          selectedStudentGroup: ENV.selected_student_group,
          reasonForChange: ENV.student_group_reason_for_change,
        })
      }
      setupPostPolicies()
    }
  },

  parseDocumentQuery() {
    return qs.parse(document.location.search, {ignoreQueryPrefix: true})
  },

  setInitiallyLoadedStudent() {
    let initialStudentId

    const queryParams = EG.parseDocumentQuery()
    if (queryParams && queryParams[anonymizableStudentId]) {
      initialStudentId = queryParams[anonymizableStudentId]
    } else if (SpeedgraderHelpers.getLocationHash() !== '') {
      initialStudentId = extractStudentIdFromHash(
        SpeedgraderHelpers.getLocationHash(),
        anonymizableStudentId
      )
    }
    SpeedgraderHelpers.setLocationHash('')

    const attemptParam = utils.getParam('attempt')
    if (attemptParam) {
      EG.initialVersion = parseInt(attemptParam, 10) - 1
    }

    // Check if this student ID "resolves" to a different one (e.g., it's an
    // invalid ID, or is in a group with someone else as a representative).
    const resolvedId = EG.resolveStudentId(initialStudentId)

    EG.goToStudent(resolvedId, HISTORY_REPLACE)
  },

  setupGradeLoadingSpinner() {
    ReactDOM.render(
      <GradeLoadingSpinner onLoadingChange={loading => toggleGradeVisibility(!loading)} />,
      document.getElementById('grades-loading-spinner')
    )
  },

  // Exists for testing purposes only
  setState(state) {
    useStore.setState(state)
  },

  anyUnpostedComment() {
    return !!(
      $.trim($add_a_comment_textarea.val() as string).length ||
      $('#media_media_recording').data('comment_id') ||
      $add_a_comment.find("input[type='file']:visible").length
    )
  },

  skipRelativeToCurrentIndex(offset) {
    const nextStudent = (offset_: number) => {
      const {length: students} = window.jsonData.studentsWithSubmissions
      const newIndex = (this.currentIndex() + offset_ + students) % students
      this.goToStudent(
        window.jsonData.studentsWithSubmissions[newIndex][anonymizableId],
        HISTORY_PUSH
      )
      const nextSubmission = window.jsonData.studentsWithSubmissions[newIndex].submission
      if (nextSubmission.missing && nextSubmission.grader_id) {
        updateSubmissionAndPageEffects()
      }
    }

    const doNotShowModalSetting = 'speedgrader.dont_show_unposted_comment_dialog.' + assignmentUrl

    if (!userSettings.get(doNotShowModalSetting) && this.anyUnpostedComment()) {
      const closeDialog = () => {
        if ($(document).find('.do-not-show-again input').is(':checked')) {
          userSettings.set(doNotShowModalSetting, true)
        }
        $dialog.dialog('close')
        $dialog.dialog('destroy').remove() // this actually removes it from DOM
      }

      const $dialog = $(
        unsubmittedCommentsTemplate({
          message: I18n.t(
            'You have created a comment that has not been posted. Do you want to proceed and save this comment as a draft? (You can post draft comments at any time.)'
          ),
        })
      ).dialog({
        title: I18n.t('Your comment is not posted'),
        minWidth: 500,
        minHeight: 200,
        resizable: false,
        dialogClass: 'no-close',
        modal: true,
        create(_e, _ui) {
          const pane = $(this).dialog('widget').find('.ui-dialog-buttonpane')
          $(
            `<label class='do-not-show-again'><input type='checkbox'/>&nbsp;${I18n.t(
              'Do not show again for this assignment'
            )}</label>`
          ).prependTo(pane)
        },
        buttons: [
          {
            id: 'unposted_comment_cancel',
            class: 'dialog_button',
            text: I18n.t('Cancel'),
            click: () => {
              closeDialog()
            },
          },
          {
            id: 'unposted_comment_proceed',
            class: 'dialog_button',
            text: I18n.t('Proceed'),
            click: () => {
              closeDialog()
              nextStudent(offset)
            },
          },
        ],
        zIndex: 1000,
      })
    } else {
      nextStudent(offset)
    }
  },

  next() {
    this.skipRelativeToCurrentIndex(1)
    const studentInfo = this.getStudentNameAndGrade()
    $('#aria_name_alert').text(studentInfo)
  },

  prev() {
    this.skipRelativeToCurrentIndex(-1)
    const studentInfo = this.getStudentNameAndGrade()
    $('#aria_name_alert').text(studentInfo)
  },

  getStudentNameAndGrade: (student = EG.currentStudent) => {
    let studentName
    if (utils.shouldHideStudentNames()) {
      studentName = anonymousName(student)
    } else {
      studentName = student.name
    }

    const submissionStatus = SpeedgraderHelpers.classNameBasedOnStudent(student)
    return `${studentName} - ${submissionStatus.formatted}`
  },

  toggleFullRubric(force) {
    // if there is no rubric associated with this assignment, then the edit
    // rubric thing should never be shown.  the view should make sure that
    // the edit rubric html is not even there but we also want to make sure
    // that pressing "r" wont make it appear either
    if (!window.jsonData.rubric_association) {
      return false
    }

    const isClosed = force === 'close'

    if (enhanced_rubrics) {
      const isOpen = isClosed ? false : !useStore.getState().rubricAssessmentTrayOpen
      useStore.setState({rubricAssessmentTrayOpen: isOpen})
      this.refreshFullRubric()
      return
    }

    const rubricFull = selectors.get('#rubric_full')

    if (rubricFull.filter(':visible').length || isClosed) {
      toggleGradeVisibility(true)
      rubricFull.fadeOut()
      $('.toggle_full_rubric').focus()
    } else {
      rubricFull.fadeIn()
      toggleGradeVisibility(false)
      this.refreshFullRubric()
      originalRubric = EG.getOriginalRubricInfo()
      rubricFull.find('.rubric_title .title').focus()
    }
  },

  refreshFullRubric() {
    if (enhanced_rubrics) {
      const assessment = rubricAssessmentToPopulate(EG) as any
      useStore.setState({studentAssessmentData: assessment?.data})
      return
    }

    const rubricFull = selectors.get('#rubric_full')
    if (!window.jsonData.rubric_association) {
      return
    }
    if (!rubricFull.filter(':visible').length) {
      return
    }

    const container = rubricFull.find('.rubric')
    rubricAssessment.populateNewRubric(
      container,
      rubricAssessmentToPopulate(EG),
      window.jsonData.rubric_association
    )
    $('#grading').height(rubricFull.height())
  },

  getOriginalRubricInfo() {
    if (window.jsonData.rubric_association) {
      const $originalRubric = $('.save_rubric_button').parents('#rubric_holder').find('.rubric')
      return rubricAssessment.assessmentData($originalRubric)
    }
    return null
  },

  hasUnsubmittedRubric(originalRubric_) {
    const $rubricFull = $('#rubric_full')
    if ($rubricFull.filter(':visible').length) {
      const $unSavedRubric = $('.save_rubric_button').parents('#rubric_holder').find('.rubric')
      const unSavedData = rubricAssessment.assessmentData($unSavedRubric)
      return !isEqual(unSavedData, originalRubric_)
    }
    return false
  },

  handleStatePopped(event: PopStateEvent) {
    // On page load this will be called with a null state, ignore it
    if (!event.state) {
      return
    }

    const newStudentId = event.state[anonymizableStudentId]
    if (EG.currentStudent == null || newStudentId !== EG.currentStudent[anonymizableId]) {
      const studentIdentifier = EG.resolveStudentId(newStudentId)
      EG.goToStudent(studentIdentifier)
    }
  },

  updateHistoryForCurrentStudent(behavior) {
    const studentId = this.currentStudent[anonymizableId]
    const stateHash = {[anonymizableStudentId]: studentId}
    const url = encodeURI(
      `?assignment_id=${ENV.assignment_id}&${anonymizableStudentId}=${studentId}`
    )

    if (behavior === HISTORY_PUSH) {
      SpeedgraderHelpers.getHistory().pushState(stateHash, '', url)
    } else {
      SpeedgraderHelpers.getHistory().replaceState(stateHash, '', url)
    }
  },

  resolveStudentId(studentId: string | null = null): string | undefined {
    let representativeOrStudentId = studentId

    // If not anonymous, see if we need to use this student's representative instead
    if (
      !isAnonymous &&
      studentId != null &&
      window.jsonData.context.rep_for_student[studentId] != null
    ) {
      representativeOrStudentId = window.jsonData.context.rep_for_student[studentId]
    }

    // choose the first ungraded student if the requested one doesn't exist
    if (!window.jsonData.studentMap[String(representativeOrStudentId)]) {
      const ungradedStudent = window.jsonData.studentsWithSubmissions.find(
        (s: StudentWithSubmission) =>
          s.submission &&
          s.submission.workflow_state !== 'graded' &&
          s.submission.submission_type &&
          (!isModerated || s.submission.grade == null)
      )
      const student = ungradedStudent || window.jsonData.studentsWithSubmissions[0]
      representativeOrStudentId = student[anonymizableId]
    }

    return representativeOrStudentId?.toString()
  },

  goToStudent(studentIdentifier, historyBehavior = null) {
    const student = window.jsonData.studentMap[studentIdentifier]

    if (student) {
      $selectmenu?.selectmenu('value', student[anonymizableId])
      if (!this.currentStudent || this.currentStudent[anonymizableId] !== student[anonymizableId]) {
        EG.handleStudentChanged(historyBehavior)
      }
    }
  },

  currentIndex() {
    return $.inArray(this.currentStudent, window.jsonData.studentsWithSubmissions)
  },

  handleStudentChanged(historyBehavior = null) {
    // Save any draft comments before loading the new student
    if ($add_a_comment_textarea.hasClass('ui-state-disabled')) {
      $add_a_comment_textarea.val('')
    } else {
      EG.addSubmissionComment(true)
    }

    if (!$selectmenu) {
      throw new Error('SpeedGrader: selectmenu not found')
    }

    const selectMenuValue = $selectmenu.val()
    // calling _.values on a large collection could be slow, that's why we're fetching from studentMap first
    this.currentStudent =
      window.jsonData.studentMap[selectMenuValue] ||
      values(window.jsonData.studentsWithSubmissions)[0]

    useStore.setState({currentStudentId: this.currentStudent[anonymizableId]})
    EG.resetReassignButton()

    if (historyBehavior) {
      EG.updateHistoryForCurrentStudent(historyBehavior)
    }

    // On the switch to a new student, clear the state of the last
    // question touched on the previous student.
    INST.lastQuestionTouched = null

    if (
      (ENV.grading_role === 'provisional_grader' &&
        this.currentStudent.submission_state === 'not_graded') ||
      ENV.grading_role === 'moderator'
    ) {
      $('.speedgrader_alert').hide()
      $submission_not_newest_notice.hide()
      $submission_late_notice.hide()
      $full_width_container.removeClass('with_enrollment_notice')
      $enrollment_inactive_notice.hide()
      $enrollment_concluded_notice.hide()
      selectors.get('#closed_gp_notice').hide()

      EG.setGradeReadOnly(true) // disabling now will keep it from getting undisabled unintentionally by disableWhileLoading
      if (
        ENV.grading_role === 'moderator' &&
        this.currentStudent.submission_state === 'not_graded'
      ) {
        this.currentStudent.submission.grade = null // otherwise it may be tricked into showing the wrong submission_state
      }

      // check whether we still can give a provisional grade
      $full_width_container.disableWhileLoading(this.fetchProvisionalGrades())
    } else {
      this.showStudent()
    }

    originalRubric = EG.getOriginalRubricInfo()
    this.setCurrentStudentAvatar()
  },

  resetReassignButton() {
    // Restore the tooltip text for the reassignment button
    // and enable the reassignment button if this user has
    // posted a comment since submission
    if ($reassign_assignment[0]) {
      const redoRequest = this.currentStudent?.submission?.redo_request
      let disableReassign = true
      let submittedAt = this.currentStudent?.submission?.submitted_at
      let maxAttempts = false
      let tooltipText = ''
      if (submittedAt) {
        const {allowed_attempts} = window.jsonData
        maxAttempts =
          allowed_attempts != null && allowed_attempts > 0
            ? (this.currentStudent.submission.attempt || 1) >=
              (window.jsonData.allowed_attempts || 0)
            : false
        submittedAt = new Date(submittedAt)
        let submissionComments = this.currentStudent.submission.submission_comments
        if (submissionComments) {
          submissionComments = submissionComments.filter(
            comment => comment.author_id === ENV.current_user_id
          )
          const lastCommentByUser = submissionComments[submissionComments.length - 1]
          if (lastCommentByUser?.created_at) {
            const commentedAt = new Date(lastCommentByUser.created_at)
            disableReassign = redoRequest || commentedAt < submittedAt || maxAttempts
          }
        }
      }
      $reassign_assignment.prop('disabled', disableReassign)
      $reassign_assignment.text(redoRequest ? I18n.t('Reassigned') : I18n.t('Reassign Assignment'))
      if (disableReassign) {
        if (redoRequest) {
          tooltipText = I18n.t('Assignment is reassigned.')
        } else if (maxAttempts) {
          tooltipText = I18n.t('Student has met maximum allowed attempts.')
        } else {
          tooltipText = I18n.t('Student feedback required in comments above to reassign.')
        }
      }
      $reassign_assignment.parent().attr('title', tooltipText)
    }
  },

  setCurrentStudentAvatar() {
    if (utils.shouldHideStudentNames() || isAnonymous || !this.currentStudent.avatar_path) {
      $avatar_image.hide()
    } else {
      // If there's any kind of delay in loading the user's avatar, it's
      // better to show a blank image than the previous student's image.
      const $new_image = $avatar_image.clone().show()
      $avatar_image.after($new_image.attr('src', this.currentStudent.avatar_path)).remove()
      $avatar_image = $new_image
    }
  },

  setCurrentStudentRubricAssessments() {
    // currentStudent.rubric_assessments only includes assessments submitted
    // by the current user, so if the viewer is a moderator, get other
    // graders' assessments from their provisional grades.
    const provisionalAssessments: RubricAssessment[] = []

    // If the moderator has just saved a new assessment, this array will have
    // entries not present elsewhere, so don't clobber them.
    const currentAssessmentsById: Record<string, boolean> = {}
    if (this.currentStudent.rubric_assessments) {
      this.currentStudent.rubric_assessments.forEach(assessment => {
        currentAssessmentsById[assessment.id] = true
      })
    }

    currentStudentProvisionalGrades().forEach(grade => {
      // TODO: decide what to do if a provisional grade contains multiple
      // assessments (currently we're not sure if this can actually happen
      // for a moderated assignment).
      if (grade.rubric_assessments && grade.rubric_assessments.length > 0) {
        // Add the assessor display name to the assessment while we have easy
        // access to the provisional grade data
        const assessment = grade.rubric_assessments[0]
        assessment.assessor_name = provisionalGraderDisplayNames[grade.provisional_grade_id]
        if (!currentAssessmentsById[assessment.id]) {
          provisionalAssessments.push(assessment)
        }
      }
    })

    if (provisionalAssessments.length > 0) {
      if (!this.currentStudent.rubric_assessments) {
        this.currentStudent.rubric_assessments = []
      }

      this.currentStudent.rubric_assessments =
        this.currentStudent.rubric_assessments.concat(provisionalAssessments)
    }

    if (anonymousGraders) {
      this.currentStudent.rubric_assessments.sort((a: RubricAssessment, b: RubricAssessment) =>
        natcompare.strings(a.anonymous_assessor_id, b.anonymous_assessor_id)
      )
    }
  },

  showStudent() {
    $rightside_inner.scrollTo(0)
    if (
      this.currentStudent.submission_state === 'not_gradeable' &&
      ENV.grading_role === 'provisional_grader'
    ) {
      $rightside_inner.hide()
      $not_gradeable_message.show()
    } else {
      $not_gradeable_message.hide()
      $rightside_inner.show()
    }
    if (ENV.grading_role === 'moderator') {
      this.renderProvisionalGradeSelector({showingNewStudent: true})
      this.setCurrentStudentRubricAssessments()

      this.showSubmission()
      this.setReadOnly(false)

      const selectedGrade = currentStudentProvisionalGrades().find(grade => grade.selected)
      if (selectedGrade) {
        this.setActiveProvisionalGradeFields({
          label: provisionalGraderDisplayNames[selectedGrade.provisional_grade_id],
          grade: selectedGrade,
        })
      } else {
        this.setActiveProvisionalGradeFields()
      }
    } else {
      // showSubmissionOverride is optionally set if the user is
      // using the quizzes.next lti tool. Rather than reload the tool based
      // on a new URL, it just dispatches a message to tell the tool to
      // change itself
      const changeSubmission = showSubmissionOverride || this.showSubmission.bind(this)
      changeSubmission(this.currentStudent.submission)
    }
  },

  showSubmission() {
    this.showGrade()
    this.showDiscussion()
    this.showRubric({validateEnteredData: false})
    this.updateStatsInHeader()
    this.showSubmissionDetails()
    this.refreshFullRubric()
  },

  setGradeReadOnly(readonly) {
    if (readonly) {
      $grade
        .addClass('ui-state-disabled')
        .attr('readonly', 'readonly')
        .attr('aria-disabled', 'true')
        .prop('disabled', true)
    } else {
      $grade
        .removeClass('ui-state-disabled')
        .removeAttr('aria-disabled')
        .removeAttr('readonly')
        .removeProp('disabled')
    }
  },

  setUpAssessmentAuditTray() {
    const bindRef = (ref: AssessmentAuditTray) => {
      EG.assessmentAuditTray = ref
    }

    const tray = <AssessmentAuditTray ref={bindRef} />
    ReactDOM.render(tray, document.getElementById(ASSESSMENT_AUDIT_TRAY_MOUNT_POINT))

    const onClick = () => {
      const {submission} = this.currentStudent

      EG.assessmentAuditTray?.show({
        assignment: {
          gradesPublishedAt: window.jsonData.grades_published_at,
          id: ENV.assignment_id,
          pointsPossible: window.jsonData.points_possible,
        },
        courseId: ENV.course_id,
        submission: {
          id: submission.id,
          score: submission.score,
        },
      })
    }

    const button = <AssessmentAuditButton onClick={onClick} />
    ReactDOM.render(button, document.getElementById(ASSESSMENT_AUDIT_BUTTON_MOUNT_POINT))
  },

  setUpRubricAssessmentTrayWrapper() {
    ReactDOM.render(
      <RubricAssessmentTrayWrapper
        rubric={ENV.rubric as RubricUnderscoreType}
        onSave={data => {
          useStore.setState({rubricAssessmentTrayOpen: false})
          this.saveRubricAssessment(data)
        }}
      />,
      document.getElementById('speed_grader_rubric_assessment_tray_wrapper')
    )
  },

  saveRubricAssessment(
    data: {[key: string]: string | boolean | number},
    rubricElement?: JQuery<HTMLElement>
  ) {
    if (ENV.grading_role === 'moderator' || ENV.grading_role === 'provisional_grader') {
      data.provisional = '1'
      if (ENV.grading_role === 'moderator' && EG.current_prov_grade_index === 'final') {
        data.final = '1'
      }
    }
    if (isAnonymous) {
      // FIXME: data['rubric_assessment[user_id]'] should not contain anonymous_id,
      // figure out how to fix the keys elsewhere
      data[`rubric_assessment[${anonymizableUserId}]`] = data['rubric_assessment[user_id]']
      delete data['rubric_assessment[user_id]']
      data.graded_anonymously = true
    } else {
      data.graded_anonymously = utils.shouldHideStudentNames()
    }
    const url = ENV.update_rubric_assessment_url!
    const method = 'POST'
    EG.toggleFullRubric('close')

    const promise = $.ajaxJSON(
      url,
      method,
      data,
      ///
      (response: {
        id: string
        rubric_association: unknown
        artifact: unknown
        related_group_submissions_and_assessments: {
          rubric_assessments: {
            rubric_assessment: {id: string}
          }[]
        }[]
      }) => {
        let found = false
        if (response && response.rubric_association) {
          if (!enhanced_rubrics) {
            rubricAssessment.updateRubricAssociation(rubricElement, response.rubric_association)
          }
          delete response.rubric_association
        }

        // If the student has a submission, update it with the data returned,
        // otherwise we need to create a submission for them.
        const assessedStudent = EG.setOrUpdateSubmission(response.artifact)

        for (let i = 0; i < assessedStudent.rubric_assessments.length; i++) {
          if (response.id === assessedStudent.rubric_assessments[i].id) {
            $.extend(true, assessedStudent.rubric_assessments[i], response)
            found = true
          }
        }
        if (!found) {
          assessedStudent.rubric_assessments.push(response)
        }

        // this next part will take care of group submissions, so that when one member of the group gets assessesed then everyone in the group will get that same assessment.
        $.each(
          response.related_group_submissions_and_assessments,
          (_i, submissionAndAssessment) => {
            // setOrUpdateSubmission returns the student. so we can set student.rubric_assesments
            // submissionAndAssessment comes back with :include_root => true, so we have to get rid of the root
            const student = EG.setOrUpdateSubmission(response.artifact)
            student.rubric_assessments = $.map(
              submissionAndAssessment.rubric_assessments,
              ra => ra.rubric_assessment
            )
            EG.updateSelectMenuStatus(student)
          }
        )

        EG.showGrade()
        EG.showDiscussion()
        EG.showRubric()
        EG.updateStatsInHeader()
      }
    )

    $rubric_holder.disableWhileLoading(promise, {
      buttons: {
        '.save_rubric_button': 'Saving...',
      },
    })
  },

  setReadOnly(readonly) {
    if (readonly) {
      EG.setGradeReadOnly(true)
      $comments.find('.delete_comment_link').hide()
      $add_a_comment.hide()
    } else {
      // $grade will be disabled/enabled in showGrade()
      // $comments will be reconstructed
      $add_a_comment.show()
    }
  },

  plagiarismIndicator({
    plagiarismAsset,
    reportUrl,
    tooltip,
  }: {
    plagiarismAsset: SubmissionOriginalityData
    reportUrl?: null | string
    tooltip: string
  }) {
    const {status, similarity_score} = plagiarismAsset

    const $indicator = reportUrl != null ? $('<a />').attr('href', reportUrl) : $('<span />')
    $indicator
      .attr('title', String(tooltip))
      .addClass('similarity_score_container')
      .append($(similarityIcon(plagiarismAsset)))

    if (status === 'scored') {
      const $similarityScore = $('<span />')
        .addClass('turnitin_similarity_score')
        .html(htmlEscape(`${similarity_score}%`))
      $indicator.append($similarityScore)
    }

    return $indicator
  },

  populateTurnitin(
    submission: HistoricalSubmission,
    assetString: string,
    turnitinAsset_: SubmissionOriginalityData,
    $turnitinScoreContainer: JQuery,
    $turnitinInfoContainer_: JQuery,
    isMostRecent: boolean
  ) {
    const showLegacyResubmit =
      isMostRecent && (window.jsonData.vericite_enabled || window.jsonData.turnitin_enabled)

    // build up new values based on this asset
    if (
      turnitinAsset_.status === 'scored' ||
      (turnitinAsset_.status == null && turnitinAsset_.similarity_score != null)
    ) {
      const urlContainer = SpeedgraderHelpers.urlContainer(
        submission,
        $assignment_submission_turnitin_report_url,
        $assignment_submission_originality_report_url
      )
      const tooltip = I18n.t('Similarity Score - See detailed report')
      let reportUrl = replaceTags(urlContainer.attr('href') || '', {
        [anonymizableUserId]: submission[anonymizableUserId],
        asset_string: assetString,
      })
      reportUrl += (reportUrl.includes('?') ? '&' : '?') + 'attempt=' + submission.attempt

      if (ENV.new_gradebook_plagiarism_icons_enabled) {
        const $indicator = this.plagiarismIndicator({
          plagiarismAsset: turnitinAsset_,
          reportUrl,
          tooltip,
        })
        $turnitinScoreContainer.empty().append($indicator)
      } else {
        $turnitinScoreContainer.html(
          turnitinScoreTemplate({
            state: `${turnitinAsset_.state || 'no'}_score`,
            reportUrl,
            tooltip,
            score: `${turnitinAsset_.similarity_score}%`,
          })
        )
      }
    } else if (turnitinAsset_.status) {
      // status === 'error' or status === 'pending'
      const pendingTooltip = I18n.t(
          'turnitin.tooltip.pending',
          'Similarity Score - Submission pending'
        ),
        errorTooltip = I18n.t(
          'turnitin.tooltip.error',
          'Similarity Score - See submission error details'
        )
      const tooltip = turnitinAsset_.status === 'error' ? errorTooltip : pendingTooltip

      const $turnitinSimilarityScore = ENV.new_gradebook_plagiarism_icons_enabled
        ? this.plagiarismIndicator({
            plagiarismAsset: turnitinAsset_,
            tooltip,
          })
        : $(
            turnitinScoreTemplate({
              icon: `/images/turnitin_submission_${turnitinAsset_.status}.png`,
              reportUrl: '#',
              state: `submission_${turnitinAsset_.status}`,
              tooltip,
            })
          )

      $turnitinScoreContainer.append($turnitinSimilarityScore)
      $turnitinSimilarityScore.click(event => {
        event.preventDefault()
        $turnitinInfoContainer_.find(`.turnitin_${assetString}`).slideToggle()
      })

      const defaultInfoMessage = I18n.t(
        'turnitin.info_message',
        'This file is still being processed by the plagiarism detection tool associated with the assignment. Please check back later to see the score.'
      )
      const defaultErrorMessage = SpeedgraderHelpers.plagiarismErrorMessage(turnitinAsset_)
      const $turnitinInfo = $(
        turnitinInfoTemplate({
          assetString,
          message:
            turnitinAsset_.status === 'error'
              ? turnitinAsset_.public_error_message || defaultErrorMessage
              : defaultInfoMessage,
          showResubmit: showLegacyResubmit,
        })
      )
      $turnitinInfoContainer_.append($turnitinInfo)

      if (showLegacyResubmit) {
        const resubmitUrl = SpeedgraderHelpers.plagiarismResubmitUrl(
          submission as HistoricalSubmission,
          anonymizableUserId
        )
        $('.turnitin_resubmit_button').on('click', e => {
          SpeedgraderHelpers.plagiarismResubmitHandler(e, resubmitUrl)
        })
      }
    }
  },
  populateVeriCite(
    submission,
    assetString,
    vericiteAsset_,
    $vericiteScoreContainer_,
    $vericiteInfoContainer_,
    isMostRecent
  ) {
    // build up new values based on this asset
    if (
      vericiteAsset_.status === 'scored' ||
      (vericiteAsset_.status == null && vericiteAsset_.similarity_score != null)
    ) {
      let reportUrl
      let tooltip
      if (!isAnonymous) {
        reportUrl = replaceTags($assignment_submission_vericite_report_url.attr('href') || '', {
          user_id: submission.user_id,
          asset_string: assetString,
        })
        tooltip = I18n.t('VeriCite Similarity Score - See detailed report')
      } else {
        tooltip = anonymousAssignmentDetailedReportTooltip
      }

      if (ENV.new_gradebook_plagiarism_icons_enabled) {
        const $indicator = this.plagiarismIndicator({
          plagiarismAsset: vericiteAsset_,
          reportUrl,
          tooltip,
        })
        $vericiteScoreContainer_.empty().append($indicator)
      } else {
        $vericiteScoreContainer_.html(
          vericiteScoreTemplate({
            state: `${vericiteAsset_.state || 'no'}_score`,
            reportUrl,
            tooltip,
            score: `${vericiteAsset_.similarity_score}%`,
          })
        )
      }
    } else if (vericiteAsset_.status) {
      // status === 'error' or status === 'pending'
      const pendingTooltip = I18n.t(
          'vericite.tooltip.pending',
          'VeriCite Similarity Score - Submission pending'
        ),
        errorTooltip = I18n.t(
          'vericite.tooltip.error',
          'VeriCite Similarity Score - See submission error details'
        )
      const tooltip = vericiteAsset_.status === 'error' ? errorTooltip : pendingTooltip

      const $vericiteSimilarityScore = ENV.new_gradebook_plagiarism_icons_enabled
        ? this.plagiarismIndicator({
            plagiarismAsset: vericiteAsset_,
            tooltip,
          })
        : $(
            vericiteScoreTemplate({
              icon: `/images/turnitin_submission_${vericiteAsset_.status}.png`,
              reportUrl: '#',
              state: `submission_${vericiteAsset_.status}`,
              tooltip,
            })
          )
      $vericiteScoreContainer_.append($vericiteSimilarityScore)
      $vericiteSimilarityScore.click(event => {
        event.preventDefault()
        $vericiteInfoContainer_.find(`.vericite_${assetString}`).slideToggle()
      })

      const defaultInfoMessage = I18n.t(
          'vericite.info_message',
          'This file is still being processed by VeriCite. Please check back later to see the score'
        ),
        defaultErrorMessage = I18n.t(
          'vericite.error_message',
          'There was an error submitting to VeriCite. Please try resubmitting the file before contacting support'
        )
      const $vericiteInfo = $(
        vericiteInfoTemplate({
          assetString,
          message:
            vericiteAsset_.status === 'error'
              ? vericiteAsset_.public_error_message || defaultErrorMessage
              : defaultInfoMessage,
          showResubmit: vericiteAsset_.status === 'error' && isMostRecent,
        })
      )
      $vericiteInfoContainer_.append($vericiteInfo)

      if (vericiteAsset_.status === 'error' && isMostRecent) {
        const resubmitUrl = replaceTags(
          $assignment_submission_resubmit_to_vericite_url.attr('href') || '',
          {user_id: submission[anonymizableUserId]}
        )
        $vericiteInfo.find('.vericite_resubmit_button').click(function (event) {
          event.preventDefault()
          $(this).prop('disabled', true).text(I18n.t('vericite.resubmitting', 'Resubmitting...'))

          $.ajaxJSON(resubmitUrl, 'POST', {}, () => {
            SpeedgraderHelpers.reloadPage()
          })
        })
      }
    }
  },

  updateWordCount(wordCount?: number | null) {
    let wordCountHTML = ''
    if (
      wordCount &&
      !['basic_lti_launch', 'external_tool'].includes(
        this.currentStudent.submission?.submission_type as string
      )
    ) {
      // xsslint safeString.method toLocaleString
      // xsslint safeString.method t
      wordCountHTML = `<label>${I18n.t('Word Count')}:</label> ${I18n.t('word', {
        count: wordCount,
      })}`
    }
    $word_count.html(wordCountHTML)
  },

  handleSubmissionSelectionChange() {
    clearInterval(sessionTimer)

    function currentIndex(
      context: SpeedGrader,
      submissionToViewVal: string | number | string[] | undefined
    ) {
      if (submissionToViewVal) {
        return Number(submissionToViewVal)
      } else if (
        context.currentStudent &&
        context.currentStudent.submission &&
        context.currentStudent.submission.currentSelectedIndex
      ) {
        return context.currentStudent.submission.currentSelectedIndex
      }
      return 0
    }

    const $submission_to_view = $('#submission_to_view')
    const submissionToViewVal = $submission_to_view.val()
    const currentSelectedIndex = currentIndex(this, submissionToViewVal)
    const submissionHolder = this.currentStudent?.submission
    const submissionHistory = submissionHolder?.submission_history
    const isMostRecent = submissionHistory && submissionHistory.length - 1 === currentSelectedIndex
    const inlineableAttachments: Attachment[] = []
    const browserableAttachments: Attachment[] = []

    // @ts-expect-error
    let submission: HistoricalSubmission = {graded_at: null}
    if (submissionHistory && submissionHistory[currentSelectedIndex]) {
      submission =
        submissionHistory[currentSelectedIndex].submission ||
        submissionHistory[currentSelectedIndex]
    }

    const turnitinEnabled =
      submission.turnitin_data && typeof submission.turnitin_data.provider === 'undefined'
    const vericiteEnabled =
      submission.turnitin_data && submission.turnitin_data.provider === 'vericite'

    SpeedgraderHelpers.plagiarismResubmitButton(
      // TODO: figure out why we're using Object.values here
      // @ts-expect-error
      submission.has_originality_score &&
        Object.values(submission.turnitin_data as any).every(
          (tiid: any) => tiid.status !== 'error'
        ),
      $('#plagiarism_platform_info_container')
    )

    if (!submission.has_originality_score) {
      const resubmitUrl = SpeedgraderHelpers.plagiarismResubmitUrl(submission, anonymizableUserId)
      $('#plagiarism_resubmit_button').off('click')
      $('#plagiarism_resubmit_button').on('click', e => {
        SpeedgraderHelpers.plagiarismResubmitHandler(e, resubmitUrl)
      })
    }

    if (vericiteEnabled) {
      $vericiteScoreContainer = $grade_container.find('.turnitin_score_container').empty()
      $vericiteInfoContainer = $grade_container.find('.turnitin_info_container').empty()
      const assetString = `submission_${submission.id}`
      vericiteAsset =
        vericiteEnabled && submission.turnitin_data && submission.turnitin_data[assetString]
      // There might be a previous submission that was text_entry, but the
      // current submission is an upload. The vericite asset for the text
      // entry would still exist
      if (vericiteAsset && submission.submission_type === 'online_text_entry') {
        EG.populateVeriCite(
          submission,
          assetString,
          vericiteAsset,
          $vericiteScoreContainer,
          $vericiteInfoContainer,
          isMostRecent
        )
      }
    } else {
      // default to TII
      const $turnitinScoreContainer = $grade_container.find('.turnitin_score_container').empty()
      $turnitinInfoContainer = $grade_container.find('.turnitin_info_container').empty()
      const assetString = `submission_${submission.id}`
      turnitinAsset = null

      if (turnitinEnabled && submission.turnitin_data) {
        turnitinAsset =
          submission.turnitin_data[originalityReportSubmissionKey(submission)] ||
          submission.turnitin_data[assetString]
      }

      // There might be a previous submission that was text_entry, but the
      // current submission is an upload. The turnitin asset for the text
      // entry would still exist
      if (turnitinAsset && submission.submission_type === 'online_text_entry') {
        EG.populateTurnitin(
          submission,
          assetString,
          turnitinAsset,
          $turnitinScoreContainer,
          $turnitinInfoContainer,
          isMostRecent
        )
      }
    }

    let studentViewedAtHTML = ''

    // handle the files
    $submission_files_list.empty()
    $turnitinInfoContainer = $('#submission_files_container .turnitin_info_container').empty()
    $vericiteInfoContainer = $('#submission_files_container .turnitin_info_container').empty()
    $.each(submission.versioned_attachments || [], (i, a) => {
      const attachment: Attachment = a.attachment
      if (
        (attachment.crocodoc_url || attachment.canvadoc_url) &&
        EG.currentStudent.provisional_crocodoc_urls
      ) {
        const urlInfo = find(
          EG.currentStudent.provisional_crocodoc_urls,
          (url: ProvisionalCrocodocUrl) => url.attachment_id === attachment.id
        )
        // @ts-expect-error
        attachment.provisional_crocodoc_url = urlInfo.crocodoc_url
        // @ts-expect-error
        attachment.provisional_canvadoc_url = urlInfo.canvadoc_url
      } else {
        attachment.provisional_crocodoc_url = null
        attachment.provisional_canvadoc_url = null
      }
      if (
        attachment.crocodoc_url ||
        attachment.canvadoc_url ||
        isPreviewable(attachment.content_type)
      ) {
        inlineableAttachments.push(attachment)
      }

      if (!window.jsonData.anonymize_students || isAdmin) {
        studentViewedAtHTML = studentViewedAtTemplate({
          viewed_at: $.datetimeString(attachment.viewed_at),
        })
      }

      if (browserableCssClasses.test(attachment.mime_class)) {
        browserableAttachments.push(attachment)
      }
      const anonymizableSubmissionIdKey = isAnonymous ? 'anonymousId' : 'submissionId'
      const $submission_file = $submission_file_hidden
        .clone(true)
        .fillTemplateData({
          data: {
            [anonymizableSubmissionIdKey]: submission[anonymizableUserId],
            attachmentId: attachment.id,
            display_name: attachment.display_name,
            attachmentWorkflow: attachment.upload_status,
          },
          hrefValues: [anonymizableSubmissionIdKey, 'attachmentId'],
        })
        .appendTo($submission_files_list)
        .find('a.display_name')
        .data('attachment', attachment)
        .click(function (this: HTMLAnchorElement, event: JQuery.ClickEvent) {
          event.preventDefault()
          EG.loadSubmissionPreview($(this).data('attachment'), null)
          EG.updateWordCount(attachment.word_count)
        })
        .end()
        .find('a.submission-file-download')
        .bind('dragstart', function (this: HTMLAnchorElement, event: JQuery.DragStartEvent) {
          // check that event dataTransfer exists
          event.originalEvent?.dataTransfer &&
            // handle dragging out of the browser window only if it is supported.
            event.originalEvent?.dataTransfer.setData(
              'DownloadURL',
              `${attachment.content_type}:${attachment.filename}:${this.href}`
            )
        })
        .end()
      renderDeleteAttachmentLink($submission_file, attachment)
      $submission_file.show()
      const $turnitinScoreContainer = $submission_file.find('.turnitin_score_container')
      let assetString = `attachment_${attachment.id}`
      turnitinAsset =
        turnitinEnabled && submission.turnitin_data && submission.turnitin_data[assetString]
      if (turnitinAsset) {
        EG.populateTurnitin(
          submission,
          assetString,
          turnitinAsset,
          $turnitinScoreContainer,
          $turnitinInfoContainer,
          isMostRecent
        )
      }
      $vericiteScoreContainer = $submission_file.find('.turnitin_score_container')
      assetString = `attachment_${attachment.id}`
      vericiteAsset =
        vericiteEnabled && submission.turnitin_data && submission.turnitin_data[assetString]
      if (vericiteAsset) {
        EG.populateVeriCite(
          submission,
          assetString,
          vericiteAsset,
          $vericiteScoreContainer,
          $vericiteInfoContainer,
          isMostRecent
        )
      }

      renderProgressIcon(attachment)
    })
    $submission_attachment_viewed_at.html(studentViewedAtHTML)

    $submission_files_container.showIf(
      submission.submission_type === 'online_text_entry' ||
        Boolean(submission.versioned_attachments && submission.versioned_attachments.length > 0)
    )

    let preview_attachment: null | Attachment = null
    if (submission.submission_type !== 'discussion_topic') {
      preview_attachment = inlineableAttachments[0] || browserableAttachments[0]
    }

    // load up a preview of one of the attachments if we can.
    this.loadSubmissionPreview(preview_attachment, submission)
    renderSubmissionCommentsDownloadLink(submission)
    EG.updateWordCount(preview_attachment ? preview_attachment.word_count : submission.word_count)

    // if there is any submissions after this one, show a notice that they are not looking at the newest
    $submission_not_newest_notice.showIf(
      $submission_to_view.filter(':visible').find(':selected').nextAll().length
    )

    $submission_late_notice.showIf(submission.late)
    $full_width_container.removeClass('with_enrollment_notice')
    $enrollment_inactive_notice.showIf(
      some(
        window.jsonData.studentMap[this.currentStudent[anonymizableId]].enrollments,
        (enrollment: {workflow_state: string}) => {
          if (enrollment.workflow_state === 'inactive') {
            $full_width_container.addClass('with_enrollment_notice')
            return true
          }
          return false
        }
      )
    )

    const isConcluded = isStudentConcluded(
      window.jsonData.studentMap,
      this.currentStudent[anonymizableId],
      ENV.selected_section_id
    )
    $enrollment_concluded_notice.showIf(isConcluded)

    // because we make .submission absent in some tests
    const gradingPeriodId = (submissionHolder || {}).grading_period_id
    const gradingPeriod =
      // needs confirmation, but the API may only return a string type now
      typeof gradingPeriodId === 'string' || typeof gradingPeriodId === 'number'
        ? window.jsonData.gradingPeriods[gradingPeriodId]
        : undefined
    const isClosedForSubmission = !!gradingPeriod && gradingPeriod.is_closed
    selectors.get('#closed_gp_notice').showIf(isClosedForSubmission)
    SpeedgraderHelpers.setRightBarDisabled(isConcluded)
    EG.setGradeReadOnly(
      (typeof submissionHolder !== 'undefined' &&
        submissionHolder.submission_type === 'online_quiz') ||
        isConcluded ||
        (isClosedForSubmission && !isAdmin)
    )

    if (isConcluded || isClosedForSubmission) {
      $full_width_container.addClass('with_enrollment_notice')
    }

    const mountPoint = availableMountPointForStatusMenu()
    if (mountPoint) {
      const isInModeration = isModerated && !window.jsonData.grades_published_at
      const shouldRender = isMostRecent && !isClosedForSubmission && !isConcluded && !isInModeration
      const component = shouldRender ? statusMenuComponent(this.currentStudent.submission) : null
      renderStatusMenu(component, mountPoint)
    }

    EG.showDiscussion()
  },

  refreshSubmissionsToView() {
    let innerHTML
    let s: StudentWithSubmission['submission'] = this.currentStudent.submission
    let submissionHistory: SubmissionHistoryEntry[]
    let noSubmittedAt: string
    let selectedIndex: number

    if (s && s.submission_history && s.submission_history.length > 0) {
      submissionHistory = s.submission_history
      noSubmittedAt = I18n.t('no_submission_time', 'no submission time')
      selectedIndex = parseInt(
        String($('#submission_to_view').val() || submissionHistory.length - 1),
        10
      )
      const templateSubmissions = map(submissionHistory, (o: unknown, i: number) => {
        // The submission objects nested in the submission_history array
        // can have two different shapes, because the `this.currentStudent.submission`
        // can come from two different API endpoints.
        //
        // Shape one:
        //
        // ```
        // [{
        //   submission: {
        //     grade: 100,
        //     ...other submission keys
        //   }
        // }]
        // ```
        //
        // Shape two:
        //
        // ```
        // [{
        //   grade: 100,
        //   ...other submission keys
        // }]
        // ```
        //
        // This little dance here is to make sure we can accommodate both.
        if (Object.prototype.hasOwnProperty.call(o, 'submission')) {
          s = (o as StudentWithSubmission).submission
        } else {
          s = o as StudentWithSubmission['submission']
        }

        let grade

        if (s.grade && (s.grade_matches_current_submission || s.show_grade_in_dropdown)) {
          grade = GradeFormatHelper.formatGrade(s.grade)
        }
        return {
          value: i,
          late_policy_status: EG.currentStudent.submission.late_policy_status,
          custom_grade_status_name: (ENV.custom_grade_statuses as GradeStatusUnderscore[])
            ?.find(status => status.id === s.custom_grade_status_id)
            ?.name.toUpperCase(),
          custom_grade_status_id: s.custom_grade_status_id,
          late: s.late,
          missing: s.missing,
          excused: EG.currentStudent.submission.excused,
          selected: selectedIndex === i,
          proxy_submitter: s.proxy_submitter,
          proxy_submitter_label_text: s.proxy_submitter ? ` by ${s.proxy_submitter}` : null,
          submittedAt: $.datetimeString(s.submitted_at) || noSubmittedAt,
          grade,
        }
      })
      innerHTML = submissionsDropdownTemplate({
        showSubmissionStatus: !window.jsonData.anonymize_students || isAdmin,
        singleSubmission: submissionHistory.length === 1,
        submissions: templateSubmissions,
        linkToQuizHistory: window.jsonData.too_many_quiz_submissions,
        quizHistoryHref: replaceTags(ENV.quiz_history_url, {
          user_id: this.currentStudent[anonymizableId],
        }),
      })
    }
    $multiple_submissions.html(innerHTML || '')
    StatusPill.renderPills(ENV.custom_grade_statuses)
  },

  showSubmissionDetails() {
    // if there is a submission
    const currentSubmission = this.currentStudent.submission
    if (currentSubmission && currentSubmission.workflow_state !== 'unsubmitted') {
      this.refreshSubmissionsToView()
      let index = currentSubmission.submission_history.length - 1

      if (EG.hasOwnProperty('initialVersion')) {
        if (Number(EG.initialVersion) >= 0 && Number(EG.initialVersion) <= index) {
          index = EG.initialVersion as number
          currentSubmission.currentSelectedIndex = index
        }
        delete EG.initialVersion
      }

      $(`#submission_to_view option:eq(${index})`).prop('selected', true)
      $submission_details.show()
      if (allowsReassignment(currentSubmission)) {
        $reassign_assignment.show()
      } else {
        $reassign_assignment.hide()
      }
    } else if (
      currentSubmission &&
      currentSubmission.submission_history &&
      currentSubmission.submission_history.length > 0 &&
      currentSubmission.workflow_state === 'unsubmitted'
    ) {
      const index = currentSubmission.submission_history.length - 1
      const missing =
        currentSubmission.submission_history[index].submission?.missing ||
        currentSubmission.submission_history[index]?.missing
      const late =
        currentSubmission.submission_history[index].submission?.late ||
        currentSubmission.submission_history[index]?.late
      const extended =
        currentSubmission.submission_history[index].submission?.late_policy_status === 'extended' ||
        currentSubmission.submission_history[index]?.late_policy_status === 'extended'
      const customStatus =
        !!currentSubmission.submission_history[index].submission?.custom_grade_status_id ||
        !!currentSubmission.submission_history[index]?.custom_grade_status_id
      if (missing || late || extended || customStatus) {
        this.refreshSubmissionsToView()
        $submission_details.show()
      } else {
        $submission_details.hide()
      }
      $reassign_assignment.hide()
    } else {
      // there's no submission
      $submission_details.hide()
      $reassign_assignment.hide()
    }
    this.handleSubmissionSelectionChange()
  },

  updateStatsInHeader() {
    let outOf = ''
    let percent
    const gradedStudents = $.grep(
      window.jsonData.studentsWithSubmissions,
      (s: StudentWithSubmission) =>
        s.submission_state === 'graded' || s.submission_state === 'not_gradeable'
    )

    $x_of_x_students.text(
      I18n.t('%{x}/%{y}', {
        x: I18n.n(EG.currentIndex() + 1),
        y: I18n.n(this.totalStudentCount()),
      })
    )
    $('#gradee').text(gradeeLabel)

    const scores = $.map(gradedStudents, s => s.submission.score)

    if (scores.length) {
      // if there are some submissions that have been graded.
      $average_score_wrapper.show()
      const avg = function (arr: number[]) {
        let sum = 0
        for (let i = 0, j = arr.length; i < j; i++) {
          sum += arr[i]
        }
        return sum / arr.length
      }
      const roundWithPrecision = function (number: number, precision: number) {
        precision = Math.abs(parseInt(String(precision), 10)) || 0
        const coefficient = 10 ** precision
        return Math.round(number * coefficient) / coefficient
      }

      if (window.jsonData.points_possible) {
        percent = I18n.n(Math.round(100 * (avg(scores) / window.jsonData.points_possible)), {
          percentage: true,
        })

        outOf = [' / ', I18n.n(window.jsonData.points_possible), ' (', percent, ')'].join('')
      }
      $average_score.text([I18n.n(roundWithPrecision(avg(scores), 2)) + outOf].join(''))
    } else {
      // there are no submissions that have been graded.
      $average_score_wrapper.hide()
    }

    $grded_so_far.text(
      I18n.t('portion_graded', '%{x}/%{y}', {
        x: I18n.n(gradedStudents.length),
        y: I18n.n(window.jsonData.studentsWithSubmissions.length),
      })
    )
  },

  totalStudentCount() {
    if (sectionToShow) {
      return filter(window.jsonData.studentsWithSubmissions, (student: StudentWithSubmission) =>
        includes(student.section_ids, sectionToShow)
      ).length
    } else {
      return window.jsonData.studentsWithSubmissions.length
    }
  },

  loadSubmissionPreview(attachment: Attachment | null, submission: HistoricalSubmission | null) {
    clearInterval(sessionTimer)
    $submissions_container.children().hide()
    $('.speedgrader_alert').hide()
    if (
      !this.currentStudent.submission ||
      !this.currentStudent.submission.submission_type ||
      this.currentStudent.submission.workflow_state === 'unsubmitted'
    ) {
      $this_student_does_not_have_a_submission.show()
      if (!ENV.SINGLE_NQ_SESSION_ENABLED || !externalToolLaunchOptions.singleLtiLaunch) {
        this.emptyIframeHolder()
      }
    } else if (
      this.currentStudent.submission &&
      this.currentStudent.submission.submitted_at &&
      window.jsonData.context.quiz &&
      window.jsonData.context.quiz.anonymous_submissions
    ) {
      $this_student_has_a_submission.show()
    } else if (attachment) {
      this.renderAttachment(attachment)
    } else if (submission && submission.submission_type === 'basic_lti_launch') {
      if (
        !ENV.SINGLE_NQ_SESSION_ENABLED ||
        !externalToolLoaded ||
        !externalToolLaunchOptions.singleLtiLaunch
      ) {
        this.renderLtiLaunch($iframe_holder, ENV.lti_retrieve_url, submission)
        externalToolLoaded = true
      } else {
        QuizzesNextSpeedGrading.postChangeSubmissionVersionMessage($iframe_holder, submission)
        $iframe_holder.show()
      }
    } else {
      this.renderSubmissionPreview()
    }
  },

  emptyIframeHolder(elem?: JQuery) {
    elem = elem || $iframe_holder
    elem.empty()
  },

  // load in the iframe preview.  if we are viewing a past version of the file pass the version to preview in the url
  renderSubmissionPreview(domElement = 'iframe') {
    // TODO: this is duplicate code from line 1972 and should be removed
    if (!this.currentStudent.submission) {
      $this_student_does_not_have_a_submission.show()
      return
    }
    this.emptyIframeHolder()
    const {context_id: courseId} = window.jsonData
    const {assignment_id: assignmentId} = this.currentStudent.submission
    const anonymizableSubmissionId = this.currentStudent.submission[anonymizableUserId]
    const resourceSegment = isAnonymous ? 'anonymous_submissions' : 'submissions'
    const iframePreviewVersion = SpeedgraderHelpers.iframePreviewVersion(
      this.currentStudent.submission
    )
    const hideStudentNames = utils.shouldHideStudentNames() ? '&hide_student_name=1' : ''
    const queryParams = `${iframePreviewVersion}${hideStudentNames}`
    const src = `/courses/${courseId}/assignments/${assignmentId}/${resourceSegment}/${anonymizableSubmissionId}?preview=true${queryParams}`
    const iframe = SpeedgraderHelpers.buildIframe(
      htmlEscape(src),
      {frameborder: 0, allowfullscreen: true},
      domElement
    )
    $iframe_holder.html(iframe).show()
  },

  renderLtiLaunch($div: JQuery, urlBase: string, submission: HistoricalSubmission) {
    let externalToolUrl = submission.external_tool_url || submission.url

    if (ENV.NQ_GRADE_BY_QUESTION_ENABLED && window.jsonData.quiz_lti && externalToolUrl) {
      const quizToolUrl = new URL(externalToolUrl)
      quizToolUrl.searchParams.set('grade_by_question_enabled', String(ENV.GRADE_BY_QUESTION))
      externalToolUrl = quizToolUrl.href
    }

    urlBase += SpeedgraderHelpers.resourceLinkLookupUuidParam(submission)

    this.emptyIframeHolder()
    const launchUrl = `${urlBase}&url=${encodeURIComponent(externalToolUrl || '')}`
    const iframe = SpeedgraderHelpers.buildIframe(htmlEscape(launchUrl), {
      className: 'tool_launch',
      allow: iframeAllowances(),
      allowfullscreen: true,
    })
    $div.html(iframe).show()
  },

  generateWarningTimings(numHours: number): number[] {
    const sessionLimit = numHours * 60 * 60 * 1000
    return [
      sessionLimit - 10 * 60 * 1000,
      sessionLimit - 5 * 60 * 1000,
      sessionLimit - 2 * 60 * 1000,
      sessionLimit - 1 * 60 * 1000,
    ]
  },

  displayExpirationWarnings(aggressiveWarnings, numHours, message) {
    const start = new Date()
    const sessionLimit = numHours * 60 * 60 * 1000
    sessionTimer = window.setInterval(() => {
      const elapsed = new Date().getTime() - start.getTime()
      if (elapsed > sessionLimit) {
        SpeedgraderHelpers.reloadPage()
      } else if (elapsed > aggressiveWarnings[0]) {
        $.flashWarning(message)
        aggressiveWarnings.shift()
      }
    }, 1000)
  },

  renderAttachment(attachment: Attachment) {
    // show the crocodoc doc if there is one
    // then show the google attachment if there is one
    // then show the first browser viewable attachment if there is one
    this.emptyIframeHolder()
    let previewOptions: DocumentPreviewOptions = {
      height: '100%',
      id: 'speedgrader_iframe',
      mimeType: attachment.content_type,
      attachment_id: attachment.id,
      submission_id: this.currentStudent.submission.id,
      attachment_view_inline_ping_url: attachment.view_inline_ping_url,
      attachment_preview_processing:
        attachment.workflow_state === 'pending_upload' ||
        attachment.workflow_state === 'processing',
    }

    if (
      !attachment.hijack_crocodoc_session &&
      attachment.submitted_to_crocodoc &&
      !attachment.crocodoc_url
    ) {
      $('#crocodoc_pending').show()
    }
    const canvadocMessage = I18n.t(
      'canvadoc_expiring',
      'Your Canvas DocViewer session is expiring soon.  Please ' +
        'reload the window to avoid losing any work.'
    )

    if (attachment.crocodoc_url) {
      if (!attachment.hijack_crocodoc_session) {
        const crocodocMessage = I18n.t(
          'crocodoc_expiring',
          'Your Crocodoc session is expiring soon.  Please reload ' +
            'the window to avoid losing any work.'
        )
        const aggressiveWarnings = this.generateWarningTimings(1)
        this.displayExpirationWarnings(aggressiveWarnings, 1, crocodocMessage)
      } else {
        const aggressiveWarnings = this.generateWarningTimings(10)
        this.displayExpirationWarnings(aggressiveWarnings, 10, canvadocMessage)
      }

      $iframe_holder.show()
      loadDocPreview(
        $iframe_holder[0],
        $.extend(previewOptions, {
          crocodoc_session_url: attachment.provisional_crocodoc_url || attachment.crocodoc_url,
        })
      )
    } else if (attachment.canvadoc_url) {
      const aggressiveWarnings = this.generateWarningTimings(10)
      this.displayExpirationWarnings(aggressiveWarnings, 10, canvadocMessage)

      $iframe_holder.show()
      loadDocPreview(
        $iframe_holder[0],
        $.extend(previewOptions, {
          canvadoc_session_url: attachment.provisional_canvadoc_url || attachment.canvadoc_url,
          iframe_min_height: 0,
        })
      )
    } else if (!INST?.disableGooglePreviews && isPreviewable(attachment.content_type)) {
      $no_annotation_warning.show()

      const currentStudentIDAsOfAjaxCall = this.currentStudent[anonymizableId]
      previewOptions = $.extend(previewOptions, {
        ajax_valid: () => currentStudentIDAsOfAjaxCall === this.currentStudent[anonymizableId],
      })
      $iframe_holder.show()
      loadDocPreview($iframe_holder[0], previewOptions)
    } else if (browserableCssClasses.test(attachment.mime_class)) {
      // xsslint safeString.identifier iframeHolderContents
      const iframeHolderContents = this.attachmentIframeContents(attachment)
      $iframe_holder.html(iframeHolderContents).show()
    }
  },

  attachmentIframeContents(attachment: Attachment, domElement = 'iframe'): string {
    let contents
    const href = $submission_file_hidden.find('.display_name').attr('href') as string
    const genericSrc = unescape(href)

    const anonymizableSubmissionIdToken = isAnonymous ? 'anonymousId' : 'submissionId'
    const src = genericSrc
      .replace(
        `{{${anonymizableSubmissionIdToken}}}`,
        this.currentStudent.submission[anonymizableUserId] || ''
      )
      .replace('{{attachmentId}}', attachment.id)

    if (attachment.mime_class === 'image') {
      contents = `<img src="${htmlEscape(src)}" style="max-width:100%;max-height:100%;">`
    } else {
      const options: {
        frameborder: number
        allowfullscreen: boolean
        className?: string
      } = {frameborder: 0, allowfullscreen: true}
      if (attachment.mime_class === 'html') {
        options.className = 'attachment-html-iframe'
      }
      contents = SpeedgraderHelpers.buildIframe(htmlEscape(src), options, domElement)
    }

    return contents
  },

  showRubric({validateEnteredData = true} = {}) {
    const selectMenu = selectors.get('#rubric_assessments_select')
    // if this has some rubric_assessments
    if (window.jsonData.rubric_association) {
      ENV.RUBRIC_ASSESSMENT.assessment_user_id = this.currentStudent[anonymizableId]

      const isModerator = ENV.grading_role === 'moderator'
      const selectMenuOptions: {id: string; name: string | null}[] = []

      const assessmentsByMe = EG.currentStudent.rubric_assessments.filter(assessment =>
        assessmentBelongsToCurrentUser(assessment)
      )
      if (assessmentsByMe.length > 0) {
        assessmentsByMe.forEach(assessment => {
          const displayName = isModerator ? customProvisionalGraderLabel : assessment.assessor_name
          selectMenuOptions.push({id: assessment.id, name: displayName})
        })
      } else if (isModerator) {
        // Moderators can create a custom assessment if they don't have one
        selectMenuOptions.push({id: '', name: customProvisionalGraderLabel})
      }

      const assessmentsByOthers = EG.currentStudent.rubric_assessments.filter(
        assessment => !assessmentBelongsToCurrentUser(assessment)
      )

      assessmentsByOthers.forEach(assessment => {
        // Display anonymous graders as "Grader 1 Rubric" (but don't use the
        // "Rubric" suffix for named graders)
        let displayName = assessment.assessor_name
        if (anonymousGraders) {
          displayName += ' Rubric'
        }

        selectMenuOptions.push({id: assessment.id, name: displayName})
      })

      selectMenu.find('option').remove()
      selectMenuOptions.forEach(option => {
        selectMenu.append(
          `<option value="${htmlEscape(option.id)}">${htmlEscape(option?.name || '')}</option>`
        )
      })

      let idToSelect = ''
      if (assessmentsByMe.length > 0) {
        idToSelect = assessmentsByMe[0].id
      } else {
        const gradingAssessment = EG.currentStudent.rubric_assessments.find(
          assessment => assessment.assessment_type === 'grading'
        )

        if (gradingAssessment) {
          idToSelect = gradingAssessment.id
        }
      }

      selectMenu.val(idToSelect)
      $('#rubric_assessments_list').showIf(isModerator || selectMenu.find('option').length > 1)

      handleSelectedRubricAssessmentChanged({validateEnteredData})
    }
  },

  renderCommentAttachment(
    comment: SubmissionComment,
    attachmentData: AttachmentData | Attachment,
    incomingOpts
  ) {
    const defaultOpts = {
      commentAttachmentBlank: $comment_attachment_blank,
    }
    const opts = {...defaultOpts, ...incomingOpts}
    const attachment = 'attachment' in attachmentData ? attachmentData.attachment : attachmentData
    let attachmentElement = opts.commentAttachmentBlank.clone(true)

    attachment.comment_id = comment.id
    attachment.submitter_id = EG.currentStudent[anonymizableId]

    attachmentElement = attachmentElement.fillTemplateData({
      data: attachment,
      hrefValues: ['comment_id', 'id', 'submitter_id'],
    })
    attachmentElement.find('a').addClass(attachment.mime_class)

    return attachmentElement
  },

  addCommentDeletionHandler(commentElement, comment) {
    const that = this

    // this is really poorly decoupled but over in
    // speed_grader.html.erb these rubricAssessment. variables are
    // set.  what this is saying is: if I am able to grade this
    // assignment (I am administrator in the course) or if I wrote
    // this comment... and if the student isn't concluded
    const isConcluded = isStudentConcluded(
      window.jsonData.studentMap,
      EG.currentStudent[anonymizableId],
      ENV.selected_section_id
    )
    const commentIsDeleteableByMe =
      (ENV.RUBRIC_ASSESSMENT.assessment_type === 'grading' ||
        ENV.RUBRIC_ASSESSMENT.assessor_id === comment[anonymizableAuthorId]) &&
      !isConcluded

    commentElement
      .find('.delete_comment_link')
      .click(function (this: HTMLElement, _event) {
        $(this)
          .parents('.comment')
          .confirmDelete({
            url: `/submission_comments/${comment.id}`,
            message: I18n.t('Are you sure you want to delete this comment?'),
            success(_data: unknown) {
              let updatedComments = []

              // Let's remove this comment from the client-side cache
              if (
                that.currentStudent.submission &&
                that.currentStudent.submission.submission_comments
              ) {
                updatedComments = reject(
                  that.currentStudent.submission.submission_comments,
                  (item: SubmissionComment) => {
                    const submissionComment = item.submission_comment || item
                    return submissionComment.id === comment.id
                  }
                )

                that.currentStudent.submission.submission_comments = updatedComments
              }

              // and also remove it from the DOM
              $(this).slideUp(function () {
                $(this).remove()
              })
            },
          })
      })
      .showIf(commentIsDeleteableByMe)
  },

  addCommentSubmissionHandler(commentElement, comment) {
    const that = this

    const isConcluded = isStudentConcluded(
      window.jsonData.studentMap,
      EG.currentStudent[anonymizableId],
      ENV.selected_section_id
    )
    commentElement
      .find('.submit_comment_button')
      .click(_event => {
        let updateUrl = ''
        let updateData = {}
        let updateAjaxOptions = {}
        const commentUpdateSucceeded = function (data: {submission_comment: SubmissionComment}) {
          let updatedComments = []
          const $replacementComment = that.renderComment(data.submission_comment)
          // @ts-expect-error
          $replacementComment.show()
          // @ts-expect-error
          commentElement.replaceWith($replacementComment)

          updatedComments = map(
            that.currentStudent.submission.submission_comments,
            (item: SubmissionComment) => {
              const submissionComment = item.submission_comment || item

              if (submissionComment.id === comment.id) {
                return data.submission_comment
              }

              return submissionComment
            }
          )

          that.currentStudent.submission.submission_comments = updatedComments
        }
        const commentUpdateFailed = function (_jqXH: JQuery.jqXHR<any>, _textStatus: string) {
          $.flashError(I18n.t('Failed to submit draft comment'))
        }
        // eslint-disable-next-line no-alert
        const confirmed = window.confirm(I18n.t('Are you sure you want to submit this comment?'))

        if (confirmed) {
          updateUrl = `/submission_comments/${comment.id}`
          updateData = {submission_comment: {draft: 'false'}}
          updateAjaxOptions = {url: updateUrl, data: updateData, dataType: 'json', type: 'PATCH'}

          $.ajax(updateAjaxOptions).done(commentUpdateSucceeded).fail(commentUpdateFailed)
        }
      })
      .showIf(comment.publishable && !isConcluded)
  },

  renderComment(commentData: SubmissionComment, incomingOpts?: CommentRenderingOptions) {
    const self = this
    let comment = commentData
    let spokenComment = ''
    let submitCommentButtonText = ''
    let deleteCommentLinkText = ''
    let hideStudentName = false
    const defaultOpts: CommentRenderingOptions = {
      commentBlank: $comment_blank,
      commentAttachmentBlank: $comment_attachment_blank,
    }
    const opts: CommentRenderingOptions = {...defaultOpts, ...incomingOpts}
    let commentElement = opts.commentBlank.clone(true)

    // Serialization seems to have changed... not sure if it's changed everywhere, though...
    if (comment.submission_comment) {
      // eslint-disable-next-line no-console
      console.warn('SubmissionComment serialization has changed')
      comment = commentData.submission_comment
    }

    // don't render private comments when viewing a group assignment
    if (!comment.group_comment_id && window.jsonData.GROUP_GRADING_MODE) return undefined

    // For screenreaders
    spokenComment = comment.comment.replace(/\s+/, ' ')

    comment.posted_at = $.datetimeString(comment.created_at)

    hideStudentName =
      opts.hideStudentNames && window.jsonData.studentMap[comment[anonymizableAuthorId]]
    if (hideStudentName) {
      comment.author_name = anonymousName(window.jsonData.studentMap[comment[anonymizableAuthorId]])
    }
    // anonymous commentors
    if (comment.author_name == null) {
      const {provisional_grade_id} = (EG.currentStudent.submission.provisional_grades || []).find(
        (pg: ProvisionalGrade) => pg.anonymous_grader_id === comment.anonymous_id
      ) as ProvisionalGrade
      if (
        provisionalGraderDisplayNames == null ||
        provisionalGraderDisplayNames[provisional_grade_id] == null
      ) {
        this.setupProvisionalGraderDisplayNames()
      }
      comment.author_name = provisionalGraderDisplayNames[provisional_grade_id]
    }
    commentElement = commentElement.fillTemplateData({data: comment})

    if (comment.draft) {
      commentElement.addClass('draft')
      submitCommentButtonText = I18n.t('Submit comment: %{commentText}', {
        commentText: spokenComment,
      })
      commentElement.find('.submit_comment_button').attr('aria-label', submitCommentButtonText)
    } else {
      commentElement.find('.draft-marker').remove()
      commentElement.find('.submit_comment_button').remove()
    }

    commentElement.find('span.comment').html(htmlEscape(comment.comment).replace(/\n/g, '<br />'))

    deleteCommentLinkText = I18n.t('Delete comment: %{commentText}', {commentText: spokenComment})
    commentElement.find('.delete_comment_link .screenreader-only').text(deleteCommentLinkText)

    if (comment.avatar_path && !hideStudentName) {
      commentElement.find('.avatar').attr('src', comment.avatar_path).show()
    }

    if (comment.media_comment_type && comment.media_comment_id) {
      commentElement.find('.play_comment_link').data(comment).show()
    }

    // TODO: Move attachment handling into a separate function
    $.each(
      comment.cached_attachments || comment.attachments || [],
      (_index, attachment: Attachment) => {
        const attachmentElement = self.renderCommentAttachment(comment, attachment, opts)

        commentElement.find('.comment_attachments').append($(attachmentElement).show())
      }
    )

    /* Submit a comment and Delete a comment listeners */

    this.addCommentDeletionHandler(commentElement, comment)
    this.addCommentSubmissionHandler(commentElement, comment)

    return commentElement
  },

  currentDisplayedSubmission(): HistoricalSubmission {
    const displayedHistory =
      typeof this.currentStudent.submission?.currentSelectedIndex === 'number'
        ? this.currentStudent.submission?.submission_history?.[
            this.currentStudent.submission.currentSelectedIndex
          ]
        : undefined
    return displayedHistory?.submission || this.currentStudent.submission
  },

  showDiscussion() {
    const that = this
    const commentRenderingOptions: CommentRenderingOptions = {
      hideStudentNames: utils.shouldHideStudentNames(),
      commentBlank: $comment_blank,
      commentAttachmentBlank: $comment_attachment_blank,
    }

    $comments.html('')

    const submission = EG.currentDisplayedSubmission()
    if (this.currentStudent.submission && this.currentStudent.submission.submission_comments) {
      $.each(this.currentStudent.submission.submission_comments, (i, comment) => {
        if (ENV.group_comments_per_attempt) {
          // Due to the fact that the unsubmitted attempt 0 submission is no longer viewable
          // from the submission histories after the attempt 1 submission has been submitted,
          // treat comments from attempt 0 and attempt 1 as if they were both on attempt 1.
          if ((comment.attempt || 1) !== (submission.attempt || 1)) {
            return
          }
        }

        const commentElement = that.renderComment(comment, commentRenderingOptions)

        if (commentElement) {
          $comments.append($(commentElement).show())
          const $commentLink = $comments.find('.play_comment_link').last()
          $commentLink.data('author', comment.author_name)
          // @ts-expect-error
          $commentLink.data('created_at', comment.posted_at)
          $commentLink.mediaCommentThumbnail('normal')
        }
      })
    }
    $comments.scrollTop(9999999) // the scrollTop part forces it to scroll down to the bottom so it shows the most recent comment.
  },

  revertFromFormSubmit: ({
    draftComment = null,
    errorSubmitting = false,
  }: {
    draftComment?: null | boolean
    errorSubmitting?: boolean
  } = {}) => {
    // This is to continue existing behavior of creating finalized comments by default
    if (draftComment === undefined) {
      draftComment = false
    }

    EG.showDiscussion()
    renderCommentTextArea()
    $add_a_comment.find(':input').prop('disabled', false)

    if (draftComment) {
      // Show a different message when auto-saving a draft comment
      $comment_saved.show()
      $comment_saved_message.attr('tabindex', -1).focus()
    } else if (!errorSubmitting) {
      $comment_submitted.show()
      $comment_submitted_message.attr('tabindex', -1).focus()
    }
    $add_a_comment_submit_button.text(I18n.t('submit', 'Submit'))
    EG.resetReassignButton()
  },

  reassignAssignment() {
    if (reassignAssignmentInProgress) {
      return false
    }
    reassignAssignmentInProgress = true
    const url = `${assignmentUrl}/${isAnonymous ? 'anonymous_' : ''}submissions/${
      EG.currentStudent[anonymizableId]
    }/reassign`
    const method = 'PUT'
    const formData = {}

    function formSuccess(studentId: string) {
      window.jsonData.submissionsMap[studentId].redo_request = true
      // Check if we're still on the same student submission
      if (studentId === EG.currentStudent?.id) {
        $reassign_assignment.text(I18n.t('Reassigned'))
        $reassign_assignment.parent().attr('title', I18n.t('Assignment is reassigned.'))
      }
      reassignAssignmentInProgress = false
      $reassignment_complete.show()
      $reassignment_complete.attr('tabindex', -1).focus()
    }

    function formError(data: GradingError, studentId: string) {
      EG.handleGradingError(data)
      // Check if we're still on the same student submission
      if (studentId === EG.currentStudent?.id) {
        $reassign_assignment.text(I18n.t('Reassign Assignment'))
        $reassign_assignment.removeAttr('disabled')
      }
      reassignAssignmentInProgress = false
    }
    $reassign_assignment.prop('disabled', true)
    $reassign_assignment.text(I18n.t('Reassigning ...'))
    $.ajaxJSON(
      url,
      method,
      formData,
      () => formSuccess(EG.currentStudent.id),
      (data: GradingError) => formError(data, EG.currentStudent.id),
      {skipDefaultError: true}
    )
  },

  addSubmissionComment(draftComment) {
    // Avoid submitting additional comments if a request is already in progress.
    // This can happen if the user submits a comment and then switches students
    // (which attempts to save a draft comment) before the request finishes.
    if (commentSubmissionInProgress) {
      return false
    }

    // This is to continue existing behavior of creating finalized comments by default
    if (draftComment === undefined) {
      draftComment = false
    }

    $comment_submitted.hide()
    $comment_saved.hide()
    if (
      !$.trim($add_a_comment_textarea.val() as string).length &&
      !$('#media_media_recording').data('comment_id') &&
      !$add_a_comment.find("input[type='file']:visible").length
    ) {
      // that means that they did not type a comment, attach a file or record any media. so dont do anything.
      return false
    }

    commentSubmissionInProgress = true
    const url = `${assignmentUrl}/${isAnonymous ? 'anonymous_' : ''}submissions/${
      EG.currentStudent[anonymizableId]
    }`
    const method = 'PUT'
    const formData = {
      'submission[assignment_id]': window.jsonData.id,
      'submission[group_comment]': $('#submission_group_comment').prop('checked') ? '1' : '0',
      'submission[comment]': $add_a_comment_textarea.val(),
      'submission[draft_comment]': draftComment,
      [`submission[${anonymizableId}]`]: EG.currentStudent[anonymizableId],
    }

    if (ENV.group_comments_per_attempt) {
      // @ts-expect-error
      formData['submission[attempt]'] = EG.currentDisplayedSubmission().attempt
    }

    if ($('#media_media_recording').data('comment_id')) {
      $.extend(formData, {
        'submission[media_comment_type]': $('#media_media_recording').data('comment_type'),
        'submission[media_comment_id]': $('#media_media_recording').data('comment_id'),
      })
    }
    if (ENV.grading_role === 'moderator' || ENV.grading_role === 'provisional_grader') {
      formData['submission[provisional]'] = true
    }

    function formSuccess(
      submissions: {
        submission: Submission
      }[]
    ) {
      $.each(submissions, function () {
        EG.setOrUpdateSubmission(this.submission)
      })
      EG.revertFromFormSubmit({draftComment})
      window.setTimeout(() => {
        $rightside_inner.scrollTo($rightside_inner[0].scrollHeight, 500)
      })
      commentSubmissionInProgress = false
    }

    const formError = (
      data: GradingError,
      _xhr: XMLHttpRequest,
      _textStatus: string,
      _errorThrown: Error
    ) => {
      EG.handleGradingError(data)
      EG.revertFromFormSubmit({errorSubmitting: true})
      commentSubmissionInProgress = false
    }

    if ($add_a_comment.find("input[type='file']:visible").length) {
      $.ajaxJSONFiles(
        `${url}.text`,
        method,
        formData,
        $add_a_comment.find("input[type='file']:visible"),
        formSuccess,
        formError
      )
    } else {
      $.ajaxJSON(url, method, formData, formSuccess, formError)
    }

    $('#comment_attachments').empty()
    $add_a_comment.find(':input').prop('disabled', true)
    $add_a_comment_submit_button.text(I18n.t('buttons.submitting', 'Submitting...'))
    hideMediaRecorderContainer()
  },

  setOrUpdateSubmission(submission) {
    // find the student this submission belongs to and update their
    // submission with this new one, if they dont have a submission,
    // set this as their submission.
    const student = window.jsonData.studentMap[submission[anonymizableUserId]]
    if (!student) return

    student.submission = student.submission || {}

    // stuff that comes back from ajax doesnt have a submission history but handleSubmissionSelectionChange
    // depends on it being there. so mimic it.
    let historyIndex =
      student.submission?.submission_history?.findIndex(
        (history: {submission?: Submission; attempt?: number | null}) => {
          const historySubmission = history.submission || history
          if (historySubmission.attempt === undefined) {
            return false
          }
          return historySubmission.attempt === submission.attempt
        }
      ) || 0
    const foundMatchingSubmission = historyIndex !== -1
    historyIndex = historyIndex === -1 ? 0 : historyIndex

    if (typeof submission.submission_history === 'undefined') {
      submission.submission_history = Array.from({length: historyIndex + 1})
      submission.submission_history[historyIndex] = {submission: $.extend(true, {}, submission)}
    }

    // update the nested submission in submission_history if needed, assuming we
    // could map the submission we got to a specific attempt (notably, with
    // Quizzes.Next submissions and possibly other LTIs we don't get an
    // "attempt" field)
    if (
      foundMatchingSubmission &&
      student.submission?.submission_history?.[historyIndex]?.submission
    ) {
      const versionedAttachments =
        submission.submission_history[historyIndex].submission?.versioned_attachments || []
      submission.submission_history[historyIndex].submission = $.extend(
        true,
        {},
        {
          ...submission,
          versioned_attachments: versionedAttachments,
        }
      )
    }

    $.extend(true, student.submission, submission)

    student.submission_state = SpeedgraderHelpers.submissionState(student, ENV.grading_role)
    if (ENV.grading_role === 'moderator') {
      // sync with current provisional grade
      let prov_grade
      if (this.current_prov_grade_index === 'final') {
        prov_grade = student.submission.final_provisional_grade
      } else if (typeof this.current_prov_grade_index !== 'undefined') {
        prov_grade =
          student.submission.provisional_grades &&
          student.submission.provisional_grades[this.current_prov_grade_index]
      }
      if (prov_grade) {
        prov_grade.score = submission.score
        prov_grade.grade = submission.grade
        prov_grade.rubric_assessments = student.rubric_assessments
        prov_grade.submission_comments = submission.submission_comments
      }
    }

    renderPostGradesMenu(EG)

    return student
  },

  // If the second argument is passed as true, the grade used will
  // be the existing score from the previous submission.  This
  // should only be called from the anonymous function attached so
  // #submit_same_score.
  handleGradeSubmit(e, use_existing_score: boolean) {
    if (
      isStudentConcluded(
        window.jsonData.studentMap,
        EG.currentStudent[anonymizableId],
        ENV.selected_section_id
      )
    ) {
      EG.showGrade()
      return
    }

    const url = ENV.update_submission_grade_url
    const method = 'POST'
    const formData = {
      'submission[assignment_id]': window.jsonData.id,
      [`submission[${anonymizableUserId}]`]: EG.currentStudent[anonymizableId],
      'submission[graded_anonymously]': isAnonymous ? true : utils.shouldHideStudentNames(),
      originator: 'speed_grader',
    }

    const grade = SpeedgraderHelpers.determineGradeToSubmit(
      use_existing_score,
      EG.currentStudent,
      $grade
    )

    const isInModeration = isModerated && !window.jsonData.grades_published_at
    if (!isInModeration) {
      updateSubmissionAndPageEffects()
    }

    if (ENV.assignment_missing_shortcut && String(grade).toUpperCase() === 'MI') {
      if (EG.currentStudent.submission.late_policy_status !== 'missing') {
        updateSubmissionAndPageEffects({latePolicyStatus: 'missing'})
      }
      return
    } else if (String(grade).toUpperCase() === 'EX') {
      formData['submission[excuse]'] = true
    } else if (unexcuseSubmission(grade, EG.currentStudent.submission, window.jsonData)) {
      formData['submission[excuse]'] = false
    } else if (use_existing_score) {
      // If we're resubmitting a score, pass it as a raw score not grade.
      // This allows percentage grading types to be handled correctly.
      formData['submission[score]'] = grade
    } else {
      // Any manually entered grade is a grade.
      const formattedGrade = EG.formatGradeForSubmission(grade)

      if (formattedGrade === 'NaN') {
        return $.flashError(I18n.t('Invalid Grade'))
      }

      formData['submission[grade]'] = formattedGrade
    }
    if (ENV.grading_role === 'moderator' || ENV.grading_role === 'provisional_grader') {
      formData['submission[provisional]'] = true
    }

    const submissionSuccess = (
      submissions: {
        submission: Submission
        score: number | null
      }[]
    ) => {
      const pointsPossible = window.jsonData.points_possible
      const score = submissions[0].submission.score

      if (!submissions[0].submission.excused) {
        const outlierScoreHelper = new OutlierScoreHelper(score, pointsPossible)
        if (outlierScoreHelper.hasWarning()) {
          $.flashWarning(outlierScoreHelper.warningMessage())
        }
      }

      $.each(submissions, function () {
        // setOrUpdateSubmission returns the student it just updated.
        // This is only operating on a subset of people, so it should
        // be fairly fast to call updateSelectMenuStatus for each one.
        const student = EG.setOrUpdateSubmission(this.submission)
        EG.updateSelectMenuStatus(student)
      })
      EG.refreshSubmissionsToView()
      $multiple_submissions.change()
      EG.showGrade()

      if (ENV.grading_role === 'moderator' && currentStudentProvisionalGrades().length > 0) {
        // This is the ID of the possibly-new grade that the server returned
        const newProvisionalGradeId = submissions[0].submission.provisional_grade_id
        const existingGrade = currentStudentProvisionalGrades().find(
          provisionalGrade => provisionalGrade.provisional_grade_id === newProvisionalGradeId
        )

        // If it's not a new grade but an existing one, update the grade to match
        if (existingGrade) {
          existingGrade.grade = grade
          existingGrade.score = score
        }

        if (ENV.final_grader_id === ENV.current_user_id) {
          EG.selectProvisionalGrade(newProvisionalGradeId, !existingGrade)
        }

        EG.setActiveProvisionalGradeFields({
          grade: existingGrade,
          label: customProvisionalGraderLabel,
        })
      }
    }

    const submissionError = (
      data: GradingError,
      _xhr: XMLHttpRequest,
      _textStatus: string,
      _errorThrown: Error
    ) => {
      EG.handleGradingError(data)

      let selectedGrade
      if (ENV.grading_role === 'moderator') {
        selectedGrade = currentStudentProvisionalGrades().find(
          provisionalGrade => provisionalGrade.selected
        )
      }

      // Revert to the previously selected provisional grade (if we're moderating) or
      // the last valid value (if not moderating or no provisional grade was chosen)
      if (selectedGrade) {
        EG.setActiveProvisionalGradeFields({
          grade: selectedGrade,
          label: provisionalGraderDisplayNames[selectedGrade.provisional_grade_id],
        })
      } else {
        EG.showGrade()
      }
    }

    $.ajaxJSON(url, method, formData, submissionSuccess, submissionError)
  },

  showGrade() {
    const submission = EG.currentStudent.submission || {}
    let grade: Grade | null = null

    if (
      submission.grading_type === 'pass_fail' ||
      ['complete', 'incomplete', 'pass', 'fail'].indexOf(submission.grade as string) > -1
    ) {
      $grade.val(submission.grade as string)
    } else {
      grade = EG.getGradeToShow(submission)
      $grade.val(grade.entered)
    }
    if (submission.points_deducted && grade) {
      $deduction_box.removeClass('hidden')
      $points_deducted.text(grade.pointsDeducted)
      $final_grade.text(grade.adjusted)
    } else {
      $deduction_box.addClass('hidden')
    }

    $('#submit_same_score').hide()
    if (typeof submission !== 'undefined' && submission.entered_score !== null) {
      // @ts-expect-error
      $score.text(I18n.n(round(submission.entered_score, round.DEFAULT)))
      if (!submission.grade_matches_current_submission) {
        $('#submit_same_score').show()
      }
    } else {
      $score.text('')
    }

    if (ENV.MANAGE_GRADES || (window.jsonData.context.concluded && ENV.READ_AS_ADMIN)) {
      renderHiddenSubmissionPill(submission)
    }
    EG.updateStatsInHeader()
  },

  updateSelectMenuStatus(student) {
    if (!student) return
    const isCurrentStudent = student === EG.currentStudent
    const newStudentInfo = EG.getStudentNameAndGrade(student)
    $selectmenu?.updateSelectMenuStatus({student, isCurrentStudent, newStudentInfo, anonymizableId})
  },

  isGradingTypePercent() {
    return ENV.grading_type === 'percent'
  },

  shouldParseGrade() {
    return EG.isGradingTypePercent() || ENV.grading_type === 'points'
  },

  formatGradeForSubmission(grade) {
    if (grade === '') {
      return grade
    }

    let formattedGrade: string = grade

    if (EG.shouldParseGrade()) {
      // Percent sign could be located on left or right, with or without space
      // https://en.wikipedia.org/wiki/Percent_sign
      formattedGrade = grade.replace(/%/g, '')
      const tmpNum = numberHelper.parse(formattedGrade)
      formattedGrade = round(tmpNum, 2).toString()

      if (EG.isGradingTypePercent() && formattedGrade !== 'NaN') {
        formattedGrade += '%'
      }
    }

    return formattedGrade
  },

  getGradeToShow(submission: Submission) {
    const grade: Grade = {entered: ''}

    if (submission) {
      if (submission.excused) {
        grade.entered = 'EX'
      } else {
        if (
          submission.points_deducted !== '' &&
          !Number.isNaN(Number(submission.points_deducted))
        ) {
          grade.pointsDeducted = I18n.n(-(submission.points_deducted || '0'))
        }

        if (submission.entered_grade != null) {
          const formatGradeOpts =
            ENV.grading_type === 'letter_grade' ? {gradingType: ENV.grading_type} : {}
          if (submission.entered_grade !== '' && !Number.isNaN(Number(submission.entered_grade))) {
            grade.entered = GradeFormatHelper.formatGrade(
              round(submission.entered_grade, 2),
              formatGradeOpts
            )
            grade.adjusted = GradeFormatHelper.formatGrade(
              round(submission.grade, 2),
              formatGradeOpts
            )
          } else {
            grade.entered = GradeFormatHelper.formatGrade(submission.entered_grade, formatGradeOpts)
            grade.adjusted = GradeFormatHelper.formatGrade(submission.grade, formatGradeOpts)
          }
        }
      }
    }

    return grade
  },

  initComments() {
    $add_a_comment_submit_button.click(event => {
      event.preventDefault()
      if ($add_a_comment_submit_button.hasClass('ui-state-disabled')) {
        return
      }
      EG.addSubmissionComment()
    })
    $add_attachment.click((event: JQuery.ClickEvent) => {
      event.preventDefault()
      if ($add_attachment.hasClass('ui-state-disabled')) {
        return
      }
      const $attachment = $comment_attachment_input_blank.clone(true)
      $attachment.find('input').attr('name', `attachments[${fileIndex}][uploaded_data]`)
      fileIndex++
      $('#comment_attachments').append($attachment.show())
    })
    $comment_attachment_input_blank.find('a').on('click', function (event: JQuery.ClickEvent) {
      event.preventDefault()
      $(this).parents('.comment_attachment_input').remove()
    })
    $right_side.on('click', '.play_comment_link', function (_event) {
      if ($(this).data('media_comment_id')) {
        $(this)
          .parents('.comment')
          .find('.media_comment_content')
          .show()
          .mediaComment(
            'show',
            $(this).data('media_comment_id'),
            $(this).data('media_comment_type'),
            this
          )
      }
      return false // so that it doesn't hit the $("a.instructure_inline_media_comment").live('click' event handler
    })
    $reassign_assignment.click(event => {
      event.preventDefault()
      EG.reassignAssignment()
    })
    if ($reassign_assignment[0]) {
      $reassign_assignment.parent().tooltip({
        position: {my: 'left bottom', at: 'left top'},
        tooltipClass: 'center bottom vertical',
      })
    }
    if ($new_screen_capture_indicator_wrapper && $new_screen_capture_indicator_wrapper.length) {
      $new_screen_capture_indicator_wrapper.tooltip({
        position: {my: 'left-100 bottom', at: 'center top'},
        tooltipClass: 'center bottom vertical',
      })
    }
    const screenCaptureMountPoint = document.getElementById(SCREEN_CAPTURE_ICON_MOUNT_POINT)
    if (screenCaptureMountPoint) {
      const screen_capture_icon = <ScreenCaptureIcon />
      ReactDOM.render(screen_capture_icon, screenCaptureMountPoint)
    }
  },

  // Note: do not use compareStudentsBy if your dataset includes 0.
  compareStudentsBy(f: (student1: StudentWithSubmission) => number) {
    const secondaryAttr = isAnonymous ? 'anonymous_id' : 'sortable_name'

    return function (studentA, studentB) {
      const a = f(studentA)
      const b = f(studentB)

      if ((!a && !b) || a === b) {
        // sort isn't guaranteed to be stable, so we need to sort by name in case of tie
        return natcompare.strings(studentA[secondaryAttr], studentB[secondaryAttr])
      } else if (!a || a > b) {
        return 1
      }

      return -1
    }
  },

  beforeLeavingSpeedgrader(event: BeforeUnloadEvent) {
    // Submit any draft comments that need submitting
    EG.addSubmissionComment(true)

    if (window.opener?.updateGrades && $.isFunction(window.opener?.updateGrades)) {
      window.opener.updateGrades()
    }

    function userNamesWithPendingQuizSubmission() {
      return $.map(
        snapshotCache,
        snapshot =>
          snapshot &&
          $.map(
            window.jsonData.studentsWithSubmissions,
            // EVAL-3900 - will always return false?
            // @ts-expect-error
            student => snapshot === student && student.name
          )[0]
      )
    }

    function hasPendingQuizSubmissions() {
      let ret = false
      const submissions = userNamesWithPendingQuizSubmission()
      if (submissions.length) {
        for (let i = 0, max = submissions.length; i < max; i++) {
          if (submissions[i] !== false) {
            ret = true
          }
        }
      }
      return ret
    }

    function hasUnsubmittedComments() {
      return $.trim($add_a_comment_textarea.val() as string) !== ''
    }

    const isNewGradeSaved = ($grade.val() || null) === EG.currentStudent.submission.grade
    if (!isNewGradeSaved) {
      event.preventDefault()
      event.returnValue = I18n.t(`There are unsaved changes to a grade.\n\nContinue anyway?`)
      return event.returnValue
    } else if (hasPendingQuizSubmissions()) {
      event.preventDefault()
      event.returnValue = I18n.t(
        'The following students have unsaved changes to their quiz submissions:\n\n' +
          '%{users}\nContinue anyway?',
        {users: userNamesWithPendingQuizSubmission().join('\n ')}
      )
      return event.returnValue
    } else if (hasUnsubmittedComments()) {
      event.preventDefault()
      event.returnValue = I18n.t(
        'If you would like to keep your unsubmitted comments, please save them before navigating away from this page.'
      )
      return event.returnValue
    } else if (EG.hasUnsubmittedRubric(originalRubric)) {
      event.preventDefault()
      event.returnValue = I18n.t(
        'If you would like to keep your unsubmitted rubric, please save them before navigating away from this page.'
      )
      return event.returnValue
    }
    teardownHandleStatePopped(EG)
    teardownBeforeLeavingSpeedgrader()
    return undefined
  },

  handleGradingError(data: GradingError = {}) {
    const errorCode = data.errors && data.errors.error_code

    // If the grader entered an invalid provisional grade, revert it without
    // showing an explicit error
    if (errorCode === 'PROVISIONAL_GRADE_INVALID_SCORE') {
      return
    }

    let errorMessage
    if (errorCode === 'MAX_GRADERS_REACHED') {
      errorMessage = I18n.t('The maximum number of graders has been reached for this assignment.')
    } else if (errorCode === 'PROVISIONAL_GRADE_MODIFY_SELECTED') {
      errorMessage = I18n.t('The grade you entered has been selected and can no longer be changed.')
    } else if (errorCode === 'ASSIGNMENT_LOCKED') {
      errorMessage = I18n.t('This assignment is locked and cannot be reassigned.')
    } else {
      errorMessage = I18n.t('An error occurred updating this assignment.')
    }

    $.flashError(errorMessage)
  },

  selectProvisionalGrade(provisionalGradeId?: string, refetchOnSuccess: boolean = false) {
    const selectGradeUrl = replaceTags(ENV.provisional_select_url || '', {
      provisional_grade_id: provisionalGradeId,
    })

    const submitSucceeded = (data: {selected_provisional_grade_id: string}) => {
      const selectedProvisionalGradeId = data.selected_provisional_grade_id
      // Update the "selected" field on our grades manually. No need to bother
      // the server solely to verify the new selections.
      currentStudentProvisionalGrades().forEach(grade => {
        grade.selected = grade.provisional_grade_id === selectedProvisionalGradeId
      })

      if (refetchOnSuccess) {
        // If this involved submitting a new provisional grade, re-fetch the
        // list of grades so we have a real data structure for the new one
        this.fetchProvisionalGrades()
      } else {
        // Otherwise we just selected an existing grade and didn't change
        // anything, so go ahead and re-render
        this.renderProvisionalGradeSelector()
      }
    }

    $.ajaxJSON(selectGradeUrl, 'PUT', {}, submitSucceeded)
  },

  setupProvisionalGraderDisplayNames() {
    provisionalGraderDisplayNames = {}
    const provisionalGrades = currentStudentProvisionalGrades()

    provisionalGrades.forEach(grade => {
      if (grade.scorer_id === ENV.final_grader_id) {
        provisionalGraderDisplayNames[grade.provisional_grade_id] = customProvisionalGraderLabel
      } else {
        const displayName = grade.anonymous_grader_id
          ? ENV.anonymous_identities[grade.anonymous_grader_id].name
          : grade.scorer_name
        provisionalGraderDisplayNames[grade.provisional_grade_id] = displayName
      }
    })
  },

  fetchProvisionalGrades() {
    const {course_id: courseId, assignment_id: assignmentId} = ENV
    const resourceSegment = isAnonymous ? 'anonymous_provisional_grades' : 'provisional_grades'
    const resourceUrl = `/api/v1/courses/${courseId}/assignments/${assignmentId}/${resourceSegment}/status`

    let status_url = `${resourceUrl}?${anonymizableStudentId}=${EG.currentStudent[anonymizableId]}`
    if (ENV.grading_role === 'moderator') {
      status_url += '&last_updated_at='
      if (EG.currentStudent.submission) {
        status_url += EG.currentStudent.submission.updated_at
      }
    }

    // Check with the API ("hit the API" sounds so brutish) to get the updated
    // list of provisional grades. We return this so that disableWhileLoading
    // has access to the Deferred object.
    return $.getJSON(status_url, {}, EG.onProvisionalGradesFetched)
  },

  onProvisionalGradesFetched(data) {
    EG.currentStudent.needs_provisional_grade = data.needs_provisional_grade

    if (ENV.grading_role === 'moderator' && data.provisional_grades) {
      // @ts-expect-error
      if (!EG.currentStudent.submission) EG.currentStudent.submission = {}
      EG.currentStudent.submission.provisional_grades = data.provisional_grades
      EG.currentStudent.submission.updated_at = data.updated_at
      EG.currentStudent.submission.final_provisional_grade = data.final_provisional_grade
    }

    EG.currentStudent.submission_state = SpeedgraderHelpers.submissionState(
      EG.currentStudent,
      ENV.grading_role
    )
    EG.showStudent()
  },

  setActiveProvisionalGradeFields({label = '', grade = null} = {}) {
    $grading_box_selected_grader.text(label || '')

    const submission: Submission = EG.currentStudent.submission || {}
    if (grade !== null) {
      // If the moderator has selected their own custom grade
      // (i.e., the selected grade isn't read-only) and has
      // excused this submission, show that instead of the
      // provisional grade's score
      if (!grade.readonly && submission.excused) {
        $grade.val('EX')
        $score.text('')
      } else {
        $grade.val(String(grade.grade))
        $score.text(String(grade.score))
      }
    }
  },

  handleProvisionalGradeSelected({
    selectedGrade,
    isNewGrade = false,
  }: {
    isNewGrade?: boolean
    selectedGrade?: {provisional_grade_id: string}
  } = {}) {
    if (selectedGrade) {
      const selectedGradeId = selectedGrade.provisional_grade_id

      this.selectProvisionalGrade(selectedGradeId)
      this.setActiveProvisionalGradeFields({
        grade: selectedGrade,
        label: provisionalGraderDisplayNames[selectedGradeId],
      })
    } else if (isNewGrade) {
      // If this is a "new" grade with no value, don't submit anything to the
      // server. This will only happen when the moderator selects a custom
      // grade for a given student for the first time (since no provisional grade
      // object exists yet). If/when the grade text field gets updated,
      // handleGradeSubmit will fire, create the new object, and re-fetch the
      // provisional grades from the server.
      this.setActiveProvisionalGradeFields({label: customProvisionalGraderLabel})

      // For now, set the grader fields appropriately and mark the grades we have
      // as not-selected until we get the new one.
      currentStudentProvisionalGrades().forEach(grade => {
        grade.selected = false
      })
      this.renderProvisionalGradeSelector()
    }
  },

  renderProvisionalGradeSelector({showingNewStudent = false} = {}) {
    const mountPoint = document.getElementById('grading_details_mount_point')
    if (!mountPoint) throw new Error('Could not find mount point for provisional grade selector')
    const provisionalGrades = currentStudentProvisionalGrades()

    // Only show the selector if the current student has at least one grade from
    // a provisional grader (i.e., not the moderator).
    if (!provisionalGrades.some(grade => grade.readonly)) {
      ReactDOM.unmountComponentAtNode(mountPoint)
      return
    }

    if (showingNewStudent) {
      this.setupProvisionalGraderDisplayNames()
    }

    const props = {
      finalGraderId: ENV.final_grader_id,
      gradingType: ENV.grading_type,
      onGradeSelected: (params: {
        selectedGrade?:
          | {
              provisional_grade_id: string
            }
          | undefined
        isNewGrade: boolean
      }) => {
        this.handleProvisionalGradeSelected(params)
      },
      pointsPossible: window.jsonData.points_possible,
      provisionalGraderDisplayNames,
      provisionalGrades,
    }

    const gradeSelector = <SpeedGraderProvisionalGradeSelector {...props} />
    ReactDOM.render(gradeSelector, mountPoint)
  },

  changeToSection(sectionId: string) {
    if (ENV.settings_url) {
      $.post(ENV.settings_url, {selected_section_id: sectionId}, () => {
        SpeedgraderHelpers.reloadPage()
      })
    } else {
      SpeedgraderHelpers.reloadPage()
    }
  },
}

function getGradingPeriods() {
  const dfd = $.Deferred()
  // treating failure as a success here since grading periods 404 when not
  // enabled
  $.ajaxJSON(
    `/api/v1/courses/${ENV.course_id}/grading_periods`,
    'GET',
    {},
    (response: {grading_periods: GradingPeriod[]}) => {
      dfd.resolve(response.grading_periods)
    },
    () => {
      dfd.resolve([])
    },
    {skipDefaultError: true}
  )

  return dfd
}

function setupSpeedGrader(
  gradingPeriods: GradingPeriod[],
  speedGraderJsonResponse: SpeedGraderResponse[]
) {
  const speedGraderJSON = speedGraderJsonResponse[0] as SpeedGraderStore

  speedGraderJSON.gradingPeriods = keyBy(gradingPeriods, 'id')
  window.jsonData = speedGraderJSON
  EG.jsonReady()
  EG.setInitiallyLoadedStudent()
  EG.setupGradeLoadingSpinner()
}

function setupSelectors() {
  // PRIVATE VARIABLES AND FUNCTIONS
  // all of the $ variables here are to speed up access to dom nodes,
  // so that the jquery selector does not have to be run every time.
  $add_a_comment = $('#add_a_comment')
  $add_a_comment_submit_button = $add_a_comment.find('button:submit')
  $add_a_comment_textarea = $(`#${SPEED_GRADER_COMMENT_TEXTAREA_MOUNT_POINT}`)
  $add_attachment = $('#add_attachment')
  $reassign_assignment = $('#reassign_assignment')
  $assignment_submission_originality_report_url = $('#assignment_submission_originality_report_url')
  $assignment_submission_resubmit_to_vericite_url = $(
    '#assignment_submission_resubmit_to_vericite_url'
  )
  $assignment_submission_turnitin_report_url = $('#assignment_submission_turnitin_report_url')
  $assignment_submission_vericite_report_url = $('#assignment_submission_vericite_report_url')
  $avatar_image = $('#avatar_image')
  $average_score = $('#average_score')
  $average_score_wrapper = $('#average-score-wrapper')
  $comment_attachment_blank = $('#comment_attachment_blank').removeAttr('id').detach()
  $comment_attachment_input_blank = $('#comment_attachment_input_blank').detach()
  $comment_blank = $('#comment_blank').removeAttr('id').detach()
  $comment_saved = $('#comment_saved')
  $comment_saved_message = $('#comment_saved_message')
  $comment_submitted = $('#comment_submitted')
  $comment_submitted_message = $('#comment_submitted_message')
  $comments = $('#comments')
  $reassignment_complete = $('#reassignment_complete')
  $deduction_box = $('#deduction-box')
  $enrollment_concluded_notice = $('#enrollment_concluded_notice')
  $enrollment_inactive_notice = $('#enrollment_inactive_notice')
  $final_grade = $('#final-grade')
  $full_width_container = $('#full_width_container')
  $grade_container = $('#grade_container')
  $grade = $grade_container.find('input, select')
  $gradebook_header = $('#gradebook_header')
  $grading_box_selected_grader = $('#grading-box-selected-grader')
  $grded_so_far = $('#x_of_x_graded')
  $iframe_holder = $('#iframe_holder')
  $left_side = $('#left_side')
  $multiple_submissions = $('#multiple_submissions')
  $new_screen_capture_indicator_wrapper = $('#new-studio-media-indicator-wrapper')
  $no_annotation_warning = $('#no_annotation_warning')
  $not_gradeable_message = $('#not_gradeable_message')
  $points_deducted = $('#points-deducted')
  $resize_overlay = $('#resize_overlay')
  $right_side = $('#right_side')
  $rightside_inner = $('#rightside_inner')
  $rubric_holder = $('#rubric_holder')
  $score = $grade_container.find('.score')
  $selectmenu = null
  $submission_attachment_viewed_at = $('#submission_attachment_viewed_at_container')
  $submission_details = $('#submission_details')
  $submission_file_hidden = $('#submission_file_hidden').removeAttr('id').detach()
  $submission_files_container = $('#submission_files_container')
  $submission_files_list = $('#submission_files_list')
  $submission_late_notice = $('#submission_late_notice')
  $submission_not_newest_notice = $('#submission_not_newest_notice')
  $submissions_container = $('#submissions_container')
  $this_student_does_not_have_a_submission = $('#this_student_does_not_have_a_submission').hide()
  $this_student_has_a_submission = $('#this_student_has_a_submission').hide()
  $width_resizer = $('#width_resizer')
  $window = $(window)
  $x_of_x_students = $('#x_of_x_students_frd')
  $word_count = $('#submission_word_count')
  assignmentUrl = $('#assignment_url').attr('href') || ''
  browserableCssClasses = /^(image|html|code)$/
  fileIndex = 1
  gradeeLabel = studentLabel
  groupLabel = I18n.t('group', 'Group')
  isAdmin = ENV.current_user_is_admin
  snapshotCache = {}
  studentLabel = I18n.t('student', 'Student')
  header = setupHeader()
}

// Helper function that guard against provisional_grades being null, allowing
// Anonymous Moderated Marking-related moderation code to forgo that check
// when considering provisional grades.
function currentStudentProvisionalGrades() {
  return EG.currentStudent.submission.provisional_grades || []
}

export default {
  setup() {
    setupSelectors()
    renderSettingsMenu(header)

    if (ENV.can_view_audit_trail) {
      EG.setUpAssessmentAuditTray()
    }

    if (enhanced_rubrics && ENV.rubric) {
      EG.setUpRubricAssessmentTrayWrapper()
    }

    function registerQuizzesNext(
      overriddenShowSubmission: (submission: Submission) => void,
      launchOptions: {
        singleLtiLaunch: boolean
      }
    ) {
      showSubmissionOverride = overriddenShowSubmission
      if (launchOptions) {
        externalToolLaunchOptions = launchOptions
      }
    }
    QuizzesNextSpeedGrading.setup(EG, $iframe_holder, registerQuizzesNext, refreshGrades, window)

    // fire off the request to get the jsonData
    // @ts-expect-error
    window.jsonData = {}
    const speedGraderJSONUrl = `${window.location.pathname}.json${window.location.search}`
    const speedGraderJsonDfd = $.ajaxJSON(
      speedGraderJSONUrl,
      'GET',
      null,
      null,
      speedGraderJSONErrorFn
    )

    commentSubmissionInProgress = false

    // eslint-disable-next-line promise/catch-or-return
    $.when(getGradingPeriods(), speedGraderJsonDfd).then(setupSpeedGrader)

    // run the stuff that just attaches event handlers and dom stuff, but does not need the jsonData
    $(document).ready(() => {
      EG.domReady()
    })
  },

  teardown() {
    if (ENV.can_view_audit_trail) {
      tearDownAssessmentAuditTray(EG)
    }

    if (EG.postPolicies) {
      EG.postPolicies.destroy()
    }

    teardownSettingsMenu()
    teardownHandleStatePopped(EG)
    teardownBeforeLeavingSpeedgrader()
  },

  EG,
}
