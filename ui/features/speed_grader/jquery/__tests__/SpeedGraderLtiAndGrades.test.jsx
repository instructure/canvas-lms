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
import fakeENV from '@canvas/test-utils/fakeENV'
import {unescape} from '@instructure/html-escape'
import SpeedGrader from '../speed_grader'
import SpeedGraderHelpers from '../speed_grader_helpers'
import '@canvas/jquery/jquery.ajaxJSON'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

// Mock SpeedGraderSettingsMenu
jest.mock('../../react/SpeedGraderSettingsMenu', () => ({
  __esModule: true,
  default: () => null,
}))

const server = setupServer()

describe('SpeedGrader', () => {
  let fixtures

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

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

  beforeAll(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
  })

  afterAll(() => {
    fixtures.remove()
  })

  describe('LTI Launch', () => {
    let $div
    let history

    beforeEach(() => {
      history = {
        back: jest.fn(),
        length: 1,
        popState: jest.fn(),
        pushState: jest.fn(),
        replaceState: jest.fn(),
      }

      jest.spyOn(SpeedGraderHelpers, 'getHistory').mockReturnValue(history)
      jest.spyOn(SpeedGraderHelpers, 'setLocation').mockImplementation(_url => {})
      jest.spyOn(SpeedGraderHelpers, 'getLocation').mockImplementation(() => '')
      jest.spyOn(SpeedGraderHelpers, 'setLocationHash').mockImplementation(_hash => {})
      jest.spyOn(SpeedGraderHelpers, 'getLocationHash').mockImplementation(() => '')
      jest.spyOn(SpeedGraderHelpers, 'reloadPage').mockImplementation(() => {})

      fakeENV.setup({
        assignment_id: '17',
        course_id: '29',
        grading_role: 'moderator',
        help_url: 'example.com/support',
        show_help_menu_item: false,
        SINGLE_NQ_SESSION_ENABLED: true,
      })

      fixtures.innerHTML = requiredDOMFixtures + '<div id="iframe_holder">not empty</div>'
      $div = $(fixtures).find('#iframe_holder')

      server.use(
        http.get('/api/v1/courses/:courseId/grading_periods', () => {
          return HttpResponse.json({
            grading_periods: [],
          })
        }),
        http.get('*', () => {
          return HttpResponse.json({})
        }),
        http.post('*', () => {
          return HttpResponse.json({})
        }),
        http.put('*', () => {
          return HttpResponse.json({})
        }),
      )

      jest.spyOn($, 'getJSON')
      jest.spyOn(SpeedGrader.EG, 'domReady')

      // Mock $.ajaxJSON.storeRequest
      $.ajaxJSON.storeRequest = jest.fn()
      $.ajaxJSON.unhandledXHRs = []

      SpeedGrader.setup()
      ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
    })

    afterEach(() => {
      SpeedGrader.teardown()
      fakeENV.teardown()
      fixtures.innerHTML = ''
      jest.restoreAllMocks()
      ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
    })

    it('contains iframe with the escaped student submission url', () => {
      const retrieveUrl = '/course/1/external_tools/retrieve?display=borderless&assignment_id=22'
      const url = 'http://www.example.com/lti/launch/user/4'
      const buildIframeStub = jest.spyOn(SpeedGraderHelpers, 'buildIframe')
      const submission = {
        external_tool_url: url,
        resource_link_lookup_uuid: '0b8fbc86-fdd7-4950-852d-ffa789b37ff2',
      }

      SpeedGrader.EG.renderLtiLaunch($div, retrieveUrl, submission)

      const [srcUrl] = buildIframeStub.mock.calls[0]
      const fullRetrieveUrl =
        retrieveUrl + '&resource_link_lookup_uuid=0b8fbc86-fdd7-4950-852d-ffa789b37ff2'
      expect(unescape(srcUrl)).toContain(fullRetrieveUrl)
      expect(unescape(srcUrl)).toContain(encodeURIComponent(url))
    })

    it('includes grade_by_question param when quiz and flag + setting are enabled', () => {
      ENV.NQ_GRADE_BY_QUESTION_ENABLED = true
      ENV.GRADE_BY_QUESTION = true
      const originalJsonData = window.jsonData
      window.jsonData = {quiz_lti: true}

      const retrieveUrl = '/course/1/external_tools/retrieve?display=borderless&assignment_id=22'
      const url = 'http://www.example.com/lti/launch/user/4'
      const buildIframeStub = jest.spyOn(SpeedGraderHelpers, 'buildIframe')
      const submission = {
        external_tool_url: url,
        resource_link_lookup_uuid: '0b8fbc86-fdd7-4950-852d-ffa789b37ff2',
      }

      SpeedGrader.EG.renderLtiLaunch($div, retrieveUrl, submission)

      const [srcUrl] = buildIframeStub.mock.calls[0]
      const {searchParams} = new URL(decodeURIComponent(unescape(srcUrl).match(/http.*/)[0]))
      expect(searchParams.get('grade_by_question_enabled')).toBe('true')

      window.jsonData = originalJsonData
    })

    it('can be fullscreened', () => {
      const retrieveUrl =
        'canvas.com/course/1/external_tools/retrieve?display=borderless&assignment_id=22'
      const url = 'http://www.example.com/lti/launch/user/4'
      const buildIframeStub = jest.spyOn(SpeedGraderHelpers, 'buildIframe')
      const submission = {
        url,
        resource_link_lookup_uuid: '0b8fbc86-fdd7-4950-852d-ffa789b37ff2',
      }

      SpeedGrader.EG.renderLtiLaunch($div, retrieveUrl, submission)

      const [, {allowfullscreen}] = buildIframeStub.mock.calls[0]
      expect(allowfullscreen).toBe(true)
    })

    it('allows options defined in iframeAllowances()', () => {
      const retrieveUrl =
        'canvas.com/course/1/external_tools/retrieve?display=borderless&assignment_id=22'
      const url = 'http://www.example.com/lti/launch/user/4'
      const buildIframeStub = jest.spyOn(SpeedGraderHelpers, 'buildIframe')
      const submission = {
        url,
        resource_link_lookup_uuid: '0b8fbc86-fdd7-4950-852d-ffa789b37ff2',
      }

      SpeedGrader.EG.renderLtiLaunch($div, retrieveUrl, submission)

      const [, {allow}] = buildIframeStub.mock.calls[0]
      expect(allow).toBe(ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; '))
    })
  })

  describe('Grade Display', () => {
    beforeEach(() => {
      fakeENV.setup()
      fixtures.innerHTML = requiredDOMFixtures

      server.use(
        http.get('/api/v1/courses/:courseId/grading_periods', () => {
          return HttpResponse.json({
            grading_periods: [],
          })
        }),
        http.get('*', () => {
          return HttpResponse.json({})
        }),
        http.post('*', () => {
          return HttpResponse.json({})
        }),
        http.put('*', () => {
          return HttpResponse.json({})
        }),
      )

      SpeedGrader.setup()
    })

    afterEach(() => {
      SpeedGrader.teardown()
      fakeENV.teardown()
      fixtures.innerHTML = ''
    })

    it('returns an empty string for "entered" if submission is null', () => {
      const grade = SpeedGrader.EG.getGradeToShow(null)
      expect(grade.entered).toBe('')
    })

    it('returns an empty string for "entered" if submission is undefined', () => {
      const grade = SpeedGrader.EG.getGradeToShow(undefined)
      expect(grade.entered).toBe('')
    })

    it('returns an empty string for "entered" if submission has no excused or grade', () => {
      const grade = SpeedGrader.EG.getGradeToShow({})
      expect(grade.entered).toBe('')
    })

    it('returns excused for "entered" if excused is true', () => {
      const grade = SpeedGrader.EG.getGradeToShow({excused: true})
      expect(grade.entered).toBe('EX')
    })

    it('returns negated points_deducted for "pointsDeducted"', () => {
      const grade = SpeedGrader.EG.getGradeToShow({
        points_deducted: 123,
      })
      expect(grade.pointsDeducted).toBe('-123')
    })

    it('returns values based on grades if submission has no excused and grade is not a float', () => {
      const grade = SpeedGrader.EG.getGradeToShow({
        grade: 'some_grade',
        entered_grade: 'entered_grade',
      })
      expect(grade.entered).toBe('entered_grade')
      expect(grade.adjusted).toBe('some_grade')
    })

    it('returns values based on grades', () => {
      const grade = SpeedGrader.EG.getGradeToShow({
        grade: 15,
        score: 25,
        entered_grade: 30,
        points_deducted: 15,
      })
      expect(grade.entered).toBe('30')
      expect(grade.adjusted).toBe('15')
      expect(grade.pointsDeducted).toBe('-15')
    })
  })
})
