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
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/media-comments'
import '@canvas/media-comments/jquery/mediaCommentThumbnail'
import {setup, teardown} from '../index'
import {waitFor} from '@testing-library/dom'

describe('submissions', () => {
  beforeEach(async () => {
    // Mock jQuery's ajaxJSON method
    $.ajaxJSON = jest.fn()

    fakeENV.setup()
    window.ENV.SUBMISSION = {
      user_id: 1,
      assignment_id: 27,
      submission: {},
    }

    document.body.innerHTML = `
      <div id="fixtures">
        <div id='preview_frame'>
          <div id='preview_frame'>
            <div id='rubric_holder'>
            </div>
            <div class='save_rubric_button'>
            </div>
            <a class='update_submission_url' href='submission_data_url.com' title='POST'></a>
            <textarea class='grading_value'>A</textarea>
            <div class='submission_header'>
            </div>
            <div class='comments_link'>
            </div>
            <div class='attach_comment_file_link'>
            </div>
            <div class='delete_comment_attachment_link'>
            </div>
            <div class='comments'>
              <div class='comment_list'>
                <div class='comment ' id='submission_comment_1'>
                  <div class='comment'>
                    <span class='comment_content' data-content='<div>My html comment</div>'></span>
                  </div>
                </div>
                <div class='comment ' id='submission_comment_2'>
                  <div class='comment'>
                    <span class='comment_content' data-content='My\nformatted\ncomment'></span>
                  </div>
                </div>
                <div class='comment_media'>
                  <span class='media_comment_id'>my_comment_id</span>
                  <div class='media_comment_content'></div>
                  <div class='play_comment_link'></div>
                </div>
              </div>
            </div>
            <textarea class='grading_comment'>Hello again.</textarea>
            <input type='checkbox' id='submission_group_comment' checked>
            <div class='save_comment_button'>
            </div>
          </div>
        </div>
      </div>
    `

    setup()
    // Wait for document ready handlers to execute
    const readyCallback = jest.fn()
    $(document).ready(readyCallback)
    $(document).trigger('ready')
    await waitFor(() => expect(readyCallback).toHaveBeenCalled())
  })

  afterEach(() => {
    jest.clearAllMocks()
    teardown()
    fakeENV.teardown()
  })

  test('comment_change posts to update_submission_url', async () => {
    // Set up the comment and trigger the save
    $('.grading_comment').val('Test comment.')
    $('.save_comment_button').click()

    // Verify the AJAX call
    expect($.ajaxJSON).toHaveBeenCalledTimes(1)
    expect($.ajaxJSON).toHaveBeenCalledWith(
      'submission_data_url.com',
      'POST',
      expect.objectContaining({
        'submission[comment]': 'Test comment.',
        'submission[assignment_id]': 27,
        'submission[user_id]': 1,
      }),
      expect.any(Function)
    )
  })

  test('comment_change submits the grading_comment but not grade', async () => {
    $('.grading_comment').val('Hello again.')
    $('.save_comment_button').click()

    expect($.ajaxJSON).toHaveBeenCalledTimes(1)
    expect($.ajaxJSON).toHaveBeenCalledWith(
      expect.any(String),
      expect.any(String),
      expect.objectContaining({
        'submission[comment]': 'Hello again.',
        'submission[assignment_id]': 27,
        'submission[user_id]': 1,
      }),
      expect.any(Function)
    )

    const [, , formData] = $.ajaxJSON.mock.calls[0]
    expect(formData).not.toHaveProperty('submission[grade]')
  })

  test('comment_change submits the user_id of the submission if present', async () => {
    $('.grading_comment').val('Hello again.')
    $('.save_comment_button').click()

    const [, , formData] = $.ajaxJSON.mock.calls[0]
    expect(formData['submission[user_id]']).toBe(1)
  })

  test('comment_change submits the anonymous_id of the submission if the user_id is not present', async () => {
    delete window.ENV.SUBMISSION.user_id
    window.ENV.SUBMISSION.anonymous_id = 'zxcvb'

    $('.grading_comment').val('Hello again.')
    $('.save_comment_button').click()

    const [, , formData] = $.ajaxJSON.mock.calls[0]
    expect(formData['submission[anonymous_id]']).toBe('zxcvb')
  })

  test('comment_change does not submit if no comment', async () => {
    $('.grading_comment').val('')
    $('.save_comment_button').click()
    expect($.ajaxJSON).not.toHaveBeenCalled()
  })

  test('html comment does not render with html tags', async () => {
    const htmlComment = document.getElementById('submission_comment_1')
    expect(htmlComment).not.toBeNull()
    expect(htmlComment.textContent.trim()).toBe('My html comment')
  })

  test('comment with \\n is formatted properly', async () => {
    const formattedComment = document.getElementById('submission_comment_2')
    expect(formattedComment).not.toBeNull()
    const commentContent = formattedComment.querySelector('span')
    expect(commentContent).not.toBeNull()
    expect(commentContent.innerHTML).toBe('My<br>\nformatted<br>\ncomment')
  })
})
