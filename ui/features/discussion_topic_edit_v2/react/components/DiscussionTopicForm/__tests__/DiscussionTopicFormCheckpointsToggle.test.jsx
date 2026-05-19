/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {setup, setupDefaultEnv} from './DiscussionTopicFormTestHelpers'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {waitFor} from '@testing-library/react'

vi.mock('@canvas/rce/react/CanvasRce')

// This test is isolated in its own file because it involves multiple clicks
// that cause heavy re-renders, making it slow enough to timeout in CI when
// combined with other tests.
describe('DiscussionTopicForm Checkpoints Toggle', () => {
  beforeEach(() => {
    setupDefaultEnv()
  })

  afterEach(() => {
    // Clean up ENV to prevent state leakage to other tests
    window.ENV = {}
  })

  it('unchecks the checkpoints checkbox when graded is unchecked', async () => {
    // Use delay:null to skip simulated event delays — the heavy re-renders in
    // this form push against the timeout even without artificial delays.
    const user = userEvent.setup({
      delay: null,
      pointerEventsCheck: PointerEventsCheckLevel.Never,
    })
    const {getByLabelText, queryByTestId, findByTestId} = setup()

    await user.click(getByLabelText('Graded'))
    // Wait for the checkpoints checkbox to appear after graded is checked
    const checkpointsCheckbox = await findByTestId('checkpoints-checkbox')
    await user.click(checkpointsCheckbox.querySelector('input'))
    expect(checkpointsCheckbox.querySelector('input').checked).toBe(true)

    // 1st graded click will uncheck checkpoints. but it also hides from document.
    await user.click(getByLabelText('Graded'))
    // Wait for the checkpoints checkbox to be removed before re-enabling graded
    // Use a generous timeout — heavy re-renders in CI can be slow
    await waitFor(
      () => {
        expect(queryByTestId('checkpoints-checkbox')).not.toBeInTheDocument()
      },
      {timeout: 10000},
    )
    // 2nd graded click will render checkpoints, notice its unchecked.
    await user.click(getByLabelText('Graded'))
    // Wait for the checkpoints checkbox to reappear and confirm it's unchecked.
    // Use waitFor to avoid a stale-state race in CI: the checkbox may appear
    // before React finishes updating the checked state.
    await waitFor(
      async () => {
        const recheckCheckbox = await findByTestId('checkpoints-checkbox')
        expect(recheckCheckbox.querySelector('input').checked).toBe(false)
      },
      {timeout: 10000},
    )
  }, 60000)
})
