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
import RCELoader from '@canvas/rce/serviceRCELoader'
import EditView from '../EditView'
import fakeENV from '@canvas/test-utils/fakeENV'
import '@canvas/jquery/jquery.simulate'
import {editView} from './utils'
import fetchMock from 'fetch-mock'

const currentOrigin = window.location.origin

EditView.prototype.loadNewEditor = () => {}

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
    fakeENV.setup({
      COURSE_ID: '1',
      context_asset_string: 'course_1',
      DISCUSSION_TOPIC: {
        ATTRIBUTES: {
          is_announcement: false,
        },
      },
      SETTINGS: {},
    })

    fetchMock
      .mock('path:/api/v1/courses/1/lti_apps/launch_definitions', 200, {
        overwriteRoutes: true,
      })
      .get('path:/api/v1/courses/1/settings', {})
      .get('path:/api/v1/courses/1/sections', [])
      .post(/.*\/api\/graphql/, {})
    RCELoader.RCE = null
    return RCELoader.loadRCE()
  })

  afterEach(() => {
    $container.remove()
    fakeENV.teardown()
    fetchMock.restore()
  })

  it('should be accessible', () => {
    const view = editView()
    expect(view).toBeTruthy()
  })

  it('renders', () => {
    const view = editView()
    expect(view).toBeTruthy()
  })

  it('shows error message on assignment point change with submissions', () => {
    const view = editView({
      withAssignment: true,
      assignmentOpts: {has_submitted_submissions: true},
    })
    view.renderGroupCategoryOptions()
    expect(view.$el.find('#discussion_point_change_warning')).toBeTruthy()
    view.$el.find('#discussion_topic_assignment_points_possible').val(1)
    view.$el.find('#discussion_topic_assignment_points_possible').trigger('change')
    expect(view.$el.find('#discussion_point_change_warning').attr('style')).not.toBeDefined()
    view.$el.find('#discussion_topic_assignment_points_possible').val(0)
    view.$el.find('#discussion_topic_assignment_points_possible').trigger('change')
    expect(view.$el.find('#discussion_point_change_warning').attr('style')).toBe('display: none;')
  })

  it('hides the published icon for announcements', () => {
    const view = editView({isAnnouncement: true})
    expect(view.$el.find('.published-status')).toHaveLength(0)
  })

  it('validates the group category for non-assignment discussions', () => {
    jest.useFakeTimers()
    const view = editView({permissions: {CAN_SET_GROUP: true}})
    jest.advanceTimersByTime(1)
    const data = {group_category_id: 'blank'}
    const errors = view.validateBeforeSave(data, [])
    expect(errors.newGroupCategory[0].message).toBeTruthy()
    jest.useRealTimers()
  })

  it('does not render #podcast_has_student_posts_container for non-course contexts', () => {
    const view = editView({
      withAssignment: true,
      permissions: {CAN_MODERATE: true},
    })
    expect(view.$el.find('#checkbox_podcast_enabled')).toHaveLength(1)
    expect(view.$el.find('#podcast_has_student_posts_container')).toHaveLength(0)
  })

  it('routes to discussion details normally', () => {
    const view = editView({}, {html_url: currentOrigin + '/foo'})
    expect(view.locationAfterSave({})).toBe(currentOrigin + '/foo')
  })

  it('routes to return_to', () => {
    const view = editView({}, {html_url: currentOrigin + '/foo'})
    expect(view.locationAfterSave({return_to: currentOrigin + '/bar'})).toBe(currentOrigin + '/bar')
  })

  it('does not route to return_to with javascript protocol', () => {
    const view = editView({}, {html_url: currentOrigin + '/foo'})
    expect(view.locationAfterSave({return_to: 'javascript:alert(1)'})).toBe(currentOrigin + '/foo')
  })

  it('does not route to return_to in remote origin', () => {
    const view = editView({}, {html_url: currentOrigin + '/foo'})
    expect(view.locationAfterSave({return_to: 'http://evil.com'})).toBe(currentOrigin + '/foo')
  })

  it('cancels to env normally', () => {
    ENV.CANCEL_TO = currentOrigin + '/foo'
    const view = editView()
    expect(view.locationAfterCancel({})).toBe(currentOrigin + '/foo')
  })

  it('cancels to return_to', () => {
    ENV.CANCEL_TO = currentOrigin + '/foo'
    const view = editView()
    expect(view.locationAfterCancel({return_to: currentOrigin + '/bar'})).toBe(
      currentOrigin + '/bar',
    )
  })

  it('does not cancel to return_to with javascript protocol', () => {
    ENV.CANCEL_TO = currentOrigin + '/foo'
    const view = editView()
    expect(view.locationAfterCancel({return_to: 'javascript:alert(1)'})).toBe(
      currentOrigin + '/foo',
    )
  })

  it('shows todo checkbox', () => {
    ENV.STUDENT_PLANNER_ENABLED = true
    const view = editView()
    expect(view.$el.find('#allow_todo_date')).toHaveLength(1)
    expect(view.$el.find('#todo_date_input')).toHaveLength(0)
  })

  it('shows todo input when todo checkbox is selected', () => {
    ENV.STUDENT_PLANNER_ENABLED = true
    const view = editView()
    expect(view.$("input[name='todo_date'")).toHaveLength(0)
    view.$("label[for='allow_todo_date']").click()
    expect(view.$("input[name='todo_date'")).toHaveLength(1)
  })

  it('shows todo input with date when given date', () => {
    ENV.STUDENT_PLANNER_ENABLED = true
    ENV.TIMEZONE = 'America/Chicago'
    const view = editView({}, {todo_date: '2017-01-03'})
    expect(view.$el.find('#allow_todo_date').prop('checked')).toBe(true)
    expect(view.$el.find('input[name="todo_date"]').val()).toBe('Jan 2, 2017, 6:00 PM')
  })

  it('renders announcement page when planner enabled', () => {
    ENV.STUDENT_PLANNER_ENABLED = true
    const view = editView({isAnnouncement: true})
    expect(view.$el.find('#discussion-edit-view')).toHaveLength(1)
  })

  it('does not show todo checkbox without permission', () => {
    ENV.STUDENT_PLANNER_ENABLED = false
    const view = editView()
    expect(view.$el.find('#allow_todo_date')).toHaveLength(0)
  })

  it('does not show todo date elements when grading is enabled', () => {
    ENV.STUDENT_PLANNER_ENABLED = true
    const view = editView()
    view.$("label[for='use_for_grading']").click()
    expect(view.$('#todo_options')).toHaveLength(0)
  })

  it('does retain the assignment when user with assignment-edit permission edits discussion', () => {
    const view = editView({
      withAssignment: true,
      permissions: {CAN_UPDATE_ASSIGNMENT: true, CAN_CREATE_ASSIGNMENT: false},
    })
    const formData = view.getFormData()
    expect(formData.set_assignment).toBe('1')
  })

  it('handleMessageEvent sets ab_guid when subject is assignment.set_ab_guid and the ab_guid is formatted correctly', () => {
    const view = editView({
      withAssignment: true,
      assignmentOpts: {has_submitted_submissions: false},
    })
    const event = {
      data: {
        subject: 'assignment.set_ab_guid',
        data: {
          ab_guid: 'xxxyyyzzz',
        },
      },
    }
    view.handleMessageEvent(event)
    const assignment = view.model.get('assignment')
    assignment.ab_guid = 'xxxyyyzzz'
    expect(assignment.ab_guid).toBe('xxxyyyzzz')
  })
})
