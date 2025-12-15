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

import {waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import * as Api from '../Api'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {
  MockContext,
  createDefaultContext,
  renderTray,
  getTray,
  getSaveButton,
  getCancelButton,
  getCloseButton,
  getInput,
} from './AssignmentPostingPolicyTrayTestUtils'

vi.mock('@canvas/alerts/react/FlashAlert')
vi.mock('../Api')

describe('AssignmentPostingPolicyTray', () => {
  let context: MockContext

  beforeEach(() => {
    context = createDefaultContext()

    // @ts-expect-error
    FlashAlert.showFlashAlert.mockReset()
    // @ts-expect-error
    Api.setAssignmentPostPolicy.mockReset()
  })

  afterEach(async () => {
    if (getTray()) {
      await userEvent.click(getCloseButton())
      await waitFor(() => expect(context.onExited).toHaveBeenCalled())
    }
    vi.clearAllMocks()
  })

  describe('"Close" Button', () => {
    beforeEach(async () => {
      renderTray(context)
      await waitFor(() => expect(getTray()).toBeInTheDocument())
    })

    it('closes the tray', async () => {
      await userEvent.click(getCloseButton())
      await waitFor(() => {
        expect(getTray()).not.toBeInTheDocument()
      })
    })
  })

  describe('"Cancel" button', () => {
    beforeEach(async () => {
      renderTray(context)
      await waitFor(() => expect(getTray()).toBeInTheDocument())
    })

    it('closes the tray', async () => {
      await userEvent.click(getCancelButton())
      await waitFor(() => {
        expect(getTray()).not.toBeInTheDocument()
      })
    })

    it('is enabled when no request is in progress', () => {
      expect(getCancelButton()).toBeEnabled()
    })

    it('is disabled when a request is in progress', async () => {
      let resolveRequest
      // @ts-expect-error
      Api.setAssignmentPostPolicy.mockImplementation(
        () =>
          new Promise(resolve => {
            resolveRequest = () => {
              resolve({assignmentId: '2301', postManually: true})
            }
          }),
      )

      await userEvent.click(getInput('Manually'))
      await userEvent.click(getSaveButton())
      expect(getCancelButton()).toBeDisabled()
      // @ts-expect-error
      resolveRequest()
    })
  })
})
