/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {act, screen} from '@testing-library/react'
import OutcomeManagementPanel from '../index'
import {setupTest, teardownTest, groupDetailMocks, courseMocks} from './testSetup'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
}))
jest.mock('@canvas/rce/RichContentEditor')
jest.mock('axios')
jest.useFakeTimers()

describe('OutcomeManagementPanel - URL Query Parameter Processing', () => {
  let render, defaultProps, groupDetailDefaultProps
  let originalLocation

  beforeAll(() => {
    // Save original location
    originalLocation = window.location
  })

  afterAll(() => {
    // Restore original location
    window.location = originalLocation
  })

  beforeEach(() => {
    const setup = setupTest()
    render = setup.render
    defaultProps = setup.defaultProps
    groupDetailDefaultProps = setup.groupDetailDefaultProps
  })

  afterEach(() => {
    jest.clearAllMocks()
    teardownTest()
  })

  const setLocationSearch = search => {
    delete window.location
    window.location = new URL(`http://localhost${search}`)
  }

  it('renders with outcome_id parameter without crashing', async () => {
    setLocationSearch('?outcome_id=1')

    const mocks = [
      ...courseMocks({childGroupsCount: 0}),
      ...groupDetailMocks({
        title: 'Root course folder',
        groupId: '2',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false,
      }),
    ]

    render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
      mocks,
      treeBrowserRootGroupId: '2',
    })

    await act(async () => {
      jest.runAllTimers()
    })

    // Verify component renders
    expect(screen.getByTestId('outcomeManagementPanel')).toBeInTheDocument()
  })

  it('renders with both outcome_id and group_id parameters without crashing', async () => {
    setLocationSearch('?outcome_id=1&group_id=200')

    const mocks = [
      ...courseMocks({childGroupsCount: 2}),
      ...groupDetailMocks({
        title: 'Course folder 0',
        groupId: '200',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false,
      }),
    ]

    render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
      mocks,
      treeBrowserRootGroupId: '2',
    })

    await act(async () => {
      jest.runAllTimers()
    })

    // Verify component renders
    expect(screen.getByTestId('outcomeManagementPanel')).toBeInTheDocument()
  })

  it('renders with multiple query parameters without crashing', async () => {
    setLocationSearch('?foo=bar&outcome_id=1&baz=qux')

    const mocks = [
      ...courseMocks({childGroupsCount: 0}),
      ...groupDetailMocks({
        title: 'Root course folder',
        groupId: '2',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false,
      }),
    ]

    render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
      mocks,
      treeBrowserRootGroupId: '2',
    })

    await act(async () => {
      jest.runAllTimers()
    })

    // Verify component renders
    expect(screen.getByTestId('outcomeManagementPanel')).toBeInTheDocument()
  })

  it('renders without processing empty outcome_id parameter', async () => {
    setLocationSearch('?outcome_id=')

    const mocks = [
      ...courseMocks({childGroupsCount: 0}),
      ...groupDetailMocks({
        title: 'Root course folder',
        groupId: '2',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false,
      }),
    ]

    render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
      mocks,
      treeBrowserRootGroupId: '2',
    })

    await act(async () => {
      jest.runAllTimers()
    })

    // Verify component renders normally
    expect(screen.getByTestId('outcomeManagementPanel')).toBeInTheDocument()
  })

  it('renders with non-existent outcome_id gracefully', async () => {
    setLocationSearch('?outcome_id=99999')

    const mocks = [
      ...courseMocks({childGroupsCount: 0}),
      ...groupDetailMocks({
        title: 'Root course folder',
        groupId: '2',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false,
      }),
    ]

    render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
      mocks,
      treeBrowserRootGroupId: '2',
    })

    await act(async () => {
      jest.runAllTimers()
    })

    // Verify component still renders without errors
    expect(screen.getByTestId('outcomeManagementPanel')).toBeInTheDocument()
  })

  it('renders without query parameters', async () => {
    setLocationSearch('')

    const mocks = [
      ...courseMocks({childGroupsCount: 0}),
      ...groupDetailMocks({
        title: 'Root course folder',
        groupId: '2',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false,
      }),
    ]

    render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
      mocks,
      treeBrowserRootGroupId: '2',
    })

    await act(async () => {
      jest.runAllTimers()
    })

    // Verify component renders normally
    expect(screen.getByTestId('outcomeManagementPanel')).toBeInTheDocument()
  })
})
