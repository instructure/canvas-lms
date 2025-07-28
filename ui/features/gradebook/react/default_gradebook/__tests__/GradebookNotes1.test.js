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
import GradebookApi from '../apis/GradebookApi'

jest.mock('../apis/GradebookApi')

const $container = document.createElement('div')
document.body.appendChild($container)

describe('Gradebook > Teacher Notes', () => {
  let gradebook
  let promise

  const setupGradebook = (options = {}) => {
    gradebook = createGradebook({
      context_id: '1201',
      ...options,
    })
    gradebook.gradebookGrid.grid = {
      getColumns: () => [],
      getOptions: () => ({
        numberOfColumnsToFreeze: 0,
      }),
      invalidate: jest.fn(),
      setColumns: jest.fn(),
      setNumberOfColumnsToFreeze: jest.fn(),
      destroy: jest.fn(),
    }
    gradebook.gradebookGrid.gridSupport = {
      destroy: jest.fn(),
    }
    gradebook.renderViewOptionsMenu = jest.fn()
    gradebook.flashError = jest.fn()
  }

  describe('showing teacher notes', () => {
    beforeEach(() => {
      promise = Promise.resolve({
        data: {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false},
      })
      GradebookApi.updateTeacherNotesColumn.mockResolvedValue(promise)
      setupGradebook()
      gradebook.gradebookContent.customColumns = [
        {id: '2401', teacher_notes: true, hidden: true, title: 'Notes'},
        {id: '2402', teacher_notes: false, hidden: false, title: 'Other Notes'},
      ]
    })

    afterEach(() => {
      jest.clearAllMocks()
      if (gradebook?.gradebookGrid?.grid?.destroy?.mockReset) {
        gradebook.gradebookGrid.grid.destroy.mockReset()
      }
      if (gradebook?.gradebookGrid?.gridSupport?.destroy?.mockReset) {
        gradebook.gradebookGrid.gridSupport.destroy.mockReset()
      }
      gradebook?.destroy()
    })

    it('sets teacherNotesUpdating to true before sending the api request', () => {
      gradebook.setTeacherNotesHidden(false)
      expect(gradebook.contentLoadStates.teacherNotesColumnUpdating).toBe(true)
    })

    it('re-renders the view options menu after setting teacherNotesUpdating', () => {
      let wasUpdating = false
      gradebook.renderViewOptionsMenu.mockImplementation(() => {
        wasUpdating = gradebook.contentLoadStates.teacherNotesColumnUpdating
      })
      gradebook.setTeacherNotesHidden(false)
      expect(wasUpdating).toBe(true)
    })

    it('calls GradebookApi.updateTeacherNotesColumn with correct parameters', () => {
      gradebook.setTeacherNotesHidden(false)
      expect(GradebookApi.updateTeacherNotesColumn).toHaveBeenCalledWith('1201', '2401', {
        hidden: false,
      })
    })

    it('shows the notes column after request resolves', async () => {
      gradebook.setTeacherNotesHidden(false)
      expect(gradebook.getTeacherNotesColumn().hidden).toBe(true)
      await promise
      expect(gradebook.getTeacherNotesColumn().hidden).toBe(false)
    })

    it('sets teacherNotesUpdating to false after request resolves', async () => {
      gradebook.setTeacherNotesHidden(false)
      await promise
      expect(gradebook.contentLoadStates.teacherNotesColumnUpdating).toBe(false)
    })

    it('re-renders the view options menu after request resolves', async () => {
      gradebook.setTeacherNotesHidden(false)
      await promise
      expect(gradebook.renderViewOptionsMenu).toHaveBeenCalled()
    })

    it('displays a flash message after request rejects', async () => {
      const error = new Error('FAIL')
      GradebookApi.updateTeacherNotesColumn.mockRejectedValue(error)
      gradebook.setTeacherNotesHidden(false)
      try {
        await promise
      } catch {
        expect(gradebook.flashError).toHaveBeenCalled()
      }
    })

    it('sets teacherNotesUpdating to false after request rejects', async () => {
      const error = new Error('FAIL')
      GradebookApi.updateTeacherNotesColumn.mockRejectedValue(error)
      gradebook.setTeacherNotesHidden(false)
      try {
        await promise
      } catch {
        expect(gradebook.contentLoadStates.teacherNotesColumnUpdating).toBe(false)
      }
    })
  })

  describe('hiding teacher notes', () => {
    beforeEach(() => {
      promise = Promise.resolve({
        data: {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true},
      })
      GradebookApi.updateTeacherNotesColumn.mockResolvedValue(promise)
      setupGradebook({
        teacher_notes: {id: '2401', teacher_notes: true, hidden: false},
      })
    })

    afterEach(() => {
      jest.clearAllMocks()
      if (gradebook?.gradebookGrid?.grid?.destroy?.mockReset) {
        gradebook.gradebookGrid.grid.destroy.mockReset()
      }
      if (gradebook?.gradebookGrid?.gridSupport?.destroy?.mockReset) {
        gradebook.gradebookGrid.gridSupport.destroy.mockReset()
      }
      gradebook?.destroy()
    })

    it('sets teacherNotesUpdating to true before sending the api request', () => {
      gradebook.setTeacherNotesHidden(true)
      expect(gradebook.contentLoadStates.teacherNotesColumnUpdating).toBe(true)
    })

    it('re-renders the view options menu after setting teacherNotesUpdating', () => {
      let wasUpdating = false
      gradebook.renderViewOptionsMenu.mockImplementation(() => {
        wasUpdating = gradebook.contentLoadStates.teacherNotesColumnUpdating
      })
      gradebook.setTeacherNotesHidden(true)
      expect(wasUpdating).toBe(true)
    })

    it('calls GradebookApi.updateTeacherNotesColumn with correct parameters', () => {
      gradebook.setTeacherNotesHidden(true)
      expect(GradebookApi.updateTeacherNotesColumn).toHaveBeenCalledWith('1201', '2401', {
        hidden: true,
      })
    })

    it('hides the notes column after request resolves', async () => {
      gradebook.setTeacherNotesHidden(true)
      expect(gradebook.getTeacherNotesColumn().hidden).toBe(false)
      await promise
      expect(gradebook.getTeacherNotesColumn().hidden).toBe(true)
    })

    it('sets teacherNotesUpdating to false after request resolves', async () => {
      gradebook.setTeacherNotesHidden(true)
      await promise
      expect(gradebook.contentLoadStates.teacherNotesColumnUpdating).toBe(false)
    })

    it('re-renders the view options menu after request resolves', async () => {
      gradebook.setTeacherNotesHidden(true)
      await promise
      expect(gradebook.renderViewOptionsMenu).toHaveBeenCalled()
    })
  })
})
