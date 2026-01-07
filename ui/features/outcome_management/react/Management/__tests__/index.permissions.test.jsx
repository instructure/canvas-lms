/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {act} from '@testing-library/react'
import OutcomeManagementPanel from '../index'
import {
  setupTest,
  clickWithPending,
} from './testSetup'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))
vi.mock('@canvas/rce/RichContentEditor')
vi.mock('axios')
vi.useFakeTimers()

// FOO-3827
describe('OutcomeManagementPanel - Permissions', () => {
  let render, defaultProps, groupDetailDefaultProps

  beforeEach(() => {
    const setup = setupTest()
    render = setup.render
    defaultProps = setup.defaultProps
    groupDetailDefaultProps = setup.groupDetailDefaultProps
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  afterAll(() => {
    window.ENV = null
  })

  describe('With manage_outcomes permission / canManage true', () => {
    it('displays outcome kebab menues', async () => {
      const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
      })
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithPending(getByText('Course folder 0'))
      expect(getByText('Menu for outcome Outcome 1 - Course folder 0')).toBeInTheDocument()
      expect(getByText('Menu for outcome Outcome 2 - Course folder 0')).toBeInTheDocument()
    })

    it('displays outcome checkboxes', async () => {
      const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
      })
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithPending(getByText('Course folder 0'))
      expect(getByText('Select outcome Outcome 1 - Course folder 0')).toBeInTheDocument()
      expect(getByText('Select outcome Outcome 2 - Course folder 0')).toBeInTheDocument()
    })
  })

  describe('Without manage_outcomes permission / canManage false', () => {
    it('hides outcome kebab menues', async () => {
      const {getByText, queryByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
        canManage: false,
      })
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithPending(getByText('Course folder 0'))
      expect(queryByText('Menu for outcome Outcome 1 - Course folder 0')).not.toBeInTheDocument()
      expect(queryByText('Menu for outcome Outcome 2 - Course folder 0')).not.toBeInTheDocument()
    })

    it('hides outcome checkboxes', async () => {
      const {getByText, queryByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
        canManage: false,
      })
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithPending(getByText('Course folder 0'))
      expect(queryByText('Select outcome Outcome 1 - Course folder 0')).not.toBeInTheDocument()
      expect(queryByText('Select outcome Outcome 2 - Course folder 0')).not.toBeInTheDocument()
    })

    it('hides ManageOutcomesFooter', async () => {
      const {queryByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
        canManage: false,
      })
      expect(queryByTestId('manage-outcomes-footer')).not.toBeInTheDocument()
    })
  })
})
