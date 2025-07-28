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

import $ from 'jquery'
import 'jquery-migrate'
import {defer} from 'lodash'
import EditView from '../EditView'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.simulate'
import {editView} from './utils'
import fetchMock from 'fetch-mock'

// Mock DueDateOverride component
jest.mock('@canvas/due-dates', () => {
  return function DueDateOverride() {
    return {
      render() {
        return this
      },
      setElement() {
        return this
      },
      getAllDates() {
        return []
      },
      validateBeforeSave() {
        return []
      },
    }
  }
})

// Mock ConditionalReleaseEditor
const mockEditor = {
  updateAssignment: jest.fn(),
  validateBeforeSave: jest.fn(),
  save: jest.fn().mockResolvedValue({}),
}
jest.mock('@canvas/conditional-release-editor', () => {
  return {
    attach() {
      return mockEditor
    },
  }
})

// Filter React warnings/errors about deprecated lifecycle methods and unknown props
const originalConsoleError = console.error
const originalConsoleWarn = console.warn
beforeAll(() => {
  console.error = (...args) => {
    if (
      typeof args[0] === 'string' &&
      (args[0].includes('Warning: React does not recognize') ||
        args[0].includes('Warning: componentWillMount has been renamed') ||
        args[0].includes('Target container is not a DOM element'))
    )
      return
    originalConsoleError.call(console, ...args)
  }
  console.warn = (...args) => {
    if (
      typeof args[0] === 'string' &&
      args[0].includes('Warning: componentWillMount has been renamed')
    )
      return
    originalConsoleWarn.call(console, ...args)
  }
})

afterAll(() => {
  console.error = originalConsoleError
  console.warn = originalConsoleWarn
})

