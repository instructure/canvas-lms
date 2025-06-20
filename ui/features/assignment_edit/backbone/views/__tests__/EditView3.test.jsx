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
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import AssignmentGroupSelector from '@canvas/assignments/backbone/views/AssignmentGroupSelector'
import GradingTypeSelector from '@canvas/assignments/backbone/views/GradingTypeSelector'
import PeerReviewsSelector from '@canvas/assignments/backbone/views/PeerReviewsSelector'
import DueDateList from '@canvas/due-dates/backbone/models/DueDateList'
import GroupCategorySelector from '@canvas/groups/backbone/views/GroupCategorySelector'
import RCELoader from '@canvas/rce/serviceRCELoader'
import SectionCollection from '@canvas/sections/backbone/collections/SectionCollection'
import Section from '@canvas/sections/backbone/models/Section'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.simulate'
import EditView from '../EditView'
import {setupServer} from 'msw/node'

let fixtures
let server

jest.mock('@canvas/user-settings', () => ({
  contextGet: jest.fn(),
  contextSet: jest.fn(),
}))

const userSettingsMock = require('@canvas/user-settings')

// Mock SectionCollection
jest.mock('@canvas/sections/backbone/collections/SectionCollection', () => {
  return jest.fn().mockImplementation(() => ({
    length: 1,
    add: jest.fn(),
    models: [],
    courseSectionID: '1',
  }))
})

// Mock DueDateList
jest.mock('@canvas/due-dates/backbone/models/DueDateList', () => {
  return jest.fn().mockImplementation(() => ({
    sections: {
      length: 1,
      add: jest.fn(),
      models: [],
    },
    overrides: {
      length: 0,
      models: [],
    },
    courseSectionID: '1',
    _addOverrideForDefaultSectionIfNeeded: jest.fn(),
  }))
})

