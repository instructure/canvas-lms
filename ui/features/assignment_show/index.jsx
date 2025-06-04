/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import '@canvas/jquery/jquery.ajaxJSON'
import React from 'react'
import {createRoot} from 'react-dom/client'
import axios from '@canvas/axios'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import PublishButtonView from '@canvas/publish-button-view'
import SpeedgraderLinkView from './backbone/views/SpeedgraderLinkView'
import vddTooltip from '@canvas/due-dates/jquery/vddTooltip'
import MarkAsDone from '@canvas/util/jquery/markAsDone'
import CyoeStats from '@canvas/conditional-release-stats/react/index'
import '@canvas/jquery/jquery.instructure_forms'
import LockManager from '@canvas/blueprint-courses/react/components/LockManager/index'
import AssignmentExternalTools from '@canvas/assignments/react/AssignmentExternalTools'
import AssignmentAssetProcessorEula from '@canvas/assignments/react/AssignmentAssetProcessorEula'
import StudentGroupFilter from '@canvas/student-group-filter'
import SpeedGraderLink from '@canvas/speed-grader-link'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import {setupSubmitHandler} from '@canvas/assignments/jquery/reuploadSubmissionsHelper'
import ready from '@instructure/ready'
import ItemAssignToManager from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToManager'
import {captureException} from '@sentry/browser'
import {
  RubricAssignmentContainer,
  RubricSelfAssessmentSettingsWrapper,
} from '@canvas/rubrics/react/RubricAssignment'
import {
  mapRubricUnderscoredKeysToCamelCase,
  mapRubricAssociationUnderscoredKeysToCamelCase,
} from '@canvas/rubrics/react/utils'
import sanitizeHtml from 'sanitize-html-with-tinymce'
import {containsHtmlTags, formatMessage} from '@canvas/util/TextHelper'

if (!('INST' in window)) window.INST = {}

const I18n = createI18nScope('assignment')

// Keep track of React roots
const roots = new Map()

function createOrUpdateRoot(elementId, component) {
  const container = document.getElementById(elementId)
  if (!container) return

  let root = roots.get(elementId)
  if (!root) {
    root = createRoot(container)
    roots.set(elementId, root)
  }
  root.render(component)
}

function unmountRoot(elementId) {
  const root = roots.get(elementId)
  if (root) {
    root.unmount()
    roots.delete(elementId)
  }
}

ready(() => {
  const comments = document.getElementsByClassName('comment_content')
  Array.from(comments).forEach(comment => {
    const content = comment.dataset.content
    const formattedComment = containsHtmlTags(content)
      ? sanitizeHtml(content)
      : formatMessage(content)
    comment.innerHTML = formattedComment
  })

  const lockManager = new LockManager()
  lockManager.init({itemType: 'assignment', page: 'show'})
  renderCoursePacingNotice()
})

let studentGroupSelectionRequestTrackers = []

function onStudentGroupSelected(selectedStudentGroupId) {
  if (selectedStudentGroupId !== '0') {
    const tracker = {selectedStudentGroupId}
    studentGroupSelectionRequestTrackers.push(tracker)

    ENV.selected_student_group_id = selectedStudentGroupId
    renderStudentGroupFilter()
    renderSpeedGraderLink()

    axios
      .put(`/api/v1/courses/${ENV.COURSE_ID}/gradebook_settings`, {
        gradebook_settings: {
          filter_rows_by: {
            student_group_id: selectedStudentGroupId,
            student_group_ids: [selectedStudentGroupId],
          },
        },
      })
      .finally(() => {
        studentGroupSelectionRequestTrackers = studentGroupSelectionRequestTrackers.filter(
          item => item !== tracker,
        )
        renderSpeedGraderLink()
      })
  }
}

function renderSpeedGraderLink() {
  const disabled =
    ENV.SETTINGS.filter_speed_grader_by_student_group &&
    (!ENV.selected_student_group_id || studentGroupSelectionRequestTrackers.length > 0)

  createOrUpdateRoot(
    'speed_grader_link_mount_point',
    <SpeedGraderLink
      disabled={disabled}
      href={ENV.speed_grader_url}
      disabledTip={I18n.t('Must select a student group first')}
    />,
  )
}

function renderStudentGroupFilter() {
  createOrUpdateRoot(
    'student_group_filter_mount_point',
    <StudentGroupFilter
      categories={ENV.group_categories}
      label={I18n.t('Select Group to Grade')}
      onChange={onStudentGroupSelected}
      value={ENV.selected_student_group_id}
    />,
  )
}

