// @ts-nocheck
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
import {App} from '../app'
import {enableFetchMocks} from 'jest-fetch-mock'

enableFetchMocks()

const pollForPublishStatus = jest.fn()
const setBlueprintLocked = jest.fn()
const setResponsiveSize = jest.fn()

const defaultProps = {
  loadingMessage: '',
  pollForPublishStatus,
  setBlueprintLocked,
  responsiveSize: 'large' as const,
  setResponsiveSize,
  showLoadingOverlay: false,
  unpublishedChanges: [],
}

beforeAll(() => {
  window.ENV.VALID_DATE_RANGE = {
    end_at: {date: '2021-09-30', date_context: 'course'},
    start_at: {date: '2021-09-01', date_context: 'course'},
  }
})

afterEach(() => {
  jest.clearAllMocks()
})

describe('App', () => {
  it('starts polling for published status updates on mount', () => {
    renderConnected(<App {...defaultProps} coursePace={PRIMARY_PACE} />)
    expect(pollForPublishStatus).toHaveBeenCalled()
  })

  it('renders one screenreader-only h1', () => {
    const {getByRole} = renderConnected(<App {...defaultProps} coursePace={PRIMARY_PACE} />)
    // should only be one h1 in the whole app
    const heading = getByRole('heading', {level: 1})
    expect(heading).toBeInTheDocument()
    expect(heading).toHaveTextContent('Course Pacing')
  })

  describe('with course paces redesign ON', () => {
    beforeAll(() => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_redesign = true
    })

    it('renders empty state if supplied shell course pace', () => {
      const {getByRole} = renderConnected(
        <App {...defaultProps} coursePace={{id: undefined, context_type: 'Course'}} />
      )
      const getStartedButton = getByRole('button', {name: 'Get Started'})
      expect(getStartedButton).toBeInTheDocument()
    })
  })
})
