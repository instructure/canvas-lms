/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import GradingForm from '../grading_form'
import $ from 'jquery'

const gradingFormHtml = `
  <form id='update_history_form'>
    <input class='question_input'/>
  </form>
`

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

describe('GradingForm', () => {
  $('#fixtures').append(gradingFormHtml)

  // fails in Jest, passes in QUnit
  test.skip('no suprious submits', function () {
    const scoringSnapshot = {}
    const gradingForm = new GradingForm(scoringSnapshot)
    gradingForm.preventInsanity()
    let submitCounter = 0
    const $form = $('#update_history_form')
    $form.submit(e => {
      submitCounter += 1
      e.preventDefault()
      return false
    })

    let eventCount = 0
    while (eventCount <= 10) {
      const keydownEvent = $.Event('keydown')
      keydownEvent.keyCode = 13
      $('.question_input').trigger(keydownEvent)
      eventCount += 1
    }
    const keyupEvent = $.Event('keyup')
    keyupEvent.keyCode = 13
    $('.question_input').trigger(keyupEvent)
    expect(submitCounter).toBe(1)
  })

  // fails in Jest, passes in QUnit
  test.skip('handler passed in is called for key enter', function () {
    const scoringSnapshot = {}
    const onInputChange = jest.fn()
    const gradingForm = new GradingForm(scoringSnapshot)
    gradingForm.preventInsanity(onInputChange)

    const keydownEvent = $.Event('keydown')
    keydownEvent.keyCode = 13
    $('.question_input').trigger(keydownEvent)

    expect(onInputChange).toHaveBeenCalledTimes(1)
  })

  test('handler paased in is not called for other keys', function () {
    const scoringSnapshot = {}
    const onInputChange = jest.fn()
    const gradingForm = new GradingForm(scoringSnapshot)
    gradingForm.preventInsanity(onInputChange)

    const keydownEvent = $.Event('keydown')
    keydownEvent.keyCode = 5
    $('.question_input').trigger(keydownEvent)

    expect(onInputChange).not.toHaveBeenCalled()
  })

  $('#fixtures').html('')
})
