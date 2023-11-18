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
import {waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {renderConnected} from '../../../__tests__/utils'
import {
  PRIMARY_PACE,
  HEADING_STATS_API_RESPONSE,
  DEFAULT_STORE_STATE,
} from '../../../__tests__/fixtures'
import ConnectedHeader, {Header} from '../header'
import {CoursePace} from 'features/course_paces/react/types'
import {enableFetchMocks} from 'jest-fetch-mock'

enableFetchMocks()

const defaultProps = {
  context_type: 'Course',
  context_id: '17',
  newPace: false,
}

describe('Course paces header', () => {
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
          'This is a new course pace and all changes are unpublished. Publish to save any changes and create the pace.'
        )
      ).toBeInTheDocument()
    })

    it('renders an alert for new section paces', () => {
      const {getByText} = renderConnected(
        <Header {...defaultProps} context_type="Section" newPace={true} />
      )
      expect(
        getByText(
          'This is a new section pace and all changes are unpublished. Publish to save any changes and create the pace.'
        )
      ).toBeInTheDocument()
    })

    it('renders an alert for new student paces', () => {
      const {getByText} = renderConnected(
        <Header {...defaultProps} context_type="Enrollment" newPace={true} />
      )
      expect(
        getByText(
          'This is a new student pace and all changes are unpublished. Publish to save any changes and create the pace.'
        )
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
  // the other messsages are tested with UnpublishedChangesIndicator

  describe('with course paces for students', () => {
    beforeAll(() => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_for_students = true
    })

    it('does render publishing changes for student paces', () => {
      const {queryByText} = renderConnected(<Header {...defaultProps} context_type="Enrollment" />)
      expect(queryByText('All changes published')).toBeInTheDocument()
    })
  })

  describe('with course paces redesign ON', () => {
    beforeAll(() => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_redesign = true
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('renders metrics as table', async () => {
      window.ENV.COURSE_ID = 30
      const {getByRole, getByTestId} = renderConnected(
        <ConnectedHeader {...defaultProps} coursePace={PRIMARY_PACE} />
      )
      await waitFor(() => {
        expect(getByRole('columnheader', {name: 'Students'})).toBeInTheDocument()
        expect(getByRole('columnheader', {name: 'Sections'})).toBeInTheDocument()
        expect(getByTestId('duration-col-header')).toBeInTheDocument()
      })
    })

    it('renders the data pulled from the context api', async () => {
      window.ENV.COURSE_ID = 30
      fetchMock.mock(
        '/api/v1/courses/30/pace_contexts?type=course',
        JSON.stringify(HEADING_STATS_API_RESPONSE)
      )
      const {getByRole, getByTestId} = renderConnected(
        <ConnectedHeader {...defaultProps} coursePace={PRIMARY_PACE} />
      )

      await waitFor(() => {
        expect(getByRole('heading', {name: 'Defense Against the Dark Arts'})).toBeInTheDocument()
        expect(getByTestId('number-of-students').textContent).toEqual('30')
        expect(getByTestId('number-of-sections').textContent).toEqual('3')
        expect(getByTestId('default-pace-duration').textContent).toEqual('9 weeks, 2 days')
      })
    })

    it('renders the proper button for preexisting pace', () => {
      const {getByRole} = renderConnected(<ConnectedHeader {...defaultProps} />)
      const getStartedButton = getByRole('button', {name: 'Edit Default Course Pace'})
      expect(getStartedButton).toBeInTheDocument()
    })

    it('renders the proper button for empty state', () => {
      const coursePace = {
        ...DEFAULT_STORE_STATE.coursePace,
        id: undefined,
        context_type: 'Course',
      } as CoursePace
      const state = {...DEFAULT_STORE_STATE, coursePace}
      const {getByRole} = renderConnected(<ConnectedHeader {...defaultProps} />, state)
      const getStartedButton = getByRole('button', {name: 'Create Course Pace'})
      expect(getStartedButton).toBeInTheDocument()
    })

    it('renders an info tooltip for durations stat', () => {
      const {getAllByRole} = renderConnected(
        <ConnectedHeader {...defaultProps} coursePace={PRIMARY_PACE} />
      )
      expect(
        getAllByRole('tooltip', {
          name: 'This duration does not take into account weekends and blackout days.',
        })[0]
      ).toBeInTheDocument()
    })
  })
})
