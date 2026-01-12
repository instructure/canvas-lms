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

import {act, fireEvent} from '@testing-library/react'
import OutcomeManagementPanel from '../index'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {
  setupTest,
  teardownTest,
  accountMocks,
  courseMocks,
  groupMocks,
  groupDetailMocks,
} from './testSetup'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))
vi.mock('@canvas/rce/RichContentEditor')
vi.mock('axios')
vi.useFakeTimers()

// FOO-3827
describe('OutcomeManagementPanel - Rendering', () => {
  let render, defaultProps, groupDetailDefaultProps

  beforeEach(() => {
    const setup = setupTest()
    render = setup.render
    defaultProps = setup.defaultProps
    groupDetailDefaultProps = setup.groupDetailDefaultProps
  })

  afterEach(() => {
    vi.clearAllMocks()
    teardownTest()
  })

  it('renders the tree browser for empty root groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: accountMocks({childGroupsCount: 0}),
    })
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Root account folder')).toBeInTheDocument()
  })

  it('loads outcome group data for Account', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: accountMocks({childGroupsCount: 2}),
    })
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
    expect(getByText('Root account folder')).toBeInTheDocument()
    expect(getByText('Account folder 0')).toBeInTheDocument()
    expect(getByText('Account folder 1')).toBeInTheDocument()
  })

  it('loads outcome group data for Course', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      contextType: 'Course',
      contextId: '2',
      mocks: courseMocks({childGroupsCount: 2}),
    })
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
    expect(getByText('Root course folder')).toBeInTheDocument()
    expect(getByText('Course folder 0')).toBeInTheDocument()
    expect(getByText('Course folder 1')).toBeInTheDocument()
  })

  it('loads nested groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: [
        ...accountMocks({childGroupsCount: 2}),
        ...groupMocks({groupId: '100'}),
        ...groupDetailMocks({groupId: '100', contextType: 'Account', contextId: '1'}),
      ],
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Group 100 folder 0')).toBeInTheDocument()
  })

  it('displays a screen reader error and text error on failed request for course outcome groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      contextType: 'Course',
      contextId: '2',
      mocks: [],
    })
    await act(async () => vi.runOnlyPendingTimers())
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'An error occurred while loading course learning outcome groups.',
      srOnly: true,
      type: 'error',
    })
    expect(getByText(/An error occurred while loading course outcomes/)).toBeInTheDocument()
  })

  it('displays a screen reader error and text error on failed request for account outcome groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: [],
    })
    await act(async () => vi.runOnlyPendingTimers())
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'An error occurred while loading account learning outcome groups.',
      srOnly: true,
      type: 'error',
    })
    expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument()
  })

  it('displays a flash alert if a child group fails to load', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: [...accountMocks({childGroupsCount: 2})],
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'An error occurred while loading account learning outcome groups.',
      type: 'error',
      srOnly: false,
    })
  })

  it('loads group detail data correctly', async () => {
    const {getByText, getAllByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Course folder 0 Outcomes')).toBeInTheDocument()
    expect(getAllByText('Outcome 1 - Course folder 0')).toHaveLength(2)
    expect(getAllByText('Outcome 2 - Course folder 0')).toHaveLength(2)
  })

  it('hides the "Outcome Group Menu" for the root group', async () => {
    const {getByText, queryByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Root course folder'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(queryByText('Menu for group Course folder 0')).not.toBeInTheDocument()
  })
})
