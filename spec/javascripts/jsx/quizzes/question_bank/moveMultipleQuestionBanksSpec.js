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

import moveMultipleQuestionBanks from 'jsx/quizzes/question_bank/moveMultipleQuestionBanks'
import $ from 'jquery'

let $modal = null

QUnit.module('Move Multiple Question Banks', {
  setup() {
    $modal = $('#fixtures').html(
      "<div id='parent'>" +
        "  <div id='move_question_dialog'>" +
        '  </div>' +
        "  <a class='ui-dialog-titlebar-close' href='#'>" +
        '  </a>' +
        '  </div>' +
        '</div>'
    )
  },

  teardown() {
    $('#fixtures').empty()
  }
})

test('is an object', () => {
  ok(typeof moveMultipleQuestionBanks === 'object')
})

test('set focus to the delete button when dialog opens', () => {
  sinon.stub(moveMultipleQuestionBanks, 'prepDialog')
  sinon.stub(moveMultipleQuestionBanks, 'showDialog')
  sinon.stub(moveMultipleQuestionBanks, 'loadData')
  const focusesButton = $modal.find('.ui-dialog-titlebar-close')[0]
  moveMultipleQuestionBanks.onClick({preventDefault: e => e})
  ok(focusesButton === document.activeElement)
})
