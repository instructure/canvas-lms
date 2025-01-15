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

import {createGradebook} from './GradebookSpecHelper'

describe('Gradebook', () => {
  let gradebook
  let container

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)
  })

  afterEach(() => {
    gradebook?.destroy()
    container.remove()
  })

  describe('studentSearchMatcher', () => {
    beforeEach(() => {
      gradebook = createGradebook()
      const students = [
        {
          id: '1303',
          name: 'Joe Dirt',
          sis_user_id: 'meteor',
          enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}],
        },
      ]
      gradebook.courseContent.students.setStudentIds(['1303'])
      gradebook.gotChunkOfStudents(students)
    })

    it('returns true if the search term is a substring of the student name (case insensitive)', () => {
      const option = {id: '1303', label: 'Joe Dirt'}
      expect(gradebook.studentSearchMatcher(option, 'dir')).toBe(true)
    })

    it('returns false if the search term is not a substring of the student name', () => {
      const option = {id: '1303', label: 'Joe Dirt'}
      expect(gradebook.studentSearchMatcher(option, 'Dirz')).toBe(false)
    })

    it('returns true if the search term matches the SIS ID exactly (case insensitive)', () => {
      const option = {id: '1303', label: 'Joe Dirt'}
      expect(gradebook.studentSearchMatcher(option, 'Meteor')).toBe(true)
    })

    it('returns false if the search term is a substring of the SIS ID, but does not match exactly', () => {
      const option = {id: '1303', label: 'Joe Dirt'}
      expect(gradebook.studentSearchMatcher(option, 'meteo')).toBe(false)
    })

    it('does not treat the search term as a regular expression', () => {
      const option = {id: '1303', label: 'Joe Dirt'}
      expect(gradebook.studentSearchMatcher(option, 'Joe.*rt')).toBe(false)
    })
  })

  describe('_updateEssentialDataLoaded', () => {
    const createInitializedGradebook = options => {
      gradebook = createGradebook(options)
      jest.spyOn(gradebook, 'finishRenderingUI')

      gradebook.setStudentIdsLoaded(true)
      gradebook.setAssignmentGroupsLoaded(true)
      gradebook.setAssignmentsLoaded()
    }

    const waitForTick = () => new Promise(resolve => setTimeout(resolve, 0))

    it('does not finish rendering the UI when student ids are not loaded', async () => {
      createInitializedGradebook()
      gradebook.setStudentIdsLoaded(false)
      gradebook._updateEssentialDataLoaded()
      await waitForTick()
      expect(gradebook.finishRenderingUI).not.toHaveBeenCalled()
    })

    it('does not finish rendering the UI when context modules are not loaded', async () => {
      createInitializedGradebook({isModulesLoading: true})
      gradebook._updateEssentialDataLoaded()
      await waitForTick()
      expect(gradebook.finishRenderingUI).not.toHaveBeenCalled()
    })
  })
})
