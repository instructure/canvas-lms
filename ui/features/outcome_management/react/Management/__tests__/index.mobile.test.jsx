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
import {setupTest, teardownTest, accountMocks} from './testSetup'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))
vi.mock('@canvas/rce/RichContentEditor')
vi.mock('axios')
vi.useFakeTimers()

// FOO-3827
describe('OutcomeManagementPanel - Mobile', () => {
  let render, defaultProps, groupDetailDefaultProps

  beforeEach(() => {
    const setup = setupTest({isMobileView: true})
    render = setup.render
    defaultProps = setup.defaultProps
    groupDetailDefaultProps = setup.groupDetailDefaultProps
  })

  afterEach(() => {
    vi.clearAllMocks()
    teardownTest()
  })

  const clickWithinMobileSelect = async selectNode => {
    fireEvent.click(selectNode)
    await act(async () => vi.runOnlyPendingTimers())
  }

  it('renders the action drilldown', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: accountMocks({childGroupsCount: 2}),
    })
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Groups')).toBeInTheDocument()
  })

  it('renders the groups within the drilldown', async () => {
    const {getByText, queryByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: accountMocks({childGroupsCount: 2}),
    })
    await act(async () => vi.runOnlyPendingTimers())
    await clickWithinMobileSelect(queryByText('Groups'))
    expect(getByText('Account folder 0')).toBeInTheDocument()
    expect(getByText('Account folder 1')).toBeInTheDocument()
  })

  it('renders the action link for the root group', async () => {
    const {getByText, queryByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: accountMocks({childGroupsCount: 2}),
    })
    await act(async () => vi.runOnlyPendingTimers())
    await clickWithinMobileSelect(queryByText('Groups'))
    expect(getByText('View 0 Outcomes')).toBeInTheDocument()
  })

  it('loads group detail data correctly', async () => {
    const {getByText, queryByText, getAllByText} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    await clickWithinMobileSelect(queryByText('Groups'))
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    await clickWithinMobileSelect(queryByText('View 2 Outcomes'))
    expect(getByText('All Course folder 0 Outcomes')).toBeInTheDocument()
    expect(getAllByText('Outcome 1 - Course folder 0')).toHaveLength(2)
    expect(getAllByText('Outcome 2 - Course folder 0')).toHaveLength(2)
  })

  it('focuses on the Select input after the group header is clicked', async () => {
    const {getByText, queryByText, getByPlaceholderText} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    await clickWithinMobileSelect(queryByText('Groups'))
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    await clickWithinMobileSelect(queryByText('View 2 Outcomes'))
    fireEvent.click(getByText('Select another group'))
    expect(getByPlaceholderText('Select an outcome group')).toHaveFocus()
  })
})
