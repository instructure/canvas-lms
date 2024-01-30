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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import '@canvas/jquery/jquery.ajaxJSON'
import React from 'react'
import ReactDOM from 'react-dom'
import axios from '@canvas/axios'
import qs from 'qs'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import PublishButtonView from '@canvas/publish-button-view'
import SpeedgraderLinkView from './backbone/views/SpeedgraderLinkView'
import vddTooltip from '@canvas/due-dates/jquery/vddTooltip'
import MarkAsDone from '@canvas/util/jquery/markAsDone'
import CyoeStats from '@canvas/conditional-release-stats/react/index'
import '@canvas/jquery/jquery.instructure_forms'
import LockManager from '@canvas/blueprint-courses/react/components/LockManager/index'
import AssignmentExternalTools from '@canvas/assignments/react/AssignmentExternalTools'
import StudentGroupFilter from '@canvas/student-group-filter'
import SpeedGraderLink from '@canvas/speed-grader-link'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import {setupSubmitHandler} from '@canvas/assignments/jquery/reuploadSubmissionsHelper'
import ready from '@instructure/ready'
import {monitorLtiMessages} from '@canvas/lti/jquery/messages'
import ItemAssignToTray from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToTray'
import {captureException} from '@sentry/browser'

if (!('INST' in window)) window.INST = {}

const I18n = useI18nScope('assignment')

ready(() => {
  const lockManager = new LockManager()
  lockManager.init({itemType: 'assignment', page: 'show'})
  renderCoursePacingNotice()
  monitorLtiMessages()
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
      .put(
        `/api/v1/courses/${ENV.COURSE_ID}/gradebook_settings`,
        qs.stringify({
          gradebook_settings: {
            filter_rows_by: {
              student_group_id: selectedStudentGroupId,
            },
          },
        })
      )
      .finally(() => {
        studentGroupSelectionRequestTrackers = studentGroupSelectionRequestTrackers.filter(
          item => item !== tracker
        )
        renderSpeedGraderLink()
      })
  }
}

function renderSpeedGraderLink() {
  const disabled =
    ENV.SETTINGS.filter_speed_grader_by_student_group &&
    (!ENV.selected_student_group_id || studentGroupSelectionRequestTrackers.length > 0)
  const $mountPoint = document.getElementById('speed_grader_link_mount_point')

  if ($mountPoint) {
    ReactDOM.render(
      <SpeedGraderLink
        disabled={disabled}
        href={ENV.speed_grader_url}
        disabledTip={I18n.t('Must select a student group first')}
      />,
      $mountPoint
    )
  }
}

function renderStudentGroupFilter() {
  const $mountPoint = document.getElementById('student_group_filter_mount_point')

  if ($mountPoint) {
    ReactDOM.render(
      <StudentGroupFilter
        categories={ENV.group_categories}
        label={I18n.t('Select Group to Grade')}
        onChange={onStudentGroupSelected}
        value={ENV.selected_student_group_id}
      />,
      $mountPoint
    )
  }
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
        // eslint-disable-next-line no-console
        console.error('Falied loading CoursePacingNotice', ex)
        captureException(ex)
      })
  }
}

ready(() => {
  // Attach the immersive reader button if enabled
  const immersive_reader_mount_point = document.getElementById('immersive_reader_mount_point')
  const immersive_reader_mobile_mount_point = document.getElementById(
    'immersive_reader_mobile_mount_point'
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
        console.log('Error loading immersive readers.', e) // eslint-disable-line no-console
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
      location: window.location,
    })
  })

  return vddTooltip()
})

function renderItemAssignToTray(open, returnFocusTo, itemProps) {
  ReactDOM.render(
    <ItemAssignToTray
      open={open}
      onClose={() => {
        ReactDOM.unmountComponentAtNode(document.getElementById('assign-to-mount-point'))
      }}
      onDismiss={() => {
        renderItemAssignToTray(false, returnFocusTo, itemProps)
        returnFocusTo.focus()
      }}
      itemType="assignment"
      iconType="assignment"
      locale={ENV.LOCALE || 'en'}
      timezone={ENV.TIMEZONE || 'UTC'}
      {...itemProps}
    />,
    document.getElementById('assign-to-mount-point')
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
  })
)

function openSendTo(event, open = true) {
  if (event) event.preventDefault()
  ReactDOM.render(
    <DirectShareUserModal
      open={open}
      sourceCourseId={ENV.COURSE_ID}
      contentShare={{content_type: 'assignment', content_id: ENV.ASSIGNMENT_ID}}
      onDismiss={() => {
        openSendTo(null, false)
        $('.al-trigger').focus()
      }}
    />,
    document.getElementById('direct-share-mount-point')
  )
}

function openCopyTo(event, open = true) {
  if (event) event.preventDefault()
  ReactDOM.render(
    <DirectShareCourseTray
      open={open}
      sourceCourseId={ENV.COURSE_ID}
      contentSelection={{assignments: [ENV.ASSIGNMENT_ID]}}
      onDismiss={() => {
        openCopyTo(null, false)
        $('.al-trigger').focus()
      }}
    />,
    document.getElementById('direct-share-mount-point')
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

  $('#edit_assignment_form').bind('assignment_updated', (event, data) => {
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
      parseInt(ENV.ASSIGNMENT_ID, 10)
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
