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

import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import SpeedGrader from '../speed_grader'
import '@canvas/jquery/jquery.ajaxJSON'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

describe('SpeedGrader Media Comments', () => {
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
  `

  const commentBlankHtml = `
    <div id="comments">
    </div>
    <div id="comment_blank">
      <a class="play_comment_link"></a>
      <div class="comment">
        <div class="comment_flex">
          <span class="comment"></span>
        </div>
      </div>
    </div>
  `

  let fixtures

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    fixtures.innerHTML = `${requiredDOMFixtures}${commentBlankHtml}`

    fakeENV.setup({
      assignment_id: '17',
      course_id: '29',
      grading_role: 'moderator',
      help_url: 'example.com/support',
      show_help_menu_item: false,
      assignment: {
        assignment_id: '17',
        course_id: '29',
      },
    })

    server.use(
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
    jest.spyOn(window.$, 'getJSON').mockImplementation(() => ({always: () => {}}))
    jest.spyOn(SpeedGrader.EG, 'domReady').mockImplementation(() => {})

    window.INST = {
      kalturaSettings: {
        resource_domain: 'example.com',
        partner_id: 'asdf',
      },
    }

    window.jsonData = {
      id: 27,
      GROUP_GRADING_MODE: false,
      points_possible: 10,
    }

    SpeedGrader.EG.currentStudent = {
      id: 4,
      name: 'Guy B. Studying',
      submission_state: 'not_graded',
      submission: {
        score: 7,
        grade: 70,
        submission_comments: [
          {
            group_comment_id: null,
            publishable: false,
            anonymous: false,
            assessment_request_id: null,
            attachment_ids: '',
            author_id: 1000,
            author_name: 'An Author',
            comment: 'a comment!',
            context_id: 1,
            context_type: 'Course',
            created_at: '2016-07-12T23:47:34Z',
            hidden: false,
            id: 11,
            media_comment_id: 3,
            media_comment_type: 'video',
            posted_at: 'Jul 12 at 5:47pm',
            submission_id: 1,
            teacher_only_comment: false,
            updated_at: '2016-07-12T23:47:34Z',
          },
        ],
      },
    }

    window.ENV = {
      SUBMISSION: {
        grading_role: 'teacher',
      },
      RUBRIC_ASSESSMENT: {
        assessment_type: 'grading',
        assessor_id: 1,
      },
      assignment_id: '17',
      course_id: '29',
      help_url: 'example.com/support',
      show_help_menu_item: false,
    }

    SpeedGrader.setup()
  })

  afterEach(() => {
    SpeedGrader.teardown()
    jest.restoreAllMocks()
    fixtures.remove()
    fakeENV.teardown()
    delete window.jsonData
    delete window.ENV
    delete window.INST
  })

  const awhile = (milliseconds = 2) => new Promise(resolve => setTimeout(resolve, milliseconds))

  it('adds screenreader text to media comment thumbnails', async () => {
    SpeedGrader.EG.showDiscussion()
    await awhile()
    const screenreaderText = document
      .querySelector('.play_comment_link .screenreader-only')
      .textContent.trim()
    expect(screenreaderText).toBe('Play media comment by An Author from Jul 12, 2016 at 11:47pm.')
  })
})
