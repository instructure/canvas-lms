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
import {waitFor} from '@testing-library/react'
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

describe('Course paces header', () => {
  beforeEach(() => {
    fakeENV.setup()
    // Clear any previous fetch mocks
    global.fetch = jest.fn()
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.resetAllMocks()
  })

  it('renders', () => {
    const {getByRole, getByText} = renderConnected(<Header {...defaultProps} />)
    expect(getByRole('button', {name: 'Course Pacing'})).toBeInTheDocument()
    expect(getByRole('button', {name: 'Modify Settings'})).toBeInTheDocument()
    expect(getByText('All changes published')).toBeInTheDocument()
  })

  describe('new paces alert', () => {
    it('renders an alert for new course paces', () => {
      const {getByText} = renderConnected(<Header {...defaultProps} newPace={true} />)
      expect(
        getByText(
          'This is a new course pace and all changes are unpublished. Publish to save any changes and create the pace.',
        ),
      ).toBeInTheDocument()
    })

    it('renders an alert for new section paces', () => {
      const {getByText} = renderConnected(
        <Header {...defaultProps} context_type="Section" newPace={true} />,
      )
      expect(
        getByText(
          'This is a new section pace and all changes are unpublished. Publish to save any changes and create the pace.',
        ),
      ).toBeInTheDocument()
    })

    it('renders an alert for new student paces', () => {
      const {getByText} = renderConnected(
        <Header {...defaultProps} context_type="Enrollment" newPace={true} />,
      )
      expect(
        getByText(
          'This is a new student pace and all changes are unpublished. Publish to save any changes and create the pace.',
        ),
      ).toBeInTheDocument()
    })

    it('does not render publishing changes for student paces', () => {
      const {queryByText} = renderConnected(<Header {...defaultProps} context_type="Enrollment" />)
      expect(queryByText('All changes published')).not.toBeInTheDocument()
    })
  })

  it('renders the unpublished changes message for a new pace', () => {
    const {getByText} = renderConnected(<Header {...defaultProps} newPace={true} />)
    expect(getByText('Pace is new and unpublished')).toBeInTheDocument()
  })

  describe('with course paces for students', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {
          course_paces_for_students: true,
        },
      })
    })

    it('does render publishing changes for student paces', () => {
      const {queryByText} = renderConnected(<Header {...defaultProps} context_type="Enrollment" />)
      expect(queryByText('All changes published')).toBeInTheDocument()
    })
  })

  describe('with course paces redesign ON', () => {
    const originalFetch = global.fetch

    beforeEach(() => {
      fakeENV.setup({
        COURSE_ID: '30',
        FEATURES: {
          course_paces_redesign: true,
        },
      })

      // Setup the fetch mock with proper headers
      global.fetch = jest.fn(() =>
        Promise.resolve({
          ok: true,
          headers: new Headers({
            'Content-Type': 'application/json',
            Link: '',
          }),
          json: () => Promise.resolve(HEADING_STATS_API_RESPONSE),
          text: () => Promise.resolve(JSON.stringify(HEADING_STATS_API_RESPONSE)),
        }),
      ) as jest.Mock
    })

    afterEach(() => {
      global.fetch = originalFetch
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
