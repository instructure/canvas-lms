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

import $ from 'jquery'
import 'jquery-migrate'
import {http} from 'msw'
import {setupServer} from 'msw/node'
import SetDefaultGradeDialog from '../SetDefaultGradeDialog'
import {windowAlert} from '@canvas/util/globalUtils'

jest.mock('@canvas/util/globalUtils', () => ({
  windowAlert: jest.fn(),
}))

const server = setupServer()

describe('Shared > SetDefaultGradeDialog', () => {
  let assignment
  let dialog

  beforeAll(() => {
    server.listen({
      onUnhandledRequest: 'error',
    })
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    assignment = {
      grading_type: 'points',
      id: '2',
      name: 'an Assignment',
      points_possible: 10,
    }
    windowAlert.mockClear()
  })

  afterEach(() => {
    if (dialog && dialog.$dialog) {
      try {
        dialog.$dialog.dialog('destroy')
        dialog.$dialog.remove()
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
    server.resetHandlers()
    jest.clearAllMocks()
  })

  function getDialog() {
    return dialog.$dialog[0].closest('.ui-dialog')
  }

  describe('submit behaviors', () => {
    const context_id = '1'

    function clickSetDefaultGrade() {
      const buttons = Array.from(getDialog().querySelectorAll('button[role="button"]'))
      const button = buttons.find(node => node.textContent.trim() === 'Set Default Grade')
      button.click()
    }

    function setupSubmissionHandler(payload) {
      server.use(
        http.post(`/courses/${context_id}/gradebook/update_submission`, () => {
          return new Response(JSON.stringify(payload), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )
    }

    beforeEach(() => {
      jest.spyOn($, 'publish').mockImplementation(jest.fn())
    })

    // fickle; cf. EVAL-4977
    test.skip('submit reports number of students scored', async () => {
      const payload = [
        {submission: {id: '11', assignment_id: '2', user_id: '3'}},
        {submission: {id: '22', assignment_id: '2', user_id: '4'}},
      ]
      const students = [{id: '3'}, {id: '4'}]

      setupSubmissionHandler(payload)

      dialog = new SetDefaultGradeDialog({
        missing_shortcut_enabled: true,
        assignment,
        students,
        context_id,
      })

      dialog.show()
      await new Promise(resolve => setTimeout(resolve, 50)) // Wait for dialog to render

      document.querySelector('input[name="default_grade"]').value = '10'
      clickSetDefaultGrade()

      await new Promise(resolve => setTimeout(resolve, 100))

      expect(windowAlert).toHaveBeenCalledWith('2 student scores updated')
    })

    // fickle; cf. EVAL-4977
    test.skip('submit reports number of students marked as missing', async () => {
      const payload = [
        {submission: {id: '11', assignment_id: '2', user_id: '3'}},
        {submission: {id: '22', assignment_id: '2', user_id: '4'}},
      ]
      const students = [{id: '3'}, {id: '4'}]

      setupSubmissionHandler(payload)

      dialog = new SetDefaultGradeDialog({
        missing_shortcut_enabled: true,
        assignment,
        students,
        context_id,
      })

      dialog.show()
      await new Promise(resolve => setTimeout(resolve, 50)) // Wait for dialog to render

      // Set the input value and submit
      document.querySelector('input[name="default_grade"]').value = 'mi'
      clickSetDefaultGrade()

      // Wait for the alert to be called
      await new Promise(resolve => setTimeout(resolve, 100))

      expect(windowAlert).toHaveBeenCalledWith('2 students marked as missing')
    })

    // fickle; cf. EVAL-4977
    test.skip('submit ignores the missing shortcut when the shortcut feature flag is disabled', async () => {
      const payload = [
        {submission: {id: '11', assignment_id: '2', user_id: '3'}},
        {submission: {id: '22', assignment_id: '2', user_id: '4'}},
      ]
      const students = [{id: '3'}, {id: '4'}]

      setupSubmissionHandler(payload)

      dialog = new SetDefaultGradeDialog({
        missing_shortcut_enabled: false,
        assignment,
        students,
        context_id,
      })

      dialog.show()
      await new Promise(resolve => setTimeout(resolve, 50))

      document.querySelector('input[name="default_grade"]').value = 'mi'
      clickSetDefaultGrade()

      await new Promise(resolve => setTimeout(resolve, 100))

      expect(windowAlert).toHaveBeenCalledWith('2 student scores updated')
    })

    // fickle; cf. EVAL-4977
    test.skip('submit reports number of students when api includes duplicates due to group assignments', async () => {
      const payload = [
        {submission: {id: '11', assignment_id: '2', user_id: '3'}},
        {submission: {id: '22', assignment_id: '2', user_id: '4'}},
        {submission: {id: '33', assignment_id: '2', user_id: '5'}},
        {submission: {id: '44', assignment_id: '2', user_id: '6'}},
      ]
      const students = [{id: '3'}, {id: '4'}, {id: '5'}, {id: '6'}]

      setupSubmissionHandler(payload)

      dialog = new SetDefaultGradeDialog({
        missing_shortcut_enabled: true,
        assignment,
        students,
        context_id,
        page_size: 2,
      })

      dialog.show()
      await new Promise(resolve => setTimeout(resolve, 50))

      document.querySelector('input[name="default_grade"]').value = '10'
      clickSetDefaultGrade()

      await new Promise(resolve => setTimeout(resolve, 100))

      expect(windowAlert).toHaveBeenCalledWith('4 student scores updated')
    })
  })
})
