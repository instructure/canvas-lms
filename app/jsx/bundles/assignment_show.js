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

import INST from 'INST'
import I18n from 'i18n!assignment'
import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import axios from 'axios'
import qs from 'qs'
import Assignment from 'compiled/models/Assignment'
import PublishButtonView from 'compiled/views/PublishButtonView'
import SpeedgraderLinkView from 'compiled/views/assignments/SpeedgraderLinkView'
import vddTooltip from 'compiled/util/vddTooltip'
import MarkAsDone from 'compiled/util/markAsDone'
import CyoeStats from '../conditional_release_stats/index'
import 'jquery.instructure_forms'
import LockManager from '../blueprint_courses/apps/LockManager'
import AssignmentExternalTools from 'jsx/assignments/AssignmentExternalTools'
import StudentGroupFilter from '../shared/StudentGroupFilter'
import SpeedGraderLink from '../shared/SpeedGraderLink'

const lockManager = new LockManager()
lockManager.init({itemType: 'assignment', page: 'show'})

function onStudentGroupSelected(selectedStudentGroupId) {
  if (selectedStudentGroupId !== '0') {
    axios.put(
      `/api/v1/courses/${ENV.COURSE_ID}/gradebook_settings`,
      qs.stringify({
        gradebook_settings: {
          filter_rows_by: {
            student_group_id: selectedStudentGroupId
          }
        }
      })
    )

    ENV.selected_student_group_id = selectedStudentGroupId
    renderStudentGroupFilter()
    renderSpeedGraderLink()
  }
}

function renderSpeedGraderLink() {
  const disabled =
    ENV.SETTINGS.filter_speed_grader_by_student_group && !ENV.selected_student_group_id
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

const promiseToGetModuleSequenceFooter = import('compiled/jquery/ModuleSequenceFooter')
$(() => {
  const $el = $('#assignment_publish_button')
  if ($el.length > 0) {
    const model = new Assignment({
      id: $el.attr('data-id'),
      unpublishable: !$el.hasClass('disabled'),
      published: $el.hasClass('published')
    })
    model.doNotParse()

    new SpeedgraderLinkView({model, el: '#assignment-speedgrader-link'}).render()
    const pbv = new PublishButtonView({model, el: $el})
    pbv.render()

    pbv.on('publish', () => $('#moderated_grading_button').show())

    pbv.on('unpublish', () => $('#moderated_grading_button').hide())
  }

  // Add module sequence footer
  promiseToGetModuleSequenceFooter.then(() => {
    $('#sequence_footer').moduleSequenceFooter({
      courseID: ENV.COURSE_ID,
      assetType: 'Assignment',
      assetID: ENV.ASSIGNMENT_ID,
      location: window.location
    })
  })

  return vddTooltip()
})

$(() =>
  $('#content').on('click', '#mark-as-done-checkbox', function() {
    return MarkAsDone.toggle(this)
  })
)

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

  $('.download_submissions_link').click(function(event) {
    event.preventDefault()
    INST.downloadSubmissions($(this).attr('href'))
    $('.upload_submissions_link').slideDown()
  })

  $('#re_upload_submissions_form').submit(function(event) {
    const data = $(this).getFormData()
    if (!data.submissions_zip) {
      event.preventDefault()
      event.stopPropagation()
    } else if (!data.submissions_zip.match(/\.zip$/)) {
      event.preventDefault()
      event.stopPropagation()
      $(this).formErrors({
        submissions_zip: I18n.t('Please upload files as a .zip')
      })
    }
  })

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
