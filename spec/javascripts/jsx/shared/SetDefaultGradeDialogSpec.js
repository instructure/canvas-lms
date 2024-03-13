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

import SetDefaultGradeDialog from '@canvas/grading/jquery/SetDefaultGradeDialog'

QUnit.module('Shared > SetDefaultGradeDialog', suiteHooks => {
  let assignment
  let dialog

  suiteHooks.beforeEach(() => {
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

  function closeDialog() {
    getDialog().querySelector('.ui-dialog-titlebar-close').click()
  }

  test('#gradeIsExcused returns true if grade is EX', () => {
    dialog = new SetDefaultGradeDialog({assignment})
    dialog.show()
    deepEqual(dialog.gradeIsExcused('EX'), true)
    deepEqual(dialog.gradeIsExcused('ex'), true)
    deepEqual(dialog.gradeIsExcused('eX'), true)
    deepEqual(dialog.gradeIsExcused('Ex'), true)
    closeDialog()
  })

  test('#gradeIsExcused returns false if grade is not EX', () => {
    dialog = new SetDefaultGradeDialog({assignment})
    dialog.show()
    deepEqual(dialog.gradeIsExcused('14'), false)
    deepEqual(dialog.gradeIsExcused('F'), false)
    // this test documents that we do not consider 'excused' to return true
    deepEqual(dialog.gradeIsExcused('excused'), false)
    closeDialog()
  })

  test('#show text', () => {
    dialog = new SetDefaultGradeDialog({assignment})
    dialog.show()
    ok(getDialog().querySelector('#default_grade_description').innerText.includes('same grade'))
    closeDialog()
  })

  test('#show changes text for grading percent', () => {
    const percentAssignmentParams = {...assignment, grading_type: 'percent'}
    dialog = new SetDefaultGradeDialog({assignment: percentAssignmentParams})
    dialog.show()
    ok(
      getDialog()
        .querySelector('#default_grade_description')
        .innerText.includes('same percent grade')
    )
    closeDialog()
  })

  QUnit.module('submit behaviors', submitBehaviorHooks => {
    const context_id = '1'
    let alert

    function clickSetDefaultGrade() {
      Array.from(getDialog().querySelectorAll('button[role="button"]'))
        .find(node => node.innerText === 'Set Default Grade')
        .click()
    }

    function respondWithPayload(payload) {
      sandbox.server.respondWith('POST', `/courses/${context_id}/gradebook/update_submission`, [
        200,
        {'Content-Type': 'application/json'},
        JSON.stringify(payload),
      ])
    }

    submitBehaviorHooks.beforeEach(() => {
      sandbox.server.respondImmediately = true
      alert = sinon.spy()
      sandbox.stub($, 'publish')
    })

    test('submit reports number of students scored', async assert => {
      const done = assert.async()
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
      strictEqual(message, '2 student scores updated')
      done()
    })

    test('submit reports number of students marked as missing', async assert => {
      const done = assert.async()
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
      strictEqual(message, '2 students marked as missing')
      done()
    })

    test('submit ignores the missing shortcut when the shortcut feature flag is disabled', async assert => {
      const done = assert.async()
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
      strictEqual(message, '2 student scores updated')
      done()
    })

    test('submit reports number of students when api includes duplicates due to group assignments', async assert => {
      const done = assert.async()
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
      strictEqual(message, '4 student scores updated')
      done()
    })
  })
})

const awhile = () => new Promise(resolve => setTimeout(resolve, 2))
