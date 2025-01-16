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

import $ from 'jquery'
import 'jquery-migrate'
import '@canvas/jquery/jquery.ajaxJSON'
import fakeENV from '@canvas/test-utils/fakeENV'
import SpeedGrader from '../speed_grader'

// Mock SpeedGraderSettingsMenu
jest.mock('../../react/SpeedGraderSettingsMenu', () => ({
  __esModule: true,
  default: () => null,
}))

describe('SpeedGrader Attachments', () => {
  let fixtures
  const requiredDOMFixtures = `
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
  `

  let originalWindowJSONData
  let originalStudent

  beforeAll(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)

    // Mock jQuery ajaxJSON
    $.ajaxJSON = jest.fn()
    $.ajaxJSON.unhandledXHRs = []
  })

  afterAll(() => {
    fixtures.remove()
  })

  beforeEach(() => {
    fakeENV.setup({
      assignment_id: '27',
      course_id: '1',
      help_url: 'example.com/help',
      settings_url: 'example.com/settings',
    })
    originalWindowJSONData = window.jsonData
    window.jsonData = {
      id: 27,
      GROUP_GRADING_MODE: false,
      points_possible: 10,
    }
    originalStudent = SpeedGrader.EG.currentStudent
    fixtures.innerHTML = requiredDOMFixtures
    SpeedGrader.setup()
  })

  afterEach(() => {
    SpeedGrader.teardown()
    window.jsonData = originalWindowJSONData
    SpeedGrader.EG.currentStudent = originalStudent
    fakeENV.teardown()
    fixtures.innerHTML = ''
    jest.clearAllMocks()
  })

  describe('attachment iframe contents', () => {
    it('returns an image tag for image attachments', () => {
      const attachment = {id: 1, mime_class: 'image'}
      const contents = SpeedGrader.EG.attachmentIframeContents(attachment)
      expect(contents).toMatch(/<img/)
    })

    it('returns an iframe for html attachments', () => {
      const attachment = {id: 1, mime_class: 'html', submitted_to_turnitin: false}
      const contents = SpeedGrader.EG.attachmentIframeContents(attachment)
      expect(contents).toMatch(/<iframe/)
    })

    it('returns an iframe for code attachments', () => {
      const attachment = {id: 1, mime_class: 'code'}
      const contents = SpeedGrader.EG.attachmentIframeContents(attachment)
      expect(contents).toMatch(/<iframe/)
    })

    it('returns an iframe for pdf attachments', () => {
      const attachment = {id: 1, mime_class: 'pdf', canvadoc_url: 'fake_url'}
      const contents = SpeedGrader.EG.attachmentIframeContents(attachment)
      expect(contents).toMatch(/<iframe/)
    })
  })

  describe('iframe holder', () => {
    it('clears the contents of the iframe holder', () => {
      const $div = $("<div id='iframe_holder'>not empty</div>").appendTo(document.body)
      SpeedGrader.EG.emptyIframeHolder($div)
      expect($div.is(':empty')).toBe(true)
      $div.remove()
    })
  })
})
