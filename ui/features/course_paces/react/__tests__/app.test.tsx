/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React from 'react'
import {renderConnected} from './utils'
import {PRIMARY_PACE} from './fixtures'
import {App, type ResponsiveComponentProps} from '../app'
import fetchMock from 'fetch-mock'
import fakeENV from '@canvas/test-utils/fakeENV'

const pollForPublishStatus = jest.fn()
const setBlueprintLocked = jest.fn()
const setResponsiveSize = jest.fn()

const defaultProps: ResponsiveComponentProps = {
  loadingMessage: '',
  pollForPublishStatus,
  setBlueprintLocked,
  responsiveSize: 'large' as const,
  setResponsiveSize,
  showLoadingOverlay: false,
  unpublishedChanges: [],
  modalOpen: false,
  coursePace: PRIMARY_PACE,
  hidePaceModal: jest.fn(),
}

beforeEach(() => {
  fakeENV.setup({
    VALID_DATE_RANGE: {
      end_at: {date: '2021-09-30', date_context: 'course'},
      start_at: {date: '2021-09-01', date_context: 'course'},
    },
  })
})

afterEach(() => {
  jest.clearAllMocks()
  fakeENV.teardown()
  fetchMock.reset()
})

describe('App', () => {
  it('renders empty state if supplied shell course pace', () => {
    fetchMock.get(/\/api\/v1\/courses\/30\/pace_contexts.*/, {})
    const {getByRole} = renderConnected(
      <App
        {...defaultProps}
        coursePace={{
          ...PRIMARY_PACE,
          id: undefined,
          context_type: 'Course',
          context_id: '1',
          workflow_state: 'active',
        }}
      />,
    )
    const getStartedButton = getByRole('button', {name: 'Get Started'})
    expect(getStartedButton).toBeInTheDocument()
  })
})
