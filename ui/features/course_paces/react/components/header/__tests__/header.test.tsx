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

import {waitFor} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {renderConnected} from '../../../__tests__/utils'
import {
  PRIMARY_PACE,
  HEADING_STATS_API_RESPONSE,
  DEFAULT_STORE_STATE,
  COURSE_PACE_CONTEXT,
} from '../../../__tests__/fixtures'
import ConnectedHeader, {Header, type HeaderProps} from '../header'
import type {CoursePace} from '../../../types'
import fakeENV from '@canvas/test-utils/fakeENV'

const defaultProps: HeaderProps = {
  context_type: 'Course',
  context_id: '17',
  newPace: false,
  responsiveSize: 'large',
  coursePace: PRIMARY_PACE,
  defaultPaceContext: COURSE_PACE_CONTEXT,
  blueprintLocked: false,
  isDraftPace: false,
  isSyncing: false,
  fetchDefaultPaceContext: jest.fn(),
  setDefaultPaceContextAsSelected: jest.fn(),
  setSelectedPaceContext: jest.fn(),
  syncUnpublishedChanges: jest.fn(),
}

const server = setupServer()

describe('Course paces header', () => {
  beforeAll(() => {
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.resetAllMocks()
    server.resetHandlers()
  })

  describe('new paces alert', () => {
    it('does not render publishing changes for student paces', () => {
      const {queryByText} = renderConnected(<Header {...defaultProps} context_type="Enrollment" />)
      expect(queryByText('No pending changes')).not.toBeInTheDocument()
    })
  })

  describe('with course paces redesign ON', () => {
    beforeEach(() => {
      fakeENV.setup({
        COURSE_ID: '30',
      })

      // Setup the fetch mock with proper headers
      server.use(
        http.get('*', () => {
          return HttpResponse.json(HEADING_STATS_API_RESPONSE, {
            headers: {
              'Content-Type': 'application/json',
              Link: '',
            },
          })
        }),
      )
    })

    it('renders metrics as table', async () => {
      const {getByRole, getByTestId} = renderConnected(<ConnectedHeader {...defaultProps} />)

      await waitFor(
        () => {
          expect(getByRole('columnheader', {name: 'Students'})).toBeInTheDocument()
          expect(getByRole('columnheader', {name: 'Sections'})).toBeInTheDocument()
          expect(getByTestId('duration-col-header')).toBeInTheDocument()
        },
        {
          timeout: 2000,
        },
      )

      await waitFor(
        () => {
          expect(getByTestId('number-of-students')).toBeInTheDocument()
          expect(getByTestId('number-of-sections')).toBeInTheDocument()
          expect(getByTestId('default-pace-duration')).toBeInTheDocument()
        },
        {
          timeout: 2000,
        },
      )
    })

    it('renders the data pulled from the context api', async () => {
      const {getByTestId} = renderConnected(<ConnectedHeader {...defaultProps} />)

      await waitFor(
        () => {
          const studentsElement = getByTestId('number-of-students')
          const sectionsElement = getByTestId('number-of-sections')
          const durationElement = getByTestId('default-pace-duration')

          expect(studentsElement).toBeInTheDocument()
          expect(sectionsElement).toBeInTheDocument()
          expect(durationElement).toBeInTheDocument()
        },
        {
          timeout: 2000,
        },
      )
    })

    it('renders the proper button for preexisting pace', async () => {
      const {getByRole} = renderConnected(<ConnectedHeader {...defaultProps} />)

      await waitFor(
        () => {
          const editButton = getByRole('button', {name: 'Edit Default Course Pace'})
          expect(editButton).toBeInTheDocument()
        },
        {
          timeout: 2000,
        },
      )
    })

    it('renders the proper button for empty state', async () => {
      const coursePace = {
        ...DEFAULT_STORE_STATE.coursePace,
        id: undefined,
        context_type: 'Course',
      } as CoursePace
      const state = {...DEFAULT_STORE_STATE, coursePace}

      const {getByRole} = renderConnected(<ConnectedHeader {...defaultProps} />, state)

      await waitFor(
        () => {
          const createButton = getByRole('button', {name: 'Create Course Pace'})
          expect(createButton).toBeInTheDocument()
        },
        {
          timeout: 2000,
        },
      )
    })

    it('renders an info tooltip for durations stat', async () => {
      const {getByRole} = renderConnected(<ConnectedHeader {...defaultProps} />)

      await waitFor(
        () => {
          const tooltip = getByRole('tooltip', {
            name: 'This duration does not take into account weekends and blackout days.',
          })
          expect(tooltip).toBeInTheDocument()
        },
        {
          timeout: 2000,
        },
      )
    })
  })
})
