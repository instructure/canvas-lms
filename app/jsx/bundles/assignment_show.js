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
import Assignment from 'compiled/models/Assignment'
import PublishButtonView from 'compiled/views/PublishButtonView'
import SpeedgraderLinkView from 'compiled/views/assignments/SpeedgraderLinkView'
import vddTooltip from 'compiled/util/vddTooltip'
import MarkAsDone from 'compiled/util/markAsDone'
import CyoeStats from '../conditional_release_stats/index'
import 'compiled/jquery/ModuleSequenceFooter'
import 'jquery.instructure_forms'
import LockManager from '../blueprint_courses/apps/LockManager'

const lockManager = new LockManager()
lockManager.init({ itemType: 'assignment', page: 'show' })

$(() =>
  $('#content').on('click', '#mark-as-done-checkbox', function () {
    return MarkAsDone.toggle(this)
  })
)

$(() => {
  const $el = $('#assignment_publish_button')
  if ($el.length > 0) {
    const model = new Assignment({
      id: $el.attr('data-id'),
      unpublishable: !$el.hasClass('disabled'),
      published: $el.hasClass('published')
    })
    model.doNotParse()

    new SpeedgraderLinkView({model, el: '#assignment-speedgrader-link'})
        .render()
    const pbv = new PublishButtonView({model, el: $el})
    pbv.render()

    pbv.on('publish', () => $('#moderated_grading_button').show())

    pbv.on('unpublish', () => $('#moderated_grading_button').hide())
  }

    // Add module sequence footer
  $('#sequence_footer').moduleSequenceFooter({
    courseID: ENV.COURSE_ID,
    assetType: 'Assignment',
    assetID: ENV.ASSIGNMENT_ID,
    location
  })

  return vddTooltip()
})

  // -- This is all for the _grade_assignment sidebar partial
$(() => {
  $('.upload_submissions_link').click((event) => {
    event.preventDefault()
    $('#re_upload_submissions_form').slideToggle()
  })

  $('.download_submissions_link').click(function (event) {
    event.preventDefault()
    INST.downloadSubmissions($(this).attr('href'))
    $('.upload_submissions_link').slideDown()
  })

  $('#re_upload_submissions_form').submit(function (event) {
    const data = $(this).getFormData()
    if (!data.submissions_zip) {
      event.preventDefault()
      event.stopPropagation()
    } else if (!data.submissions_zip.match(/\.zip$/)) {
      event.preventDefault()
      event.stopPropagation()
      $(this).formErrors({
        submissions_zip: I18n.t('Please upload files as a .zip')})
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
})
