/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {reject} from 'es-toolkit/compat'
import ShowEventDetailsDialog from '../ShowEventDetailsDialog'
import eventDetailsTemplate from '../../jst/eventDetails.handlebars'
import Popover from 'jquery-popover'

vi.mock('jquery-popover')
vi.mock('../../jst/eventDetails.handlebars', () => ({default: vi.fn()}))
vi.mock('jquery-tinypubsub', () => ({publish: vi.fn(), subscribe: vi.fn()}))

describe('ShowEventDetailsDialog appointment cancellation', () => {
  describe('child_events filtering with reject', () => {
    it('removes canceled appointment from child_events array', () => {
      const childEvents = [
        {url: '/appointments/1', user: {id: '1', name: 'User 1'}},
        {url: '/appointments/2', user: {id: '2', name: 'User 2'}},
        {url: '/appointments/3', user: {id: '3', name: 'User 3'}},
      ]

      const urlToRemove = '/appointments/2'
      const result = reject(childEvents, e => e.url === urlToRemove)

      expect(result).toEqual([
        {url: '/appointments/1', user: {id: '1', name: 'User 1'}},
        {url: '/appointments/3', user: {id: '3', name: 'User 3'}},
      ])
      expect(result).toHaveLength(2)
    })

    it('returns an array that can be iterated with forEach', () => {
      const childEvents = [
        {url: '/appointments/1', user: {id: '1', name: 'User 1'}},
        {url: '/appointments/2', user: {id: '2', name: 'User 2'}},
      ]

      const result = reject(childEvents, e => e.url === '/appointments/2')

      // Verify it's a real array with forEach method
      expect(Array.isArray(result)).toBe(true)
      expect(typeof result.forEach).toBe('function')

      // Verify forEach works correctly
      const names = []
      result.forEach(e => {
        names.push(e.user.name)
      })
      expect(names).toEqual(['User 1'])
    })

    it('handles empty array after filtering', () => {
      const childEvents = [{url: '/appointments/1', user: {id: '1', name: 'User 1'}}]

      const result = reject(childEvents, e => e.url === '/appointments/1')

      expect(result).toEqual([])
      expect(result).toHaveLength(0)
      expect(Array.isArray(result)).toBe(true)
    })

    it('handles no matches - returns all items', () => {
      const childEvents = [
        {url: '/appointments/1', user: {id: '1', name: 'User 1'}},
        {url: '/appointments/2', user: {id: '2', name: 'User 2'}},
      ]

      const result = reject(childEvents, e => e.url === '/appointments/999')

      expect(result).toEqual(childEvents)
      expect(result).toHaveLength(2)
    })

    it('returns an array not a LodashWrapper (regression test for migration bug)', () => {
      const childEvents = [
        {url: '/appointments/1', user: {id: '1', name: 'User 1'}},
        {url: '/appointments/2', user: {id: '2', name: 'User 2'}},
      ]

      const result = reject(childEvents, e => e.url === '/appointments/2')

      // The old lodash code without .value() would return a LodashWrapper
      // Verify we get a plain array, not a wrapper object
      expect(Array.isArray(result)).toBe(true)
      expect(result.constructor.name).toBe('Array')
      expect(result).not.toHaveProperty('value') // LodashWrapper has a .value() method
    })
  })
})

describe('ShowEventDetailsDialog edit button for peer review assignments', () => {
  let originalLocation

  const buildEvent = (overrides = {}) => ({
    contexts: [],
    contextInfo: {
      user_is_student: false,
      user_is_observer: false,
      allow_observers_in_appointment_groups: false,
      can_view_context: false,
    },
    object: {
      reserve_url: null,
      child_events: [],
      parent_event_id: null,
      available_slots: undefined,
      reserve_comments: null,
      comments: null,
    },
    calendarEvent: null,
    eventType: 'assignment',
    assignment: {
      html_url: '/courses/1/assignments/2',
      peer_review_sub_assignment_enabled: false,
    },
    isAppointmentGroupEvent: vi.fn(() => null),
    endDate: vi.fn(),
    fullDetailsURL: vi.fn(() => null),
    ...overrides,
  })

  beforeEach(() => {
    vi.mocked(eventDetailsTemplate).mockReturnValue('<button class="edit_event_link">Edit</button>')
    vi.mocked(Popover).mockImplementation((_jsEvent, html) => {
      const container = document.createElement('div')
      container.innerHTML = html
      return {el: $(container), trapFocus: vi.fn(), hide: vi.fn()}
    })

    document.body.innerHTML = '<div id="event-details-trap-focus"></div>'

    window.ENV = {CALENDAR: {SHOW_SCHEDULER: false}}

    originalLocation = window.location
    delete window.location
    window.location = {href: ''}
  })

  afterEach(() => {
    window.location = originalLocation
    vi.clearAllMocks()
  })

  it('editSubAssignment navigates to the assignment edit page', () => {
    const event = buildEvent({
      assignment: {html_url: '/courses/1/assignments/2', peer_review_sub_assignment_enabled: true},
    })
    const dialog = new ShowEventDetailsDialog(event, {})
    dialog.editSubAssignment()
    expect(window.location.href).toBe('/courses/1/assignments/2/edit')
  })

  it('wires edit button to editSubAssignment when peer_review_sub_assignment_enabled is true', () => {
    const event = buildEvent({
      assignment: {html_url: '/courses/1/assignments/2', peer_review_sub_assignment_enabled: true},
    })
    const dialog = new ShowEventDetailsDialog(event, {})
    const editSubSpy = vi.spyOn(dialog, 'editSubAssignment').mockImplementation(() => {})
    dialog.show({preventDefault: vi.fn()})
    dialog.popover.el.find('.edit_event_link').trigger('click')
    expect(editSubSpy).toHaveBeenCalled()
  })

  it('wires edit button to editSubAssignment for an assignment_override when peer_review_sub_assignment_enabled is true', () => {
    const event = buildEvent({
      eventType: 'assignment_override',
      assignment: {html_url: '/courses/1/assignments/2', peer_review_sub_assignment_enabled: true},
    })
    const dialog = new ShowEventDetailsDialog(event, {})
    const editSubSpy = vi.spyOn(dialog, 'editSubAssignment').mockImplementation(() => {})
    dialog.show({preventDefault: vi.fn()})
    dialog.popover.el.find('.edit_event_link').trigger('click')
    expect(editSubSpy).toHaveBeenCalled()
  })

  it('wires edit button to the normal edit dialog for an assignment_override when peer_review_sub_assignment_enabled is false', () => {
    const event = buildEvent({
      eventType: 'assignment_override',
      assignment: {html_url: '/courses/1/assignments/2', peer_review_sub_assignment_enabled: false},
    })
    const dialog = new ShowEventDetailsDialog(event, {})
    const editSubSpy = vi.spyOn(dialog, 'editSubAssignment').mockImplementation(() => {})
    const showEditSpy = vi.spyOn(dialog, 'showEditDialog').mockImplementation(() => {})
    dialog.show({preventDefault: vi.fn()})
    dialog.popover.el.find('.edit_event_link').trigger('click')
    expect(editSubSpy).not.toHaveBeenCalled()
    expect(showEditSpy).toHaveBeenCalled()
  })
})
