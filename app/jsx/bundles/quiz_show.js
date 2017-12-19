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

import $ from 'jquery'
import inputMethods from 'quiz_inputs'
import 'quiz_show'
import 'quiz_rubric'
import 'message_students'
import 'jquery.disableWhileLoading'
import 'compiled/jquery/ModuleSequenceFooter'
import LockManager from '../blueprint_courses/apps/LockManager'

const lockManager = new LockManager()
lockManager.init({ itemType: 'quiz', page: 'show' })

$(() => {
  inputMethods.setWidths()
  $('.answer input[type=text]').each(function () {
    $(this).width(($(this).val().length || 11) * 9.5)
  })

  $('.download_submissions_link').click(function (event) {
    event.preventDefault()
    INST.downloadSubmissions($(this).attr('href'))
  })

    // load in regrade versions
  if (ENV.SUBMISSION_VERSIONS_URL && !ENV.IS_SURVEY) {
    const versions = $('#quiz-submission-version-table')
    versions.css({height: '100px'})
    const dfd = $.get(ENV.SUBMISSION_VERSIONS_URL, (html) => {
      versions.html(html)
      versions.css({height: 'auto'})
    })
    versions.disableWhileLoading(dfd)
  }

    // Add module sequence footer
  $('#module_sequence_footer').moduleSequenceFooter({
    courseID: ENV.COURSE_ID,
    assetType: 'Quiz',
    assetID: ENV.QUIZ.id,
    location
  })
})
