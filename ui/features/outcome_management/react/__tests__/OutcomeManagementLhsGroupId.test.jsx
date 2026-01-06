/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

// This test is extracted from OutcomeManagement.test.jsx to isolate the slow test
// that was timing out in CI due to complex GraphQL mocks and modal interactions.

import React from 'react'
import {render, fireEvent, act, within} from '@testing-library/react'
import {MockedProvider} from '@apollo/client/testing'
import {OutcomeManagementWithoutGraphql as OutcomeManagement} from '../OutcomeManagement'
import {createCache} from '@canvas/apollo-v3'
import {courseMocks, groupDetailMocks, groupMocks} from '@canvas/outcomes/mocks/Management'

vi.mock('@canvas/outcomes/react/OutcomesImporter', () => ({
  showOutcomesImporter: vi.fn(() => vi.fn(() => {})),
  showOutcomesImporterIfInProgress: vi.fn(() => vi.fn(() => {})),
}))

vi.mock('@canvas/util/globalUtils', async () => ({
  ...(await vi.importActual('@canvas/util/globalUtils')),
  windowConfirm: vi.fn(() => true),
}))

describe('OutcomeManagement - LHS Group Selection', () => {
  let cache

  beforeEach(() => {
    cache = createCache()
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.clearAllMocks()
    vi.useRealTimers()
    window.ENV = null
  })

  // OUT-6972 (10/23/2024) - Extracted to own file for CI stability
  it('renders ManagementHeader with lhsGroupId if selected a group in lhs', async () => {
    const rceEnv = {
      RICH_CONTENT_CAN_UPLOAD_FILES: true,
      RICH_CONTENT_APP_HOST: 'rce-host',
      JWT: 'test-jwt',
      current_user_id: '1',
    }
    window.ENV = {
      context_asset_string: 'course_2',
      CONTEXT_URL_ROOT: '/course/2',
      IMPROVED_OUTCOMES_MANAGEMENT: true,
      PERMISSIONS: {
        manage_proficiency_calculations: true,
        manage_outcomes: true,
      },
      current_user: {id: '1'},
      ...rceEnv,
    }
    const mocks = [
      ...courseMocks({childGroupsCount: 2}),
      ...groupMocks({
        title: 'Course folder 0',
        groupId: '200',
        parentOutcomeGroupTitle: 'Root course folder',
        parentOutcomeGroupId: '2',
      }),
      ...groupDetailMocks({
        title: 'Course folder 0',
        groupId: '200',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false,
      }),
      ...groupMocks({
        groupId: '300',
        childGroupOffset: 400,
        parentOutcomeGroupTitle: 'Course folder 0',
        parentOutcomeGroupId: '200',
      }),
      ...groupDetailMocks({
        groupId: '300',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false,
      }),
    ]
    const {findByText, findByTestId, getByTestId} = render(
      <MockedProvider cache={cache} mocks={mocks}>
        <OutcomeManagement breakpoints={{tablet: true}} />
      </MockedProvider>,
    )
    await act(async () => vi.runAllTimers())

    // Select a group in the lsh
    const cf0 = await findByText('Course folder 0')
    fireEvent.click(cf0)
    await act(async () => vi.runAllTimers())

    // The easy way to determine if lsh is passing to ManagementHeader is
    // to open the create outcome modal and check if the lhs group was loaded
    // by checking if the child of the lhs group is there
    fireEvent.click(within(getByTestId('managementHeader')).getByText('Create'))
    await act(async () => vi.runAllTimers())
    // there's something weird going on in the test here that while we find the modal
    // .toBeInTheDocument() fails, even though a findBy for it fails before ^that click.
    // We can test that the elements expected to be within it exist.
    const modal = await findByTestId('createOutcomeModal')
    expect(within(modal).getByText('Course folder 0')).not.toBeNull()
    expect(within(modal).getByText('Group 200 folder 0')).not.toBeNull()
  })
})
