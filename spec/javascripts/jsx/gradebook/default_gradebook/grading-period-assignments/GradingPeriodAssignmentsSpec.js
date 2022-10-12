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

import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

QUnit.module('Gradebook > Students', suiteHooks => {
  let $container
  let gradebook

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($container)
  })

  suiteHooks.afterEach(() => {
    gradebook.destroy()
    $container.remove()
  })

  QUnit.module('#updateGradingPeriodAssignments()', hooks => {
    let gradingPeriodAssignments

    hooks.beforeEach(() => {
      gradebook = createGradebook()
      gradingPeriodAssignments = {
        1501: ['2301', '2303'],
        1502: ['2302', '2304'],
      }
    })

    test('stores the given grading period assignments', () => {
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
      deepEqual(gradebook.courseContent.gradingPeriodAssignments, gradingPeriodAssignments)
    })

    test('sets the grading period assignments loaded status to true', () => {
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
      strictEqual(gradebook.contentLoadStates.gradingPeriodAssignmentsLoaded, true)
    })

    test('updates columns when the grid has rendered', () => {
      sinon.stub(gradebook, '_gridHasRendered').returns(true)
      sinon.stub(gradebook, 'updateColumns')
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
      strictEqual(gradebook.updateColumns.callCount, 1)
    })

    test('updates columns after storing grading period assignments', () => {
      sinon.stub(gradebook, '_gridHasRendered').returns(true)
      sinon.stub(gradebook, 'updateColumns').callsFake(() => {
        deepEqual(gradebook.courseContent.gradingPeriodAssignments, gradingPeriodAssignments)
      })
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
    })

    test('does not update columns when the grid has not yet rendered', () => {
      sinon.stub(gradebook, '_gridHasRendered').returns(false)
      sinon.stub(gradebook, 'updateColumns')
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
      strictEqual(gradebook.updateColumns.callCount, 0)
    })

    test('updates essential data load status', () => {
      sinon.spy(gradebook, '_updateEssentialDataLoaded')
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
      strictEqual(gradebook._updateEssentialDataLoaded.callCount, 1)
    })

    test('updates essential data load status after updating the grading period assignments loaded status', () => {
      sinon.stub(gradebook, '_updateEssentialDataLoaded').callsFake(() => {
        strictEqual(gradebook.contentLoadStates.gradingPeriodAssignmentsLoaded, true)
      })
      gradebook.updateGradingPeriodAssignments(gradingPeriodAssignments)
    })
  })
})
