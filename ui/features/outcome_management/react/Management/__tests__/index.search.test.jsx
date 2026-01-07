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

import {act, fireEvent, waitFor} from '@testing-library/react'
import OutcomeManagementPanel from '../index'
import {
  setupTest,
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
describe('OutcomeManagementPanel - Search', () => {
  let render, defaultProps, groupDetailDefaultProps, defaultMocks

  beforeEach(() => {
    const setup = setupTest()
    render = setup.render
    defaultProps = setup.defaultProps
    groupDetailDefaultProps = setup.groupDetailDefaultProps
    defaultMocks = setup.defaultMocks
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  afterAll(() => {
    window.ENV = null
  })

  it('should not disable search input and clear search button (X) if there are no results', async () => {
    const {getByText, getByLabelText, queryByTestId} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
        mocks: [
          ...defaultMocks,
          groupDetailMocks({
            title: 'Course folder 0',
            groupId: '200',
            contextType: 'Course',
            contextId: '2',
            searchQuery: 'no matched results',
            withMorePage: false,
          })[6],
        ],
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    await waitFor(() => expect(getByText('2 Outcomes')).toBeInTheDocument())
    fireEvent.change(getByLabelText('Search field'), {target: {value: 'no matched results'}})
    await act(async () => vi.advanceTimersByTime(500))
    await waitFor(() => expect(getByLabelText('Search field')).toBeEnabled())
    await waitFor(() => expect(queryByTestId('clear-search-icon')).toBeInTheDocument())
  })

  it('debounces search string typed by user', async () => {
    const {getByText, getByLabelText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
      mocks: [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({
          title: 'Course folder 0',
          groupId: '200',
          parentOutcomeGroupTitle: 'Root course folder',
          parentOutcomeGroupId: '2',
        }),
        groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 1',
          withMorePage: false,
        })[3],
        groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 1',
          withMorePage: false,
        })[5],
      ],
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('All Course folder 0 Outcomes')).toBeInTheDocument()

    const searchInput = getByLabelText('Search field')
    fireEvent.change(searchInput, {target: {value: 'Outcom'}})
    await act(async () => vi.advanceTimersByTime(200))
    expect(getByText('2 Outcomes')).toBeInTheDocument()

    fireEvent.change(searchInput, {target: {value: 'Outcome '}})
    await act(async () => vi.advanceTimersByTime(200))
    expect(getByText('2 Outcomes')).toBeInTheDocument()

    fireEvent.change(searchInput, {target: {value: 'Outcome 1'}})
    await act(async () => vi.advanceTimersByTime(500))
    await waitFor(() => expect(getByText('1 Outcome')).toBeInTheDocument())
  })

  describe('Search input', () => {
    let searchInputMocks

    beforeEach(() => {
      searchInputMocks = [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({groupId: '200'}),
        groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 1',
          withMorePage: false,
        })[3],
        groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 1',
          withMorePage: false,
        })[5],
        ...groupMocks({groupId: '201', childGroupOffset: 400}),
        groupDetailMocks({
          title: 'Course folder 1',
          groupId: '201',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 2',
          withMorePage: false,
        })[3],
        groupDetailMocks({
          title: 'Course folder 1',
          groupId: '201',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 2',
          withMorePage: false,
        })[5],
      ]
    })

    it('should not clear search input if same group is selected/toggled', async () => {
      const {getByText, getByLabelText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
        mocks: searchInputMocks,
      })
      await act(async () => vi.runOnlyPendingTimers())
      const courseFolder = getByText('Course folder 0')
      fireEvent.click(courseFolder)
      await act(async () => vi.advanceTimersByTime(500))
      expect(getByText('2 Outcomes')).toBeInTheDocument()
      fireEvent.change(getByLabelText('Search field'), {target: {value: 'Outcome 1'}})
      await act(async () => vi.runOnlyPendingTimers())
      await act(async () => vi.advanceTimersByTime(500))
      expect(getByText('1 Outcome')).toBeInTheDocument()
      fireEvent.click(courseFolder)
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('1 Outcome')).toBeInTheDocument()
      expect(getByLabelText('Search field')).toHaveValue('Outcome 1')
    })

    it('should clear search input if different group is selected', async () => {
      const {getByText, getByLabelText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
        mocks: searchInputMocks,
      })
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.advanceTimersByTime(500))
      expect(getByText('2 Outcomes')).toBeInTheDocument()
      fireEvent.change(getByLabelText('Search field'), {target: {value: 'Outcome 1'}})
      await act(async () => vi.runOnlyPendingTimers())
      await act(async () => vi.advanceTimersByTime(500))
      expect(getByText('1 Outcome')).toBeInTheDocument()
      fireEvent.click(getByText('Course folder 1'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('2 Outcomes')).toBeInTheDocument()
      expect(getByLabelText('Search field')).toHaveValue('')
    })
  })
})
