/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import AssignmentMuter from 'coffeescripts/AssignmentMuter'
import $ from 'jquery'

QUnit.module('AssignmentMuter', (suiteHooks) => {
  let assignment
  let responseAssignment

  suiteHooks.beforeEach(() => {
    assignment = {id: '1', name: 'foo', anonymize_students: false, muted: false}
    responseAssignment = {id: '1', name: 'foo', anonymize_students: true, muted: true}
  })

  function createAssignmentMuter(setterFn) {
    const muter = new AssignmentMuter({text: () => {}}, assignment, '/bar', setterFn, {})
    muter.$dialog = {dialog() {}}
    return muter
  }

  QUnit.module('#afterUpdate', (hooks) => {
    hooks.beforeEach(() => {
      sinon.stub($, 'publish')
    })

    hooks.afterEach(() => {
      $.publish.restore()
    })

    test('closes the dialog', () => {
      const muter = createAssignmentMuter()
      sinon.stub(muter.$dialog, 'dialog')
      muter.afterUpdate({assignment: responseAssignment})
      ok(muter.$dialog.dialog.calledWith('close'))
    })

    QUnit.module('when not passed a setter function', () => {
      test('sets anonymize_students on the assignment', () => {
        const muter = createAssignmentMuter()
        muter.afterUpdate({assignment: responseAssignment})
        strictEqual(muter.assignment.anonymize_students, responseAssignment.anonymize_students)
      })

      test('sets muted on the assignment', () => {
        const muter = createAssignmentMuter()
        muter.afterUpdate({assignment: responseAssignment})
        strictEqual(muter.assignment.muted, responseAssignment.muted)
      })

      test('publishes "assignment_muting_toggled" message', () => {
        const muter = createAssignmentMuter()
        muter.afterUpdate({assignment: responseAssignment})
        ok($.publish.calledWith('assignment_muting_toggled'))
      })

      test('publishes "assignment_muting_toggled" message with the updated anonymize_students attribute', () => {
        const muter = createAssignmentMuter()
        muter.afterUpdate({assignment: responseAssignment})
        const [publishedAssignment] = $.publish.getCall(0).args[1]
        strictEqual(publishedAssignment.anonymize_students, responseAssignment.anonymize_students)
      })

      test('publishes "assignment_muting_toggled" message with the updated muted attribute', () => {
        const muter = createAssignmentMuter()
        muter.afterUpdate({assignment: responseAssignment})
        const [publishedAssignment] = $.publish.getCall(0).args[1]
        strictEqual(publishedAssignment.muted, responseAssignment.muted)
      })
    })

    QUnit.module('when passed a setter function', () => {
      test('sets anonymize_students via the setter function', () => {
        const setterFn = sinon.stub()
        const muter = createAssignmentMuter(setterFn)
        muter.afterUpdate({assignment: responseAssignment})
        ok(setterFn.calledWith(assignment, 'anonymize_students', responseAssignment.anonymize_students))
      })

      test('sets muted via the setter function', () => {
        const setterFn = sinon.stub()
        const muter = createAssignmentMuter(setterFn)
        muter.afterUpdate({assignment: responseAssignment})
        ok(setterFn.calledWith(assignment, 'muted', responseAssignment.anonymize_students))
      })

      test('publishes "assignment_muting_toggled" message', () => {
        const muter = createAssignmentMuter(() => {})
        muter.afterUpdate({assignment: responseAssignment})
        ok($.publish.calledWith('assignment_muting_toggled'))
      })

      test('publishes "assignment_muting_toggled" message with the updated anonymize_students attribute', () => {
        const muter = createAssignmentMuter(() => {})
        muter.afterUpdate({assignment: responseAssignment})
        const [publishedAssignment] = $.publish.getCall(0).args[1]
        strictEqual(publishedAssignment.anonymize_students, responseAssignment.anonymize_students)
      })

      test('publishes "assignment_muting_toggled" message with the updated muted attribute', () => {
        const muter = createAssignmentMuter(() => {})
        muter.afterUpdate({assignment: responseAssignment})
        const [publishedAssignment] = $.publish.getCall(0).args[1]
        strictEqual(publishedAssignment.muted, responseAssignment.muted)
      })
    })
  })
})
