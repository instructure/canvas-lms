/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import fakeENV from '@canvas/test-utils/fakeENV'
import $ from 'jquery'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import SpeedGrader from '../speed_grader'
import SpeedGraderHelpers from '../speed_grader_helpers'

const server = setupServer()

describe('SpeedGrader Timeouts', () => {
  let documentLocation = ''
  let documentLocationHash = ''

  beforeAll(() => {
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    // Set up DOM elements
    document.body.innerHTML = `
      <div id="hide-assignment-grades-tray"></div>
      <div id="post-assignment-grades-tray"></div>
      <div id="speed_grader_assessment_audit_tray_mount_point"></div>
      <span id="speed_grader_post_grades_menu_mount_point"></span>
      <span id="speed_grader_settings_mount_point"></span>
      <div id="speed_grader_rubric_assessment_tray_wrapper"><div>
      <div id="speed_grader_assessment_audit_button_mount_point"></div>
      <div id="speed_grader_submission_comments_download_mount_point"></div>
      <div id="speed_grader_hidden_submission_pill_mount_point"></div>
      <div id="grades-loading-spinner"></div>
      <div id="grading"></div>
      <div id="settings_form">
        <select id="eg_sort_by" name="eg_sort_by">
          <option value="alphabetically"></option>
          <option value="submitted_at"></option>
          <option value="submission_status"></option>
          <option value="randomize"></option>
        </select>
        <input id="hide_student_names" type="checkbox" name="hide_student_names">
        <input id="enable_speedgrader_grade_by_question" type="checkbox" name="enable_speedgrader_grade_by_question">
        <button type="submit" class="submit_button"></button>
      </div>
      <div id="speed_grader_timeout_alert"></div>
    `

    const history = {
      back: jest.fn(),
      length: 1,
      popState: jest.fn(),
      pushState: jest.fn(),
      replaceState: jest.fn(),
    }

    jest.spyOn(SpeedGraderHelpers, 'getHistory').mockReturnValue(history)
    jest
      .spyOn(SpeedGraderHelpers, 'setLocation')
      .mockImplementation(url => (documentLocation = url))
    jest.spyOn(SpeedGraderHelpers, 'getLocation').mockImplementation(() => documentLocation)
    jest
      .spyOn(SpeedGraderHelpers, 'setLocationHash')
      .mockImplementation(hash => (documentLocationHash = hash))
    jest.spyOn(SpeedGraderHelpers, 'getLocationHash').mockImplementation(() => documentLocationHash)
    jest.spyOn(SpeedGraderHelpers, 'reloadPage').mockImplementation(() => {})

    // Mock fetch for timeout simulation
    server.use(
      http.get('*', () => {
        return new HttpResponse(null, {
          status: 504,
          headers: {'Content-Type': 'text/html'},
        })
      }),
    )

    // Set up ENV
    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false,
      assignment_title: 'Assignment Title',
      SINGLE_NQ_SESSION_ENABLED: true,
    })

    // Stub domReady to prevent actual initialization
    jest.spyOn(SpeedGrader.EG, 'domReady').mockImplementation(() => {})
  })

  afterEach(() => {
    document.body.innerHTML = ''
    fakeENV.teardown()
    jest.restoreAllMocks()
    server.resetHandlers()
  })

  describe('when the gateway times out', () => {
    it('excludes a link to the "large course" setting when the feature is disabled', async () => {
      ENV.filter_speed_grader_by_student_group_feature_enabled = false

      SpeedGrader.setup()
      await new Promise(resolve => setTimeout(resolve, 2))

      expect($('#speed_grader_timeout_alert a')).toHaveLength(0)
    })
  })
})
