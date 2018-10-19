/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {setup, teardown} from 'submissions'
import fakeENV from 'helpers/fakeENV'
import 'jquery.ajaxJSON'

QUnit.module('submissions', {
  setup() {
    sinon.spy($, 'ajaxJSON')
    fakeENV.setup()
    ENV.SUBMISSION = {
      user_id: 1,
      assignment_id: 27,
      submission: {}
    }
    $('#fixtures').html(`
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
    `)
    setup()
  },

  teardown() {
    $.ajaxJSON.restore()
    teardown()
    fakeENV.teardown()
    $('#fixtures').html('')
  }
})

test('comment_change posts to update_submission_url', () => {
  $('.grading_comment').val('Hello again.')
  $(document).triggerHandler('comment_change')
  equal($.ajaxJSON.getCall(0).args[0], 'submission_data_url.com')
  equal($.ajaxJSON.getCall(0).args[1], 'POST')
})

test('comment_change submits the grading_comment but not grade', () => {
  $('.grading_comment').val('Hello again.')
  $('.save_comment_button').click()
  equal($.ajaxJSON.getCall(0).args[2]['submission[user_id]'], 1)
  equal($.ajaxJSON.getCall(0).args[2]['submission[assignment_id]'], 27)
  equal($.ajaxJSON.getCall(0).args[2]['submission[comment]'], 'Hello again.')
  equal($.ajaxJSON.getCall(0).args[2]['submission[grade]'], undefined)
  equal($.ajaxJSON.getCall(0).args[2]['submission[group_comment]'], '1')
})

test('comment_change does not submit if no comment', () => {
  $('.grading_comment').val('')
  $('.save_comment_button').click()
  ok($.ajaxJSON.notCalled)
})

test('grading_change posts to update_submission_url', () => {
  $(document).triggerHandler('grading_change')
  equal($.ajaxJSON.getCall(0).args[0], 'submission_data_url.com')
  equal($.ajaxJSON.getCall(0).args[1], 'POST')
})

test('grading_change submits the grade but not grading_comment', () => {
  $(document).triggerHandler('grading_change')
  equal($.ajaxJSON.getCall(0).args[2]['submission[user_id]'], 1)
  equal($.ajaxJSON.getCall(0).args[2]['submission[assignment_id]'], 27)
  equal($.ajaxJSON.getCall(0).args[2]['submission[grade]'], 'A')
  equal($.ajaxJSON.getCall(0).args[2]['submission[comment]'], undefined)
})

test('clicking a media comment passes the opening element to the window', () => {
  const commentLink = $('#preview_frame .play_comment_link')
  sinon.stub($.fn, 'mediaComment')

  commentLink.click()
  const [,,,openingElement] = $.fn.mediaComment.firstCall.args
  strictEqual(openingElement, commentLink.get(0))

  $.fn.mediaComment.restore()
})