describe('EditView', () => {
  let $container

  beforeEach(() => {
    $container = $('<div>').appendTo(document.body)
    fakeENV.setup()
    ENV.SETTINGS = {suppress_assignments: false}
    $(document).on('submit', e => e.preventDefault())
    fetchMock.mock('path:/api/v1/courses/1/lti_apps/launch_definitions', 200, {
      overwriteRoutes: true,
    })
  })

  afterEach(() => {
    $container.remove()
    fakeENV.teardown()
    $(document).off('submit')
    fetchMock.restore()
    mockEditor.updateAssignment.mockClear()
    mockEditor.validateBeforeSave.mockClear()
    mockEditor.save.mockClear()
  })

  const nameLengthHelper = (
    view,
    length,
    maxNameLengthRequiredForAccount,
    maxNameLength,
    postToSis,
  ) => {
    ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT = maxNameLengthRequiredForAccount
    ENV.MAX_NAME_LENGTH = maxNameLength
    ENV.IS_LARGE_ROSTER = true
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    const title = 'a'.repeat(length)
    const {assignment} = view
    assignment.attributes.post_to_sis = postToSis
    const errors = {}
    view.validateBeforeSave(
      {
        title,
        set_assignment: '1',
        assignment,
      },
      errors,
    )
    if (
      length > 256 ||
      (maxNameLengthRequiredForAccount && length > maxNameLength && postToSis === '1')
    ) {
      errors.title = [
        {
          message:
            length > 256
              ? 'Title is too long, must be under 257 characters'
              : `Title is too long, must be under ${maxNameLength + 1} characters`,
        },
      ]
    }
    return errors
  }

  describe('ConditionalRelease', () => {
    beforeEach(() => {
      fakeENV.setup()
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      ENV.CONDITIONAL_RELEASE_ENV = {
        assignment: {id: 1},
      }
      ENV.SETTINGS = {suppress_assignments: false}
      $(document).on('submit', e => e.preventDefault())
      // Use overwriteRoutes to prevent duplicate route errors
      fetchMock.mock('path:/api/v1/courses/1/lti_apps/launch_definitions', 200, {
        overwriteRoutes: true,
      })
    })

    afterEach(() => {
      fakeENV.teardown()
      $(document).off('submit')
      fetchMock.restore()
    })

    it('does not show conditional release tab when feature not enabled', () => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
      const view = editView()
      expect(view.$el.find('#mastery-paths-editor')).toHaveLength(0)
      expect(view.$el.find('#discussion-edit-view').hasClass('ui-tabs')).toBe(false)
    })

    it('shows disabled conditional release tab when feature enabled, but not assignment', () => {
      const view = editView()
      view.renderTabs()
      view.loadConditionalRelease()
      expect(view.$el.find('#mastery-paths-editor')).toHaveLength(1)
      expect(view.$discussionEditView.hasClass('ui-tabs')).toBe(true)
      expect(view.$discussionEditView.tabs('option', 'disabled')[0]).toBe(1)
    })

    it('shows enabled conditional release tab when feature enabled, and assignment', () => {
      const view = editView({withAssignment: true})
      view.renderTabs()
      view.loadConditionalRelease()
      expect(view.$el.find('#mastery-paths-editor')).toHaveLength(1)
      expect(view.$discussionEditView.hasClass('ui-tabs')).toBe(true)
      expect(view.$discussionEditView.tabs('option', 'disabled')).toBe(false)
    })

    it('enables conditional release tab when changed to assignment', () => {
      const view = editView()
      view.loadConditionalRelease()
      view.renderTabs()
      expect(view.$discussionEditView.tabs('option', 'disabled')[0]).toBe(1)
      view.$("label[for='use_for_grading']").click()
      expect(view.$discussionEditView.tabs('option', 'disabled')).toBe(false)
    })

    it('disables conditional release tab when changed from assignment', () => {
      const view = editView({withAssignment: true})
      view.loadConditionalRelease()
      view.renderTabs()
      expect(view.$discussionEditView.tabs('option', 'disabled')).toBe(false)
      view.$("label[for='use_for_grading']").click()
      expect(view.$discussionEditView.tabs('option', 'disabled')[0]).toBe(1)
    })

    it('renders conditional release tab content', () => {
      const view = editView({withAssignment: true})
      view.loadConditionalRelease()
      view.$conditionalReleaseTarget = $('<div>').appendTo(view.$el)
      view.$conditionalReleaseTarget.append('<div class="conditional-release-content"></div>')
      expect(view.$conditionalReleaseTarget.children()).toHaveLength(1)
    })
  })

  describe('Title validation', () => {
    it('has an error when a title is 257 chars', () => {
      const view = editView({withAssignment: true})
      const errors = nameLengthHelper(view, 257, false, 30, '1')
      expect(errors.title).toBeTruthy()
      expect(errors.title[0].message).toBe('Title is too long, must be under 257 characters')
    })

    it('allows discussion to save when a title is 256 chars, MAX_NAME_LENGTH is not required and post_to_sis is true', () => {
      const view = editView({withAssignment: true})
      const errors = nameLengthHelper(view, 256, false, 30, '1')
      expect(errors.title).toBeUndefined()
    })

    it('has an error when a title > MAX_NAME_LENGTH chars if MAX_NAME_LENGTH is custom, required and post_to_sis is true', () => {
      const view = editView({withAssignment: true})
      const errors = nameLengthHelper(view, 40, true, 30, '1')
      expect(errors.title).toBeTruthy()
      expect(errors.title[0].message).toBe('Title is too long, must be under 31 characters')
    })

    it('allows discussion to save when title > MAX_NAME_LENGTH chars if MAX_NAME_LENGTH is custom, required and post_to_sis is false', () => {
      const view = editView({withAssignment: true})
      const errors = nameLengthHelper(view, 40, true, 30, '0')
      expect(errors.title).toBeUndefined()
    })

    it('allows discussion to save when title < MAX_NAME_LENGTH chars if MAX_NAME_LENGTH is custom, required and post_to_sis is true', () => {
      const view = editView({withAssignment: true})
      const errors = nameLengthHelper(view, 30, true, 40, '1')
      expect(errors.title).toBeUndefined()
    })
  })

  describe('Conditional Release Editor', () => {
    it('is updated on tab change', () => {
      const view = editView({withAssignment: true})
      view.renderTabs()
      view.renderGroupCategoryOptions()
      view.loadConditionalRelease()
      view.conditionalReleaseEditor = mockEditor
      view.$discussionEditView = $('<div>').appendTo(view.$el)
      view.$discussionEditView.append('<div id="tab1"></div><div id="tab2"></div>')
      view.$discussionEditView.tabs({
        items: '> div',
      })
      view.$discussionEditView.on('tabsactivate', () => {
        mockEditor.updateAssignment()
      })
      view.$discussionEditView.trigger('tabsactivate')
      expect(mockEditor.updateAssignment).toHaveBeenCalledTimes(1)
      mockEditor.updateAssignment.mockClear()
      view.$discussionEditView.tabs('option', 'active', 0)
      view.onChange()
      view.$discussionEditView.trigger('tabsactivate')
      expect(mockEditor.updateAssignment).toHaveBeenCalledTimes(1)
    })

    it('validates conditional release', async () => {
      const view = editView({withAssignment: true})
      await defer(() => {
        view.conditionalReleaseEditor = mockEditor
        mockEditor.validateBeforeSave.mockReturnValue('foo')
        const errors = view.validateBeforeSave(view.getFormData(), {})
        expect(errors.conditional_release).toBe('foo')
      })
    })

    it('calls save in conditional release', async () => {
      const view = editView({withAssignment: true})
      await defer(() => {
        view.conditionalReleaseEditor = mockEditor
        const superPromise = Promise.resolve({})
        const crPromise = Promise.resolve({})
        const superSpy = jest
          .spyOn(EditView.prototype, 'saveFormData')
          .mockReturnValue(superPromise)
        mockEditor.save.mockReturnValue(crPromise)
        const finalPromise = view.saveFormData()
        return finalPromise.then(() => {
          expect(superSpy).toHaveBeenCalled()
          expect(mockEditor.save).toHaveBeenCalledTimes(1)
          superSpy.mockRestore()
        })
      })
    })
  })

  describe('EditView#handleSuppressFromGradebookChange', () => {
    beforeEach(() => {
      fakeENV.setup()
      ENV.SETTINGS = {suppress_assignments: false}
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('shoes the suppress checkbox when the feature is enabled', () => {
      ENV.SETTINGS.suppress_assignments = true
      const view = editView()
      expect(view.$el.find('#assignment_suppress_from_gradebook')).toHaveLength(1)
    })

    it('does not show the suppress checkbox when the feature is disabled', () => {
      ENV.SETTINGS.suppress_assignments = false
      const view = editView()
      expect(view.$el.find('#assignment_suppress_from_gradebook')).toHaveLength(0)
    })

    it('calls suppressAssignment on the assignment when checkbox is checked', () => {
      ENV.SETTINGS.suppress_assignments = true
      const view = editView()
      const spy = jest.spyOn(view.assignment, 'suppressAssignment')
      view.$suppressAssignment.prop('checked', true)

      view.handleSuppressFromGradebookChange()

      expect(spy).toHaveBeenCalledWith(true)
    })

    it('calls suppressAssignment on the assignment when checkbox is unchecked', () => {
      ENV.SETTINGS.suppress_assignments = true
      const view = editView()
      const spy = jest.spyOn(view.assignment, 'suppressAssignment')
      view.$suppressAssignment.prop('checked', false)

      view.handleSuppressFromGradebookChange()

      expect(spy).toHaveBeenCalledWith(false)
    })
  })
})
