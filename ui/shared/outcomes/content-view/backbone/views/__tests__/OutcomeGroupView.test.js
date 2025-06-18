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

import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'
import OutcomeContentBase from '../OutcomeContentBase'
import OutcomeGroup from '../../../../backbone/models/OutcomeGroup'
import OutcomeGroupView from '../OutcomeGroupView'
import {waitFor} from '@testing-library/dom'

// Stub RCE initialization
const readyForm = jest.fn()
OutcomeContentBase.prototype.readyForm = readyForm

const createView = opts => {
  const view = new OutcomeGroupView(opts)
  view.$el.appendTo(document.getElementById('fixtures'))
  return view.render()
}

describe('OutcomeGroupView', () => {
  let container
  let outcomeGroup

  beforeEach(() => {
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
    fakeENV.setup()
  })

  afterEach(() => {
    container.remove()
    fakeENV.teardown()
  })

  describe('as a teacher', () => {
    beforeEach(() => {
      ENV.PERMISSIONS = {manage_outcomes: true}
      outcomeGroup = new OutcomeGroup({
        context_type: 'Course',
        url: 'www.example.com',
        context_id: 1,
        parent_outcome_group: {subgroups_url: 'www.example.com'},
        description: 'blah',
        can_edit: true,
      })
    })

    it('renders placeholder text properly for new outcome groups', async () => {
      const view = createView({
        state: 'add',
        model: outcomeGroup,
      })

      // Use waitFor from testing-library to wait for the element to be available
      await waitFor(
        () => {
          // First verify the container exists
          const container = document.getElementById('outcome_group_title_container')
          expect(container).not.toBeNull()

          // Then check for the input with the correct placeholder
          // The input is rendered inside the React component
          const input = document.querySelector('input[placeholder="New Outcome Group"]')
          expect(input).not.toBeNull()
          expect(input.getAttribute('placeholder')).toBe('New Outcome Group')
        },
        {timeout: 1000},
      )

      view.remove()
    })

    it('validates title is present', () => {
      const view = createView({
        state: 'add',
        model: outcomeGroup,
      })
      view.$('#outcome_group_title').val('')
      expect(view.isValid()).toBe(false)
      expect(view.errors.title).toBeTruthy()
      view.remove()
    })

    it('displays move, edit, and delete buttons', () => {
      const view = createView({
        state: 'show',
        model: outcomeGroup,
      })
      const moveButton = view.$('.move_group_button')
      expect(moveButton).toHaveLength(1)
      view.remove()
    })

    it('hides move, edit, and delete buttons when read only', () => {
      const view = createView({
        state: 'show',
        model: outcomeGroup,
        readOnly: true,
      })
      const moveButton = view.$('.move_group_button')
      expect(moveButton).toHaveLength(0)
      view.remove()
    })
  })

  describe('as a student', () => {
    beforeEach(() => {
      ENV.PERMISSIONS = {manage_outcomes: false}
      outcomeGroup = new OutcomeGroup({
        context_type: 'Course',
        url: 'www.example.com',
        context_id: 1,
        parent_outcome_group: {subgroups_url: 'www.example.com'},
        description: 'blah',
        can_edit: false,
      })
    })

    it('does not display move, edit, and delete buttons', () => {
      const view = createView({
        state: 'show',
        model: outcomeGroup,
      })
      const moveButton = view.$('.move_group_button')
      expect(moveButton).toHaveLength(0)
      view.remove()
    })
  })
})
