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

QUnit.module('Gradebook > Assignment Groups', suiteHooks => {
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

  QUnit.module('#updateAssignmentGroups()', hooks => {
    let assignmentGroups
    let assignments

    hooks.beforeEach(() => {
      gradebook = createGradebook()

      assignments = [
        {
          assignment_group_id: '2201',
          assignment_visibility: null,
          id: '2301',
          name: 'Math Assignment',
          only_visible_to_overrides: false,
          points_possible: 10,
          published: true,
        },

        {
          assignment_group_id: '2202',
          assignment_visibility: ['1102'],
          id: '2302',
          name: 'English Assignment',
          only_visible_to_overrides: true,
          points_possible: 10,
          published: false,
        },
      ]

      assignmentGroups = [
        {
          assignments: assignments.slice(0, 1),
          group_weight: 40,
          id: '2201',
          name: 'Assignments',
          position: 1,
        },

        {
          assignments: assignments.slice(1, 2),
          group_weight: 60,
          id: '2202',
          name: 'Homework',
          position: 2,
        },
      ]
    })

    test('stores the given assignment groups', () => {
      gradebook.updateAssignmentGroups(assignmentGroups)
      const storedGroups = gradebook.assignmentGroupList()
      deepEqual(
        storedGroups.map(assignmentGroup => assignmentGroup.id),
        ['2201', '2202']
      )
    })

    test('sets the assignment groups loaded status to true', () => {
      gradebook.updateAssignmentGroups(assignmentGroups)
      strictEqual(gradebook.contentLoadStates.assignmentGroupsLoaded, true)
    })

    test('renders the view options menu', () => {
      sinon.spy(gradebook, 'renderViewOptionsMenu')
      gradebook.updateAssignmentGroups(assignmentGroups)
      strictEqual(gradebook.renderViewOptionsMenu.callCount, 1)
    })

    test('renders the view options menu after storing the assignment groups', () => {
      sinon.stub(gradebook, 'renderViewOptionsMenu').callsFake(() => {
        const storedGroups = gradebook.assignmentGroupList()
        strictEqual(storedGroups.length, 2)
      })
      gradebook.updateAssignmentGroups(assignmentGroups)
    })

    test('renders the view options menu after updating the assignment groups loaded status', () => {
      sinon.stub(gradebook, 'renderViewOptionsMenu').callsFake(() => {
        strictEqual(gradebook.contentLoadStates.assignmentGroupsLoaded, true)
      })
      gradebook.updateAssignmentGroups(assignmentGroups)
    })

    test('updates column headers', () => {
      sinon.spy(gradebook, 'updateColumnHeaders')
      gradebook.updateAssignmentGroups(assignmentGroups)
      strictEqual(gradebook.updateColumnHeaders.callCount, 1)
    })

    test('updates column headers after storing the assignment groups', () => {
      sinon.stub(gradebook, 'updateColumnHeaders').callsFake(() => {
        const storedGroups = gradebook.assignmentGroupList()
        strictEqual(storedGroups.length, 2)
      })
      gradebook.updateAssignmentGroups(assignmentGroups)
    })

    test('updates column headers after updating the assignment groups loaded status', () => {
      sinon.stub(gradebook, 'updateColumnHeaders').callsFake(() => {
        strictEqual(gradebook.contentLoadStates.assignmentGroupsLoaded, true)
      })
      gradebook.updateAssignmentGroups(assignmentGroups)
    })

    test('updates essential data load status', () => {
      sinon.spy(gradebook, '_updateEssentialDataLoaded')
      gradebook.updateAssignmentGroups(assignmentGroups)
      strictEqual(gradebook._updateEssentialDataLoaded.callCount, 1)
    })

    test('updates essential data load status after updating the assignment groups loaded status', () => {
      sinon.spy(gradebook, 'updateColumnHeaders')
      sinon.stub(gradebook, '_updateEssentialDataLoaded').callsFake(() => {
        strictEqual(gradebook.contentLoadStates.assignmentGroupsLoaded, true)
      })
      gradebook.updateAssignmentGroups(assignmentGroups)
    })

    test('updates essential data load status after rendering filters', () => {
      sinon.spy(gradebook, 'updateColumnHeaders')
      sinon.stub(gradebook, '_updateEssentialDataLoaded').callsFake(() => {
        strictEqual(gradebook.updateColumnHeaders.callCount, 1)
      })
      gradebook.updateAssignmentGroups(assignmentGroups)
    })
  })
})
