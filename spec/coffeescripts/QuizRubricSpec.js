/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import QuizRubric from '@canvas/quizzes/jquery/quiz_rubric'
import $ from 'jquery'
import 'jquery-migrate'

const assignmentRubricHtml = `
  <div id='test-rubrics-wrapper'>
    <div id="rubrics" class="rubric_dialog">
      <a href='#' class='btn add_rubric_link'>Add Rubric</a>
    </div>
    <script>
      window.ENV = window.ENV || {};
      window.ENV.ROOT_OUTCOME_GROUP = {};
      var event = document.createEvent('Event');
      event.initEvent('rubricEditDataReady', true, true);
      document.dispatchEvent(event)
    </script>
  </div>
`

const defaultRubric = `
  <div id='default_rubric'>
    DUMMY CONTENT FOR RUBRIC FORM
  </div>
`

QUnit.module('QuizRubric', {
  setup() {
    $('#fixtures').append(defaultRubric)
  },
  teardown() {
    $('#test-rubrics-wrapper').remove()
    $('#fixtures').html('')
    $('.ui-dialog').remove()
  },
})

test('rubric editing event loads the rubric form', async () => {
  await QuizRubric.createRubricDialog('#', assignmentRubricHtml)
  $('.add_rubric_link').click()
  const contentIndex = $('#rubrics').html().indexOf('DUMMY CONTENT FOR RUBRIC FORM')
  ok(contentIndex > 0)
})
