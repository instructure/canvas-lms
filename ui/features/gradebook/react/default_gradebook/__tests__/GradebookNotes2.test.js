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

describe('Gradebook > Teacher Notes', () => {
  let gradebook

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

  describe('#getTeacherNotesViewOptionsMenuProps', () => {
    beforeEach(() => {
      setupGradebook()
      Object.defineProperty(gradebook.gridReady, 'state', {
        get: () => 'unresolved',
      })
    })

    it('includes required props', () => {
      const props = gradebook.getTeacherNotesViewOptionsMenuProps()
      expect(typeof props.disabled).toBe('boolean')
      expect(typeof props.onSelect).toBe('function')
      expect(typeof props.selected).toBe('boolean')
    })

    it('disabled defaults to true', () => {
      const props = gradebook.getTeacherNotesViewOptionsMenuProps()
      expect(props.disabled).toBe(true)
    })

    it('disabled is false when the grid is ready', () => {
      Object.defineProperty(gradebook.gridReady, 'state', {
        get: () => 'resolved',
      })
      const props = gradebook.getTeacherNotesViewOptionsMenuProps()
      expect(props.disabled).toBe(false)
    })

    it('disabled is true if the teacher notes column is updating', () => {
      Object.defineProperty(gradebook.gridReady, 'state', {
        get: () => 'resolved',
      })
      gradebook.setTeacherNotesColumnUpdating(true)
      const props = gradebook.getTeacherNotesViewOptionsMenuProps()
      expect(props.disabled).toBe(true)
    })

    it('disabled is false if the teacher notes column is not updating', () => {
      Object.defineProperty(gradebook.gridReady, 'state', {
        get: () => 'resolved',
      })
      gradebook.setTeacherNotesColumnUpdating(false)
      const props = gradebook.getTeacherNotesViewOptionsMenuProps()
      expect(props.disabled).toBe(false)
    })

    describe('onSelect', () => {
      it('calls createTeacherNotes if there are no teacher notes', () => {
        const mockPromise = Promise.resolve({data: {}})
        GradebookApi.createTeacherNotesColumn.mockReturnValue(mockPromise)
        gradebook = createGradebook({teacher_notes: null})
        jest.spyOn(gradebook, 'createTeacherNotes')
        const props = gradebook.getTeacherNotesViewOptionsMenuProps()
        props.onSelect()
        expect(gradebook.createTeacherNotes).toHaveBeenCalledTimes(1)
      })

      it('calls setTeacherNotesHidden with false if teacher notes are hidden', () => {
        const mockPromise = Promise.resolve()
        GradebookApi.updateTeacherNotesColumn.mockReturnValue(mockPromise)
        const teacherNotes = {
          id: '2401',
          title: 'Notes',
          position: 1,
          teacher_notes: true,
          hidden: true,
        }
        gradebook = createGradebook({teacher_notes: teacherNotes})
        jest.spyOn(gradebook, 'setTeacherNotesHidden')
        const props = gradebook.getTeacherNotesViewOptionsMenuProps()
        props.onSelect()
        expect(gradebook.setTeacherNotesHidden).toHaveBeenCalledWith(false)
      })

      it('calls setTeacherNotesHidden with true if teacher notes are visible', () => {
        const mockPromise = Promise.resolve()
        GradebookApi.updateTeacherNotesColumn.mockReturnValue(mockPromise)
        const teacherNotes = {
          id: '2401',
          title: 'Notes',
          position: 1,
          teacher_notes: true,
          hidden: false,
        }
        gradebook = createGradebook({teacher_notes: teacherNotes})
        jest.spyOn(gradebook, 'setTeacherNotesHidden')
        const props = gradebook.getTeacherNotesViewOptionsMenuProps()
        props.onSelect()
        expect(gradebook.setTeacherNotesHidden).toHaveBeenCalledWith(true)
      })
    })

    describe('selected', () => {
      it('is false if there are no teacher notes', () => {
        gradebook = createGradebook({teacher_notes: null})
        const props = gradebook.getTeacherNotesViewOptionsMenuProps()
        expect(props.selected).toBe(false)
      })

      it('is false if teacher notes are hidden', () => {
        const teacherNotes = {
          id: '2401',
          title: 'Notes',
          position: 1,
          teacher_notes: true,
          hidden: true,
        }
        gradebook = createGradebook({teacher_notes: teacherNotes})
        const props = gradebook.getTeacherNotesViewOptionsMenuProps()
        expect(props.selected).toBe(false)
      })

      it('is true if teacher notes are visible', () => {
        const teacherNotes = {
          id: '2401',
          title: 'Notes',
          position: 1,
          teacher_notes: true,
          hidden: false,
        }
        gradebook = createGradebook({teacher_notes: teacherNotes})
        const props = gradebook.getTeacherNotesViewOptionsMenuProps()
        expect(props.selected).toBe(true)
      })
    })
  })

  describe('#createTeacherNotes', () => {
    let promise

    beforeEach(() => {
      setupGradebook()
      promise = Promise.resolve({
        data: {id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false},
      })
      GradebookApi.createTeacherNotesColumn.mockResolvedValue(promise)
      jest.spyOn(gradebook, 'showNotesColumn')
    })

    it('sets teacherNotesUpdating to true before sending the api request', () => {
      gradebook.createTeacherNotes()
      expect(gradebook.contentLoadStates.teacherNotesColumnUpdating).toBe(true)
    })

    it('re-renders the view options menu after setting teacherNotesUpdating', () => {
      let wasUpdating = false
      gradebook.renderViewOptionsMenu.mockImplementation(() => {
        wasUpdating = gradebook.contentLoadStates.teacherNotesColumnUpdating
      })
      gradebook.createTeacherNotes()
      expect(wasUpdating).toBe(true)
    })

    it('calls GradebookApi.createTeacherNotesColumn with course id', () => {
      gradebook.createTeacherNotes()
      expect(GradebookApi.createTeacherNotesColumn).toHaveBeenCalledWith('1201')
    })

    it('updates teacher notes with response data after request resolves', async () => {
      gradebook.createTeacherNotes()
      await promise
      expect(gradebook.getTeacherNotesColumn()).toEqual({
        id: '2401',
        title: 'Notes',
        position: 1,
        teacher_notes: true,
        hidden: false,
      })
    })

    it('updates custom columns with response data after request resolves', async () => {
      gradebook.createTeacherNotes()
      await promise
      expect(gradebook.gradebookContent.customColumns).toEqual([
        {
          id: '2401',
          title: 'Notes',
          position: 1,
          teacher_notes: true,
          hidden: false,
        },
      ])
    })

    it('shows the notes column after request resolves', async () => {
      gradebook.createTeacherNotes()
      await promise
      expect(gradebook.getTeacherNotesColumn().hidden).toBe(false)
    })

    it('sets teacherNotesUpdating to false after request resolves', async () => {
      gradebook.createTeacherNotes()
      await promise
      expect(gradebook.contentLoadStates.teacherNotesColumnUpdating).toBe(false)
    })

    it('re-renders the view options menu after request resolves', async () => {
      gradebook.createTeacherNotes()
      await promise
      expect(gradebook.renderViewOptionsMenu).toHaveBeenCalled()
    })

    it('displays a flash error after request rejects', async () => {
      const error = new Error('FAIL')
      GradebookApi.createTeacherNotesColumn.mockRejectedValue(error)
      gradebook.createTeacherNotes()
      try {
        await promise
      } catch {
        expect(gradebook.flashError).toHaveBeenCalled()
      }
    })

    it('sets teacherNotesUpdating to false after request rejects', async () => {
      const error = new Error('FAIL')
      GradebookApi.createTeacherNotesColumn.mockRejectedValue(error)
      gradebook.createTeacherNotes()
      try {
        await promise
      } catch {
        expect(gradebook.contentLoadStates.teacherNotesColumnUpdating).toBe(false)
      }
    })

    it('re-renders the view options menu after request rejects', async () => {
      const error = new Error('FAIL')
      GradebookApi.createTeacherNotesColumn.mockRejectedValue(error)
      gradebook.createTeacherNotes()
      try {
        await promise
      } catch {
        expect(gradebook.renderViewOptionsMenu).toHaveBeenCalled()
      }
    })
  })
})
