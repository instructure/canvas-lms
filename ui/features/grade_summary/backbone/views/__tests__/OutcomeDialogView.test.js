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
import {waitFor} from '@testing-library/dom'
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import OutcomeDialogView from '../OutcomeDialogView'
import OutcomeLineGraphView from '../OutcomeLineGraphView'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import fakeEnv from '@canvas/test-utils/fakeENV'

const server = setupServer(
  http.get('*/api/v1/courses/:courseId/outcome_results', () => {
    return HttpResponse.json({
      outcome_results: [],
      linked: {
        alignments: [],
      },
    })
  }),
)

describe('OutcomeDialogView', () => {
  beforeAll(() => server.listen({onUnhandledRequest: 'bypass'}))
  afterAll(() => server.close())

  let outcomeDialogView
  let mockEvent
  let $dialog
  let dialogSpy

  beforeEach(async () => {
    // Set up ENV object for OutcomeResultCollection
    fakeEnv.setup({
      context_asset_string: 'course_123',
      student_id: '456',
      current_user: {
        display_name: 'Test User',
      },
    })

    const readyCallback = vi.fn()
    $(document).ready(readyCallback)
    $(document).trigger('ready')
    await waitFor(() => expect(readyCallback).toHaveBeenCalled())

    // Mock jQuery dialog
    $dialog = $('<div>')
    $dialog.parent = () => ({
      attr: vi.fn().mockReturnThis(),
    })
    dialogSpy = vi.fn().mockReturnValue($dialog)
    $.fn.dialog = dialogSpy

    outcomeDialogView = new OutcomeDialogView({model: new Outcome()})
    mockEvent = (name, options = {}) => {
      return $.Event(name, {...options, currentTarget: outcomeDialogView.el})
    }
  })

  afterEach(() => {
    outcomeDialogView.remove()
    vi.restoreAllMocks()
    server.resetHandlers()
    fakeEnv.teardown()
  })

  it('creates an instance of OutcomeLineGraphView on initialization', () => {
    expect(outcomeDialogView.outcomeLineGraphView).toBeInstanceOf(OutcomeLineGraphView)
  })

  describe('afterRender', () => {
    it('sets element and renders line graph', () => {
      const setElementSpy = vi.spyOn(outcomeDialogView.outcomeLineGraphView, 'setElement')
      const renderSpy = vi.spyOn(outcomeDialogView.outcomeLineGraphView, 'render')

      outcomeDialogView.render()

      expect(setElementSpy).toHaveBeenCalled()
      expect(renderSpy).toHaveBeenCalled()
    })
  })

  describe('show', () => {
    beforeEach(() => {
      vi.spyOn(outcomeDialogView, 'render')
      dialogSpy.mockClear()
    })

    it('does not render or open dialog on mouseenter without keycode', () => {
      outcomeDialogView.show(mockEvent('mouseenter'))

      expect(outcomeDialogView.render).not.toHaveBeenCalled()
      expect(dialogSpy).not.toHaveBeenCalledWith('open')
    })

    it('renders and opens dialog with KeyCode 13', () => {
      outcomeDialogView.show(mockEvent('mouseenter', {keyCode: 13}))

      expect(outcomeDialogView.render).toHaveBeenCalled()
      expect(dialogSpy).toHaveBeenCalledWith('open')
    })

    it('renders and opens dialog with KeyCode 32', () => {
      outcomeDialogView.show(mockEvent('mouseenter', {keyCode: 32}))

      expect(outcomeDialogView.render).toHaveBeenCalled()
      expect(dialogSpy).toHaveBeenCalledWith('open')
    })

    it.each([8, 27])('does not render or open dialog with KeyCode %i', keyCode => {
      outcomeDialogView.show(mockEvent('mouseenter', {keyCode}))

      expect(outcomeDialogView.render).not.toHaveBeenCalled()
      expect(dialogSpy).not.toHaveBeenCalledWith('open')
    })

    it('renders and opens dialog on click', () => {
      outcomeDialogView.show(mockEvent('click'))

      expect(outcomeDialogView.render).toHaveBeenCalled()
      expect(dialogSpy).toHaveBeenCalledWith('open')
    })
  })

  describe('toJSON', () => {
    it('includes dialog key', () => {
      expect(outcomeDialogView.toJSON()).toHaveProperty('dialog', true)
    })
  })
})
