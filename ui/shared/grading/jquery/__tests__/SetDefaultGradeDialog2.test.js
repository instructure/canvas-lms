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
import sinon from 'sinon'
import SetDefaultGradeDialog from '../SetDefaultGradeDialog'

const sandbox = sinon.createSandbox()
const server = sinon.fakeServer.create()

describe('Shared > SetDefaultGradeDialog', () => {
  let assignment
  let dialog

  beforeEach(() => {
    assignment = {
      grading_type: 'points',
      id: '2',
      name: 'an Assignment',
      points_possible: 10,
    }
  })

  function getDialog() {
    return dialog.$dialog[0].closest('.ui-dialog')
  }

  describe('submit behaviors', () => {
    const context_id = '1'
    let alert

    function clickSetDefaultGrade() {
      Array.from(getDialog().querySelectorAll('button[role="button"]'))
        .find(node => node.innerText === 'Set Default Grade')
        .click()
    }

    function respondWithPayload(payload) {
      server.respondWith('POST', `/courses/${context_id}/gradebook/update_submission`, [
        200,
        {'Content-Type': 'application/json'},
        JSON.stringify(payload),
      ])
    }

    beforeEach(() => {
      server.respondImmediately = true
      alert = sinon.spy()
      jest.spyOn($, 'publish').mockImplementation(jest.fn())
    })

    test('submit reports number of students scored', async () => {
      const payload = [
        {submission: {id: '11', assignment_id: '2', user_id: '3'}},
        {submission: {id: '22', assignment_id: '2', user_id: '4'}},
      ]
      respondWithPayload(payload)
      const students = [{id: '3'}, {id: '4'}]
      dialog = new SetDefaultGradeDialog({
        missing_shortcut_enabled: true,
        assignment,
        students,
        context_id,
        alert,
      })
      dialog.show()
      clickSetDefaultGrade()
      await awhile()
      const {
        firstCall: {
          args: [message],
        },
      } = alert
      expect(message).toEqual('2 student scores updated')
    })

    test('submit reports number of students marked as missing', async () => {
      const payload = [
        {submission: {id: '11', assignment_id: '2', user_id: '3'}},
        {submission: {id: '22', assignment_id: '2', user_id: '4'}},
      ]
      respondWithPayload(payload)
      const students = [{id: '3'}, {id: '4'}]
      dialog = new SetDefaultGradeDialog({
        missing_shortcut_enabled: true,
        assignment,
        students,
        context_id,
        alert,
      })
      dialog.show()
      document.querySelector('input[name="default_grade"]').value = 'mi'
      clickSetDefaultGrade()
      await awhile()
      const {
        firstCall: {
          args: [message],
        },
      } = alert
      expect(message).toEqual('2 students marked as missing')
    })

    test('submit ignores the missing shortcut when the shortcut feature flag is disabled', async () => {
      const payload = [
        {submission: {id: '11', assignment_id: '2', user_id: '3'}},
        {submission: {id: '22', assignment_id: '2', user_id: '4'}},
      ]
      respondWithPayload(payload)
      const students = [{id: '3'}, {id: '4'}]
      dialog = new SetDefaultGradeDialog({
        missing_shortcut_enabled: false,
        assignment,
        students,
        context_id,
        alert,
      })
      dialog.show()
      document.querySelector('input[name="default_grade"]').value = 'mi'
      clickSetDefaultGrade()
      await awhile()
      const {
        firstCall: {
          args: [message],
        },
      } = alert
      expect(message).toEqual('2 student scores updated')
    })

    test('submit reports number of students when api includes duplicates due to group assignments', async () => {
      const payload = [
        {submission: {id: '11', assignment_id: '2', user_id: '3'}},
        {submission: {id: '22', assignment_id: '2', user_id: '4'}},
        {submission: {id: '33', assignment_id: '2', user_id: '5'}},
        {submission: {id: '44', assignment_id: '2', user_id: '6'}},
      ]
      respondWithPayload(payload)
      const students = [{id: '3'}, {id: '4'}, {id: '5'}, {id: '6'}]
      // adjust page size so that we generate two requests
      dialog = new SetDefaultGradeDialog({
        missing_shortcut_enabled: true,
        assignment,
        students,
        context_id,
        page_size: 2,
        alert,
      })
      dialog.show()
      clickSetDefaultGrade()
      await awhile()
      const {
        firstCall: {
          args: [message],
        },
      } = alert
      expect(message).toEqual('4 student scores updated')
    })
  })
})

const awhile = () => new Promise(resolve => setTimeout(resolve, 2))
