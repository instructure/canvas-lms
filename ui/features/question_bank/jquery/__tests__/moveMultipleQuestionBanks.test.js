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
import moveMultipleQuestionBanks from '../moveMultipleQuestionBanks'

describe('Move Multiple Question Banks', () => {
  let $modal

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="fixtures">
        <div id="parent">
          <div id="move_question_dialog"></div>
          <a class="ui-dialog-titlebar-close" href="#"></a>
        </div>
      </div>
    `
    $modal = $('#fixtures')
  })

  afterEach(() => {
    $('#fixtures').empty()
    jest.restoreAllMocks() // Restore all mocks to their original value
  })

  test('is an object', () => {
    expect(typeof moveMultipleQuestionBanks).toBe('object')
  })

  test('set focus to the delete button when dialog opens', () => {
    // Mocking methods inside moveMultipleQuestionBanks
    jest.spyOn(moveMultipleQuestionBanks, 'prepDialog').mockImplementation(() => {})
    jest.spyOn(moveMultipleQuestionBanks, 'showDialog').mockImplementation(() => {})
    jest.spyOn(moveMultipleQuestionBanks, 'loadData').mockImplementation(() => {})

    const focusesButton = $modal.find('.ui-dialog-titlebar-close')[0]
    moveMultipleQuestionBanks.onClick({preventDefault: () => {}})
    expect(document.activeElement).toBe(focusesButton)
  })
})
