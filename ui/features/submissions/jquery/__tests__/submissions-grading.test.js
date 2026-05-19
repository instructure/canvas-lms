/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.ajaxJSON'
import {setup, teardown} from '../index'
import {waitFor} from '@testing-library/dom'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer()

describe('submissions grading', () => {
  beforeAll(() => {
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(async () => {
    fakeENV.setup({
      SUBMISSION: {
        user_id: 1,
        assignment_id: 27,
        submission: {},
      },
    })

    document.body.innerHTML = `
      <div id="fixtures">
        <div id='preview_frame'>
          <a class='update_submission_url' href='submission_data_url.com' title='POST'></a>
          <textarea class='grading_value'>85</textarea>
          <div class='submission_header'></div>
          <div class='comments_link'></div>
          <div class='attach_comment_file_link'></div>
          <div class='delete_comment_attachment_link'></div>
          <div class='comments'>
            <div class='comment_list'></div>
          </div>
          <textarea class='grading_comment'></textarea>
          <div id="textarea-error-container"></div>
          <input type='checkbox' id='submission_group_comment'>
          <div class='save_comment_button'></div>
        </div>
      </div>
    `

    setup()
    const readyCallback = vi.fn()
    $(document).ready(readyCallback)
    $(document).trigger('ready')
    await waitFor(() => expect(readyCallback).toHaveBeenCalled())
  })

  afterEach(() => {
    teardown()
    fakeENV.teardown()
  })

  // Regression test for CFA-696: a missing semicolon (introduced by biome during
  // TypeScriptify) caused ASI to merge two statements into one, so
  // delocalizeGrade's string return value was invoked as a function, throwing
  // TypeError and preventing the grade from being saved.
  test('grading_change submits the grade value (regression: ASI semicolon bug)', async () => {
    let capturedRequest
    server.use(
      http.post('http://localhost/submission_data_url.com', async ({request}) => {
        capturedRequest = await request.formData()
        return HttpResponse.json({
          submission: {
            user_id: '1',
            assignment_id: 27,
            submission_comments: [],
          },
        })
      }),
    )

    // Make .grading_value "visible" — JSDOM has no layout engine so offsetWidth
    // is 0 by default, which causes jQuery's :visible check to skip the code path.
    const textarea = document.querySelector('.grading_value')
    Object.defineProperty(textarea, 'offsetWidth', {get: () => 100, configurable: true})
    Object.defineProperty(textarea, 'offsetHeight', {get: () => 30, configurable: true})

    // Trigger grading_change — with the bug this threw:
    //   TypeError: GradeFormatHelper.delocalizeGrade(...) is not a function
    expect(() => $(document).triggerHandler('grading_change')).not.toThrow()

    await waitFor(() => expect(capturedRequest).toBeDefined())
    expect(capturedRequest.get('submission[grade]')).toBe('85')
    expect(capturedRequest.get('submission[assignment_id]')).toBe('27')
  })
})