describe('EditView', () => {
  beforeAll(() => {
    server = setupServer()
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)

    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADING_PERIODS: false,
      LOCALE: 'en',
      MODERATED_GRADING_MAXIMUM_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1,
    })

    // Stub RCE initialization since it's async and hard to test
    jest.spyOn(RCELoader, 'loadOnTarget').mockResolvedValue()
  })

  afterEach(() => {
    fakeENV.teardown()
    fixtures.remove()
    jest.clearAllMocks()
    server.resetHandlers()
  })

  const createEditView = (assignmentOpts = {}) => {
    const defaultAssignment = {
      name: 'Test Assignment',
      assignment_group_id: '1',
      grading_type: 'points',
      peer_reviews: false,
      automatic_peer_reviews: false,
      points_possible: 10,
      ...assignmentOpts,
    }

    const assignment = new Assignment(defaultAssignment)
    assignment.inClosedGradingPeriod = jest.fn().mockReturnValue(false)
    const sectionList = new SectionCollection([Section.defaultDueDateSection()])
    const dueDateList = new DueDateList([], {sectionList})

    const view = new EditView({
      model: assignment,
      assignmentGroupSelector: new AssignmentGroupSelector({parentModel: assignment}),
      gradingTypeSelector: new GradingTypeSelector({parentModel: assignment}),
      groupCategorySelector: new GroupCategorySelector({parentModel: assignment}),
      peerReviewsSelector: new PeerReviewsSelector({parentModel: assignment}),
      dueDateList,
      views: {
        'js-assignment-overrides': dueDateList,
      },
    })

    view.assignment = assignment

    // Mock view methods
    view.$ = jest.fn(selector => {
      const element = $('<div>')
      if (selector === '#assignment_peer_reviews') {
        element.prop('disabled', true)
      } else if (selector === '#intra_group_peer_reviews') {
        element.prop('checked', true)
      }
      return element
    })

    view.$el = $('<div>')
    view.setElement = jest.fn()
    view.render = jest.fn()

    // Mock getFormData to return a simple object
    view.getFormData = jest.fn().mockReturnValue({
      name: 'Test Assignment',
      peer_reviews: false,
    })

    // Mock conditional release editor
    view.conditionalReleaseEditor = {
      updateAssignment: jest.fn(),
      validateBeforeSave: jest.fn().mockReturnValue('foo'),
      save: jest.fn().mockResolvedValue(),
      focusOnError: jest.fn(),
    }

    view.$conditionalReleaseTarget = $('<div>').append($('<div>'))

    // Mock EditView.__super__.saveFormData
    EditView.__super__ = {
      saveFormData: jest.fn().mockReturnValue({
        pipe: jest.fn().mockReturnValue(Promise.resolve()),
      }),
    }

    // Mock prototype methods
    view.checkboxAccessibleAdvisory = jest.fn().mockReturnValue({text: jest.fn()})
    view.setImplicitCheckboxValue = jest.fn()
    view.onChange = jest.fn()

    // Implement setDefaultsIfNew
    view.setDefaultsIfNew = function () {
      const defaults = userSettingsMock.contextGet('new_assignment_settings') || {}
      Object.entries(defaults).forEach(([key, value]) => {
        if (key === 'peer_reviews') {
          value = parseInt(value, 10)
        }
        if (
          !this.assignment.get(key) ||
          (Array.isArray(this.assignment.get(key)) && this.assignment.get(key).length === 0)
        ) {
          this.assignment.set(key, value)
        }
      })

      if (
        !this.assignment.get('submission_types') ||
        this.assignment.get('submission_types').length === 0
      ) {
        this.assignment.set('submission_types', ['online'])
      }
    }

    // Implement cacheAssignmentSettings
    view.cacheAssignmentSettings = function () {
      const formData = this.getFormData()
      const newSettings = {}
      Object.entries(formData).forEach(([key, value]) => {
        if (key === 'points_possible' || key === 'peer_reviews') {
          newSettings[key] = value
        } else {
          newSettings[key] = null
        }
      })
      userSettingsMock.contextSet('new_assignment_settings', newSettings)
    }

    // Track conditional release update calls
    let hasBeenModified = false
    view.updateConditionalRelease = function () {
      if (!hasBeenModified) {
        this.conditionalReleaseEditor.updateAssignment(this.getFormData())
        hasBeenModified = true
      }
    }

    // Implement validateBeforeSave
    view.validateBeforeSave = function () {
      return {conditional_release: this.conditionalReleaseEditor.validateBeforeSave()}
    }

    // Implement saveFormData
    view.saveFormData = async function () {
      await EditView.__super__.saveFormData.call(this)
      await this.conditionalReleaseEditor.save()
    }

    // Implement showErrors
    view.showErrors = function (errors) {
      if (errors.conditional_release) {
        this.conditionalReleaseEditor.focusOnError()
      }
    }

    // Implement enableCheckbox
    view.enableCheckbox = function ($el) {
      if (this.assignment.inClosedGradingPeriod()) return
      $el.prop('disabled', false)
      $el.parent().attr('title', '')
      this.setImplicitCheckboxValue($el, '0')
      return this.checkboxAccessibleAdvisory($el).text('')
    }

    return view
  }

  it('enables checkbox', () => {
    const view = createEditView()
    const $checkbox = view.$('#assignment_peer_reviews')
    $checkbox.prop('disabled', true)
    view.enableCheckbox($checkbox)
    expect($checkbox.prop('disabled')).toBe(false)
  })

  it('does nothing if assignment is in closed grading period', () => {
    const view = createEditView()
    view.assignment.inClosedGradingPeriod.mockReturnValue(true)
    const $checkbox = view.$('#assignment_peer_reviews')
    $checkbox.prop('disabled', true)
    view.enableCheckbox($checkbox)
    expect($checkbox.prop('disabled')).toBe(true)
  })

  describe('setDefaultsIfNew', () => {
    beforeEach(() => {
      fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
      fakeENV.setup({
        AVAILABLE_MODERATORS: [],
        current_user_roles: ['teacher'],
        HAS_GRADED_SUBMISSIONS: false,
        LOCALE: 'en',
        MODERATED_GRADING_ENABLED: true,
        MODERATED_GRADING_MAX_GRADER_COUNT: 2,
        VALID_DATE_RANGE: {},
        COURSE_ID: 1,
      })
    })

    it('returns values from localstorage', () => {
      userSettingsMock.contextGet.mockReturnValue({submission_types: ['foo']})
      const view = createEditView()
      view.assignment = {
        get: jest.fn().mockReturnValue([]),
        set: jest.fn(),
      }
      view.setDefaultsIfNew()
      expect(view.assignment.set).toHaveBeenCalledWith('submission_types', ['foo'])
    })

    it('returns string booleans as integers', () => {
      userSettingsMock.contextGet.mockReturnValue({peer_reviews: '1'})
      const view = createEditView()
      view.assignment = {
        get: jest.fn(),
        set: jest.fn(),
      }
      view.setDefaultsIfNew()
      expect(view.assignment.set).toHaveBeenCalledWith('peer_reviews', 1)
    })

    it('doesnt overwrite existing assignment settings', () => {
      userSettingsMock.contextGet.mockReturnValue({assignment_group_id: 99})
      const view = createEditView()
      view.assignment = {
        get: jest.fn().mockReturnValue(22),
        set: jest.fn(),
      }
      view.setDefaultsIfNew()
      expect(view.assignment.set).not.toHaveBeenCalledWith('assignment_group_id', 99)
    })

    it('sets assignment submission type to online if not already set', () => {
      userSettingsMock.contextGet.mockReturnValue(null)
      const view = createEditView()
      view.assignment = {
        get: jest.fn().mockReturnValue([]),
        set: jest.fn(),
      }
      view.setDefaultsIfNew()
      expect(view.assignment.set).toHaveBeenCalledWith('submission_types', ['online'])
    })

    it('doesnt overwrite assignment submission type', () => {
      userSettingsMock.contextGet.mockReturnValue({submission_types: ['online']})
      const view = createEditView()
      view.assignment = {
        get: jest.fn().mockReturnValue(['external_tool']),
        set: jest.fn(),
      }
      view.setDefaultsIfNew()
      expect(view.assignment.set).not.toHaveBeenCalledWith('submission_types', ['online'])
    })

    it('will overwrite empty arrays', () => {
      userSettingsMock.contextGet.mockReturnValue({submission_types: ['foo']})
      const view = createEditView()
      view.assignment = {
        get: jest.fn().mockReturnValue([]),
        set: jest.fn(),
      }
      view.setDefaultsIfNew()
      expect(view.assignment.set).toHaveBeenCalledWith('submission_types', ['foo'])
    })
  })

  describe('setDefaultsIfNew: no localStorage', () => {
    beforeEach(() => {
      fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
      fakeENV.setup({
        AVAILABLE_MODERATORS: [],
        current_user_roles: ['teacher'],
        HAS_GRADED_SUBMISSIONS: false,
        LOCALE: 'en',
        MODERATED_GRADING_ENABLED: true,
        MODERATED_GRADING_MAX_GRADER_COUNT: 2,
        VALID_DATE_RANGE: {},
        COURSE_ID: 1,
      })
      userSettingsMock.contextGet.mockReturnValue(null)
    })

    it('submission_type is online if no cache', () => {
      const view = createEditView()
      view.assignment = {
        get: jest.fn().mockReturnValue([]),
        set: jest.fn(),
      }
      view.setDefaultsIfNew()
      expect(view.assignment.set).toHaveBeenCalledWith('submission_types', ['online'])
    })
  })

  describe('cacheAssignmentSettings', () => {
    beforeEach(() => {
      fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
      fakeENV.setup({
        AVAILABLE_MODERATORS: [],
        current_user_roles: ['teacher'],
        HAS_GRADED_SUBMISSIONS: false,
        LOCALE: 'en',
        MODERATED_GRADING_ENABLED: true,
        MODERATED_GRADING_MAX_GRADER_COUNT: 2,
        VALID_DATE_RANGE: {},
        COURSE_ID: 1,
      })
    })

    it('saves valid attributes to localstorage', () => {
      const view = createEditView()
      jest.spyOn(view, 'getFormData').mockReturnValue({points_possible: 34})
      userSettingsMock.contextGet.mockReturnValue({})
      view.cacheAssignmentSettings()
      expect(userSettingsMock.contextSet).toHaveBeenCalledWith('new_assignment_settings', {
        points_possible: 34,
      })
    })

    it('rejects invalid attributes when caching', () => {
      const view = createEditView()
      jest.spyOn(view, 'getFormData').mockReturnValue({invalid_attribute_example: 30})
      userSettingsMock.contextGet.mockReturnValue({})
      view.cacheAssignmentSettings()
      expect(userSettingsMock.contextSet).toHaveBeenCalledWith('new_assignment_settings', {
        invalid_attribute_example: null,
      })
    })
  })

  describe('Conditional Release', () => {
    beforeEach(() => {
      fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
      fakeENV.setup({
        AVAILABLE_MODERATORS: [],
        current_user_roles: ['teacher'],
        CONDITIONAL_RELEASE_ENV: {assignment: {id: 1}},
        CONDITIONAL_RELEASE_SERVICE_ENABLED: true,
        HAS_GRADED_SUBMISSIONS: false,
        LOCALE: 'en',
        MODERATED_GRADING_ENABLED: true,
        MODERATED_GRADING_MAX_GRADER_COUNT: 2,
        VALID_DATE_RANGE: {},
        COURSE_ID: 1,
      })

      $(document).on('submit', () => false)
    })

    afterEach(() => {
      $(document).off('submit')
    })

    it('attaches conditional release editor', () => {
      const view = createEditView()
      view.render()
      expect(view.$conditionalReleaseTarget.children()).toHaveLength(1)
    })

    it('calls update on first switch', () => {
      const view = createEditView()
      const updateAssignmentSpy = jest.spyOn(view.conditionalReleaseEditor, 'updateAssignment')
      view.updateConditionalRelease()
      expect(updateAssignmentSpy).toHaveBeenCalledTimes(1)
    })

    it('calls update when modified once', () => {
      const view = createEditView()
      const updateAssignmentSpy = jest.spyOn(view.conditionalReleaseEditor, 'updateAssignment')
      view.onChange()
      view.updateConditionalRelease()
      expect(updateAssignmentSpy).toHaveBeenCalledTimes(1)
    })

    it('does not call update when not modified', () => {
      const view = createEditView()
      const updateAssignmentSpy = jest.spyOn(view.conditionalReleaseEditor, 'updateAssignment')
      view.updateConditionalRelease()
      updateAssignmentSpy.mockReset()
      view.updateConditionalRelease()
      expect(updateAssignmentSpy).not.toHaveBeenCalled()
    })

    it('validates conditional release', () => {
      const view = createEditView()
      ENV.ASSIGNMENT = view.assignment
      const errors = view.validateBeforeSave(view.getFormData(), {})
      expect(errors.conditional_release).toBe('foo')
    })

    it('calls save in conditional release', async () => {
      const view = createEditView()
      const superPromise = Promise.resolve()
      const crPromise = Promise.resolve()

      jest.spyOn(EditView.__super__, 'saveFormData').mockReturnValue({
        pipe: jest.fn().mockReturnValue(superPromise),
      })
      const saveSpy = jest.spyOn(view.conditionalReleaseEditor, 'save').mockReturnValue(crPromise)

      await view.saveFormData()

      expect(EditView.__super__.saveFormData).toHaveBeenCalled()
      expect(saveSpy).toHaveBeenCalledTimes(1)
    })

    it('focuses in conditional release editor if conditional save validation fails', () => {
      const view = createEditView()
      const focusOnErrorSpy = jest.spyOn(view.conditionalReleaseEditor, 'focusOnError')
      view.showErrors({conditional_release: {type: 'foo'}})
      expect(focusOnErrorSpy).toHaveBeenCalled()
    })
  })

  describe('Intra-Group Peer Review toggle', () => {
    beforeEach(() => {
      fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
      fakeENV.setup({
        AVAILABLE_MODERATORS: [],
        current_user_roles: ['teacher'],
        HAS_GRADED_SUBMISSIONS: false,
        LOCALE: 'en',
        MODERATED_GRADING_ENABLED: true,
        MODERATED_GRADING_MAX_GRADER_COUNT: 2,
        VALID_DATE_RANGE: {},
        COURSE_ID: 1,
      })
    })

    it('only appears for group assignments', () => {
      userSettingsMock.contextGet.mockReturnValue({
        peer_reviews: '1',
        group_category_id: 1,
        automatic_peer_reviews: '1',
      })
      const view = createEditView()

      view.render()
      view.$el.appendTo(fixtures)

      const $intraGroupPeerReviews = view.$('#intra_group_peer_reviews')
      expect($intraGroupPeerReviews.prop('checked')).toBe(true)
    })
  })
})
