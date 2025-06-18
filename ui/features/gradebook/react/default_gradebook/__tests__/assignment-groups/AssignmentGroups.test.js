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

import {createGradebook, setFixtureHtml} from '../GradebookSpecHelper'

describe('Gradebook > Assignment Groups', () => {
  let $container
  let gradebook

  beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($container)
    ENV.SETTINGS = {}
  })

  afterEach(() => {
    gradebook.destroy()
    $container.remove()
    jest.restoreAllMocks()
  })

  describe('#updateAssignmentGroups()', () => {
    let assignmentGroups
    let assignments

    beforeEach(() => {
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
      expect(storedGroups.map(assignmentGroup => assignmentGroup.id)).toEqual(['2201', '2202'])
    })

    test('sets the assignment groups loaded status to true', () => {
      gradebook.updateAssignmentGroups(assignmentGroups)
      expect(gradebook.contentLoadStates.assignmentGroupsLoaded).toBe(true)
    })

    test('renders the view options menu', () => {
      const renderViewOptionsMenuSpy = jest.spyOn(gradebook, 'renderViewOptionsMenu')
      gradebook.updateAssignmentGroups(assignmentGroups)
      expect(renderViewOptionsMenuSpy).toHaveBeenCalledTimes(1)
    })

    test('renders the view options menu after storing the assignment groups', () => {
      jest.spyOn(gradebook, 'renderViewOptionsMenu').mockImplementation(() => {
        const storedGroups = gradebook.assignmentGroupList()
        expect(storedGroups).toHaveLength(2)
      })
      gradebook.updateAssignmentGroups(assignmentGroups)
    })

    test('renders the view options menu after updating the assignment groups loaded status', () => {
      jest.spyOn(gradebook, 'renderViewOptionsMenu').mockImplementation(() => {
        expect(gradebook.contentLoadStates.assignmentGroupsLoaded).toBe(true)
      })
      gradebook.updateAssignmentGroups(assignmentGroups)
    })

    test('updates column headers', () => {
      const updateColumnHeadersSpy = jest.spyOn(gradebook, 'updateColumnHeaders')
      gradebook.updateAssignmentGroups(assignmentGroups)
      expect(updateColumnHeadersSpy).toHaveBeenCalledTimes(1)
    })

    test('updates column headers after storing the assignment groups', () => {
      jest.spyOn(gradebook, 'updateColumnHeaders').mockImplementation(() => {
        const storedGroups = gradebook.assignmentGroupList()
        expect(storedGroups).toHaveLength(2)
      })
      gradebook.updateAssignmentGroups(assignmentGroups)
    })

    test('updates column headers after updating the assignment groups loaded status', () => {
      jest.spyOn(gradebook, 'updateColumnHeaders').mockImplementation(() => {
        expect(gradebook.contentLoadStates.assignmentGroupsLoaded).toBe(true)
      })
      gradebook.updateAssignmentGroups(assignmentGroups)
    })

    test('updates essential data load status', () => {
      const updateEssentialDataLoadedSpy = jest.spyOn(gradebook, '_updateEssentialDataLoaded')
      gradebook.updateAssignmentGroups(assignmentGroups)
      expect(updateEssentialDataLoadedSpy).toHaveBeenCalledTimes(1)
    })

    test('updates essential data load status after updating the assignment groups loaded status', () => {
      jest.spyOn(gradebook, '_updateEssentialDataLoaded').mockImplementation(() => {
        expect(gradebook.contentLoadStates.assignmentGroupsLoaded).toBe(true)
      })
      gradebook.updateAssignmentGroups(assignmentGroups)
    })

    test('updates essential data load status after rendering filters', () => {
      const updateColumnHeadersSpy = jest.spyOn(gradebook, 'updateColumnHeaders')
      jest.spyOn(gradebook, '_updateEssentialDataLoaded').mockImplementation(() => {
        expect(updateColumnHeadersSpy).toHaveBeenCalledTimes(1)
      })
      gradebook.updateAssignmentGroups(assignmentGroups)
    })
  })
})