function renderCoursePacingNotice() {
  const $mountPoint = document.getElementById('course_paces_due_date_notice')

  if ($mountPoint) {
    import('@canvas/due-dates/react/CoursePacingNotice')
      .then(CoursePacingNoticeModule => {
        const renderNotice = CoursePacingNoticeModule.renderCoursePacingNotice
        renderNotice($mountPoint, ENV.COURSE_ID)
      })
      .catch(ex => {
        console.error('Failed loading CoursePacingNotice', ex)
        captureException(ex)
      })
  }
}

ready(() => {
  // Attach the immersive reader button if enabled
  const immersive_reader_mount_point = document.getElementById('immersive_reader_mount_point')
  const immersive_reader_mobile_mount_point = document.getElementById(
    'immersive_reader_mobile_mount_point',
  )
  if (immersive_reader_mount_point || immersive_reader_mobile_mount_point) {
    import('@canvas/immersive-reader/ImmersiveReader')
      .then(({initializeReaderButton}) => {
        const content = () => document.querySelector('.description')?.innerHTML
        const title = document.querySelector('.title')?.textContent

        if (immersive_reader_mount_point) {
          initializeReaderButton(immersive_reader_mount_point, {content, title})
        }

        if (immersive_reader_mobile_mount_point) {
          initializeReaderButton(immersive_reader_mobile_mount_point, {
            content,
            title,
          })
        }
      })
      .catch(e => {
        console.log('Error loading immersive readers.', e)
      })
  }
})

const promiseToGetModuleSequenceFooter = import('@canvas/module-sequence-footer')
$(() => {
  const $el = $('#assignment_publish_button')
  if ($el.length > 0) {
    const model = new Assignment({
      id: $el.attr('data-id'),
      unpublishable: !$el.hasClass('disabled'),
      published: $el.hasClass('published'),
    })
    model.doNotParse()

    new SpeedgraderLinkView({model, el: '#assignment-speedgrader-link'}).render()
    const pbv = new PublishButtonView({model, el: $el})
    pbv.render()

    pbv.on('publish', () => {
      $('#moderated_grading_button').show()
      $('#speed-grader-link-container').removeClass('hidden')
    })

    pbv.on('unpublish', () => {
      $('#moderated_grading_button').hide()
      $('#speed-grader-link-container').addClass('hidden')
    })
  }

  // Add module sequence footer
  promiseToGetModuleSequenceFooter.then(() => {
    $('#sequence_footer').moduleSequenceFooter({
      courseID: ENV.COURSE_ID,
      assetType: 'Assignment',
      assetID: ENV.ASSIGNMENT_ID,
      onFetchSuccess: () => {
        $('.module-sequence-footer-right').prepend($('#mark-as-done-container'))
        $('#mark-as-done-container').css({'margin-right': '4px'})
      },
      location: window.location,
    })
  })

  return vddTooltip()
})

function renderItemAssignToTray(open, returnFocusTo, itemProps) {
  createOrUpdateRoot(
    'assign-to-mount-point',
    <ItemAssignToManager
      open={open}
      onClose={() => {
        unmountRoot('assign-to-mount-point')
      }}
      onDismiss={() => {
        renderItemAssignToTray(false, returnFocusTo, itemProps)
        returnFocusTo?.focus()
      }}
      itemType="assignment"
      iconType="assignment"
      locale={ENV.LOCALE || 'en'}
      timezone={ENV.TIMEZONE || 'UTC'}
      {...itemProps}
    />,
  )
}

$('.assign-to-link').on('click keyclick', function (event) {
  event.preventDefault()
  const returnFocusTo = $(event.target).closest('ul').prev('.al-trigger')

  const courseId = event.target.getAttribute('data-assignment-context-id')
  const itemName = event.target.getAttribute('data-assignment-name')
  const itemContentId = event.target.getAttribute('data-assignment-id')
  const pointsString = event.target.getAttribute('data-assignment-points-possible')
  const pointsPossible = pointsString ? parseFloat(pointsString) : undefined
  renderItemAssignToTray(true, returnFocusTo, {
    courseId,
    itemName,
    itemContentId,
    pointsPossible,
  })
})

$(() =>
  $('#content').on('click', '#mark-as-done-checkbox', function () {
    return MarkAsDone.toggle(this)
  }),
)

function openSendTo(event, open = true) {
  if (event) event.preventDefault()

  createOrUpdateRoot(
    'direct-share-mount-point',
    <DirectShareUserModal
      open={open}
      sourceCourseId={ENV.COURSE_ID}
      contentShare={{content_type: 'assignment', content_id: ENV.ASSIGNMENT_ID}}
      onDismiss={() => {
        unmountRoot('direct-share-mount-point')
        openSendTo(null, false)
        $('.al-trigger').focus()
      }}
    />,
  )
}

