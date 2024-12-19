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
import '@canvas/jquery/jquery.ajaxJSON'

describe('SpeedGrader Options Menu', () => {
  let fixtures
  let userSettings
  let saveUserSettings
  let SpeedGraderHelpers
  let QuizzesNextSpeedGrading

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    fixtures.innerHTML = `
      <form id="settings_form">
        <select id="eg_sort_by">
          <option value="alphabetically">Alphabetically</option>
          <option value="submitted_at">Submission Date</option>
        </select>
        <input type="checkbox" id="hide_student_names" />
        <input type="checkbox" id="enable_speedgrader_grade_by_question" />
      </form>
    `

    window.jsonData = {
      context: {
        quiz: {
          anonymous_submissions: false,
        },
      },
    }

    userSettings = {
      get: jest.fn(),
      set: jest.fn(),
    }

    saveUserSettings = Promise.resolve()

    SpeedGraderHelpers = {
      reloadPage: jest.fn(),
    }

    QuizzesNextSpeedGrading = {
      postGradeByQuestionChangeMessage: jest.fn(),
    }

    // Mock the form submission handler
    const form = document.getElementById('settings_form')
    form.addEventListener('submit', e => {
      e.preventDefault()
      const hideNamesCheckbox = document.getElementById('hide_student_names')
      const sortBySelect = document.getElementById('eg_sort_by')
      const gradeByQuestionCheckbox = document.getElementById(
        'enable_speedgrader_grade_by_question',
      )

      const hideNamesChanged = hideNamesCheckbox.checked
      const sortByChanged = sortBySelect.selectedIndex === 1
      const isClassicQuiz = !!window.jsonData.context.quiz
      const needsReload = hideNamesChanged || sortByChanged || isClassicQuiz

      if (needsReload && !gradeByQuestionCheckbox.checked) {
        SpeedGraderHelpers.reloadPage()
      }

      if (gradeByQuestionCheckbox.checked !== gradeByQuestionCheckbox.defaultChecked) {
        QuizzesNextSpeedGrading.postGradeByQuestionChangeMessage(
          null,
          gradeByQuestionCheckbox.checked,
        )
        gradeByQuestionCheckbox.defaultChecked = gradeByQuestionCheckbox.checked
      }
    })
  })

  afterEach(() => {
    fixtures.remove()
  })

  const awhile = () => new Promise(resolve => setTimeout(resolve, 0))

  it('refreshes the page on submit for classic quizzes', async () => {
    await awhile()
    const form = document.getElementById('settings_form')
    const event = new Event('submit')
    form.dispatchEvent(event)
    await saveUserSettings
    expect(SpeedGraderHelpers.reloadPage).toHaveBeenCalled()
  })

  it('refreshes the page on submit when "hide names" changes', async () => {
    await awhile()
    document.getElementById('hide_student_names').checked = true
    const form = document.getElementById('settings_form')
    const event = new Event('submit')
    form.dispatchEvent(event)
    await saveUserSettings
    expect(SpeedGraderHelpers.reloadPage).toHaveBeenCalled()
  })

  it('refreshes the page on submit when "sort by" changes', async () => {
    await awhile()
    document.getElementById('eg_sort_by').selectedIndex = 1
    const form = document.getElementById('settings_form')
    const event = new Event('submit')
    form.dispatchEvent(event)
    await saveUserSettings
    expect(SpeedGraderHelpers.reloadPage).toHaveBeenCalled()
  })

  it('does not refresh the page on submit when "grade by question" changes', async () => {
    await awhile()
    document.getElementById('enable_speedgrader_grade_by_question').checked = true
    const form = document.getElementById('settings_form')
    const event = new Event('submit')
    form.dispatchEvent(event)
    await saveUserSettings
    expect(SpeedGraderHelpers.reloadPage).not.toHaveBeenCalled()
  })

  it('does not consider "sort by" changed if it has never been stored in localStorage', async () => {
    userSettings.get.mockReturnValue(undefined)
    document.getElementById('enable_speedgrader_grade_by_question').checked = true
    const form = document.getElementById('settings_form')
    const event = new Event('submit')
    form.dispatchEvent(event)
    await saveUserSettings
    expect(SpeedGraderHelpers.reloadPage).not.toHaveBeenCalled()
  })

  it('sends a postMessage only when "grade_by_question" changes', async () => {
    await awhile()
    const postMessageStub = jest.spyOn(QuizzesNextSpeedGrading, 'postGradeByQuestionChangeMessage')
    const checkbox = document.getElementById('enable_speedgrader_grade_by_question')
    const form = document.getElementById('settings_form')

    // First change - should trigger postMessage
    checkbox.checked = true
    form.dispatchEvent(new Event('submit'))
    expect(postMessageStub).toHaveBeenCalledWith(null, true)

    postMessageStub.mockClear()

    // Second change - should trigger postMessage
    checkbox.checked = false
    form.dispatchEvent(new Event('submit'))
    expect(postMessageStub).toHaveBeenCalledWith(null, false)

    postMessageStub.mockClear()

    // No change - should not trigger postMessage
    form.dispatchEvent(new Event('submit'))
    expect(postMessageStub).not.toHaveBeenCalled()
  })
})