function openCopyTo(event, open = true) {
  if (event) event.preventDefault()

  createOrUpdateRoot(
    'direct-share-mount-point',
    <DirectShareCourseTray
      open={open}
      sourceCourseId={ENV.COURSE_ID}
      contentSelection={{assignments: [ENV.ASSIGNMENT_ID]}}
      onDismiss={() => {
        unmountRoot('direct-share-mount-point')
        openCopyTo(null, false)
        $('.al-trigger').focus()
      }}
    />,
  )
}

$(() => {
  $('.direct-share-send-to-menu-item').click(openSendTo)
  $('.direct-share-copy-to-menu-item').click(openCopyTo)
})

// -- This is all for the _grade_assignment sidebar partial
$(() => {
  if (ENV.speed_grader_url) {
    if (ENV.SETTINGS.filter_speed_grader_by_student_group) {
      renderStudentGroupFilter()
    }

    renderSpeedGraderLink()
  }
})

$(() => {
  const $mountPoint = document.getElementById('enhanced-rubric-assignment-edit-mount-point')

  if ($mountPoint) {
    const envRubric = ENV.assigned_rubric
    const envRubricAssociation = ENV.rubric_association
    const assignmentRubric = envRubric
      ? {
          ...mapRubricUnderscoredKeysToCamelCase(ENV.assigned_rubric),
          can_update: ENV.assigned_rubric?.can_update,
          association_count: ENV.assigned_rubric?.association_count,
        }
      : undefined
    const assignmentRubricAssociation = envRubricAssociation
      ? mapRubricAssociationUnderscoredKeysToCamelCase(ENV.rubric_association)
      : undefined

    createOrUpdateRoot(
      'enhanced-rubric-assignment-edit-mount-point',
      <RubricAssignmentContainer
        accountMasterScalesEnabled={ENV.ACCOUNT_LEVEL_MASTERY_SCALES}
        assignmentId={ENV.ASSIGNMENT_ID}
        assignmentRubric={assignmentRubric}
        assignmentRubricAssociation={assignmentRubricAssociation}
        canManageRubrics={ENV.PERMISSIONS.manage_rubrics}
        contextAssetString={ENV.context_asset_string}
        courseId={ENV.COURSE_ID}
        rubricSelfAssessmentFFEnabled={ENV.rubric_self_assessment_ff_enabled}
        aiRubricsEnabled={ENV.ai_rubrics_enabled}
      />,
    )
  }

  createOrUpdateRoot(
    'enhanced-rubric-self-assessment-edit',
    <RubricSelfAssessmentSettingsWrapper assignmentId={ENV.ASSIGNMENT_ID} />,
  )
})

$(() => {
  $('.upload_submissions_link').click(event => {
    event.preventDefault()
    $('#re_upload_submissions_form').slideToggle()
  })

  $('.download_submissions_link').click(function (event) {
    event.preventDefault()
    INST.downloadSubmissions($(this).attr('href'))
    $('.upload_submissions_link').slideDown()
  })

  setupSubmitHandler(ENV.USER_ASSET_STRING)

  $('#edit_assignment_form').bind('assignment_updated', (_, data) => {
    if (data.assignment && data.assignment.peer_reviews) {
      $('.assignment_peer_reviews_link').slideDown()
    } else {
      $('.assignment_peer_reviews_link').slideUp()
    }
  })
})

$(() => {
  const graphsRoot = document.getElementById('crs-graphs')
  const detailsParent = document.getElementById('not_right_side')
  CyoeStats.init(graphsRoot, detailsParent)
  if (document.getElementById('assignment_external_tools')) {
    AssignmentExternalTools.attach(
      document.getElementById('assignment_external_tools'),
      'assignment_view',
      parseInt(ENV.COURSE_ID, 10),
      parseInt(ENV.ASSIGNMENT_ID, 10),
    )
  }
})

ready(() => {
  $('#accessibility_warning').on('focus', function () {
    $('#accessibility_warning').removeClass('screenreader-only')
  })

  $('#accessibility_warning').on('blur', function () {
    $('#accessibility_warning').addClass('screenreader-only')
  })
})

if (ENV.FEATURES.lti_asset_processor) {
  ready(() => {
    createOrUpdateRoot(
      'assignment_asset_processor_eula',
      <AssignmentAssetProcessorEula launches={ENV.ASSET_PROCESSOR_EULA_LAUNCH_URLS} />,
    )
  })
}
