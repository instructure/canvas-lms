/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {
  DefaultGradingScheme,
  DefaultUsedLocations,
  secondUsedLocations,
  IntersectionObserver,
} from './fixtures'
import type {GradingSchemeUsedLocationsModalProps} from '../GradingSchemeUsedLocationsModal'
import GradingSchemeUsedLocationsModal from '../GradingSchemeUsedLocationsModal'

jest.mock('@canvas/do-fetch-api-effect')

describe('UsedLocationsModal', () => {
  beforeAll(() => {
    global.IntersectionObserver = IntersectionObserver
  })

  beforeEach(() => {
    doFetchApi.mockImplementation((opts: {path: string; method: string}) => {
      if (
        opts.path ===
        `/accounts/${DefaultGradingScheme.context_id}/grading_schemes/${DefaultGradingScheme.id}/used_locations`
      ) {
        return Promise.resolve({
          response: {ok: true},
          // need a deep copy of the DefaultUsedLocations array to avoid mutating the original
          json: DefaultUsedLocations.map(location => JSON.parse(JSON.stringify(location))),
          link: {next: {url: 'nextPage'}},
        })
      } else if (opts.path === 'nextPage') {
        return Promise.resolve({
          response: {ok: true},
          // need a deep copy of the secondUsedLocations array to avoid mutating the original
          json: secondUsedLocations.map(location => JSON.parse(JSON.stringify(location))),
          link: null,
        })
      }
      return Promise.resolve({response: {ok: false}})
    })
  })

  afterEach(() => {
    doFetchApi.mockClear()
  })
  function renderUsedLocationsModal(props: Partial<GradingSchemeUsedLocationsModalProps> = {}) {
    const handleClose = jest.fn()

    const utils = render(
      <GradingSchemeUsedLocationsModal
        open={true}
        handleClose={handleClose}
        gradingScheme={DefaultGradingScheme}
        {...props}
      />
    )

    return {
      ...utils,
      handleClose,
    }
  }
  it('should render a modal', async () => {
    const {getByTestId} = renderUsedLocationsModal()
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(doFetchApi).toHaveBeenCalled()
    expect(getByTestId('used-locations-modal')).toBeInTheDocument()
  })

  it('should call the handleClose function when the close button is clicked', () => {
    const {getByTestId, handleClose} = renderUsedLocationsModal()
    const closeBtn = getByTestId('used-locations-modal-close-button').children[0]
    fireEvent.click(closeBtn)
    expect(handleClose).toHaveBeenCalled()
  })

  it('should render concluded pill if the course is concluded', async () => {
    const {getByTestId} = renderUsedLocationsModal()
    const concludedCourse = DefaultUsedLocations.find(location => location['concluded?'])
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(getByTestId(`concluded-course-${concludedCourse?.id}-pill`)).toBeInTheDocument()
  })

  describe('2 pages of used locations', () => {
    it('should make 2 calls to the API to load the next page', async () => {
      renderUsedLocationsModal()
      await new Promise(resolve => setTimeout(resolve, 0))
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(doFetchApi).toHaveBeenCalledTimes(2)
    })

    it('should load the second page of used locations', async () => {
      const {getByTestId} = renderUsedLocationsModal()
      await new Promise(resolve => setTimeout(resolve, 0))
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByTestId('used-locations-modal')).toBeInTheDocument()
      expect(
        getByTestId(`used-locations-modal-course-${DefaultUsedLocations[0].id}`)
      ).toBeInTheDocument()
      expect(
        getByTestId(`used-locations-modal-course-${secondUsedLocations[1].id}`)
      ).toBeInTheDocument()
    })

    it('should merge the second page of used locations with the first page if the first location of the second page matches the last location of the first page and not create two bullet points for the same course', async () => {
      const {getAllByTestId, getByTestId} = renderUsedLocationsModal()
      await new Promise(resolve => setTimeout(resolve, 0))
      await new Promise(resolve => setTimeout(resolve, 0))
      // for this test to work, the secondUsedLocations array must have its first course location match the last course location of the DefaultUsedLocations array
      // this simulates the case where a course's assignments are split between two pages from the api
      expect(DefaultUsedLocations[DefaultUsedLocations.length - 1].id).toEqual(
        secondUsedLocations[0].id
      )
      expect(getByTestId('used-locations-modal')).toBeInTheDocument()
      expect(
        getByTestId(`used-locations-modal-course-${secondUsedLocations[0].id}`)
      ).toBeInTheDocument()
      expect(
        getByTestId(`used-locations-modal-assignment-${secondUsedLocations[0].assignments[0].id}`)
      ).toBeInTheDocument()
      expect(
        getAllByTestId(`used-locations-modal-course-${secondUsedLocations[0].id}`)
      ).toHaveLength(1)
    })
  })

  describe('filtering', () => {
    it('should show all assignments if there is no filter', async () => {
      const {getByTestId} = renderUsedLocationsModal()
      await new Promise(resolve => setTimeout(resolve, 0))
      DefaultUsedLocations.forEach(location => {
        expect(getByTestId(`used-locations-modal-course-${location.id}`)).toBeInTheDocument()
        location.assignments.forEach(assignment => {
          expect(
            getByTestId(`used-locations-modal-assignment-${assignment.id}`)
          ).toBeInTheDocument()
        })
      })
    })

    it('should show the course and all its assignments if it matches the query even if the assignment names do not match', async () => {
      const {getByTestId, queryByTestId} = renderUsedLocationsModal()
      await new Promise(resolve => setTimeout(resolve, 0))
      const filterInput = getByTestId('used-locations-modal-search-input')
      fireEvent.change(filterInput, {target: {value: DefaultUsedLocations[0].name}})
      expect(
        getByTestId(`used-locations-modal-course-${DefaultUsedLocations[0].id}`)
      ).toBeInTheDocument()
      DefaultUsedLocations[0].assignments.forEach(assignment => {
        expect(getByTestId(`used-locations-modal-assignment-${assignment.id}`)).toBeInTheDocument()
      })
      expect(
        queryByTestId(`used-locations-modal-course-${DefaultUsedLocations[1].id}`)
      ).not.toBeInTheDocument()
      expect(
        queryByTestId(
          `used-locations-modal-assignment-${DefaultUsedLocations[1].assignments[0].id}`
        )
      ).not.toBeInTheDocument()
    })

    it('should show the course names for all assignments that match the query, even if the course name does not match', async () => {
      const {getByTestId, queryByTestId} = renderUsedLocationsModal()
      await new Promise(resolve => setTimeout(resolve, 0))
      const filterInput = getByTestId('used-locations-modal-search-input')
      fireEvent.change(filterInput, {target: {value: DefaultUsedLocations[0].assignments[0].title}})
      expect(
        getByTestId(`used-locations-modal-course-${DefaultUsedLocations[0].id}`)
      ).toBeInTheDocument()
      expect(
        getByTestId(`used-locations-modal-assignment-${DefaultUsedLocations[0].assignments[0].id}`)
      ).toBeInTheDocument()
      expect(
        queryByTestId(`used-locations-modal-course-${DefaultUsedLocations[1].id}`)
      ).not.toBeInTheDocument()
    })

    it('should show course and assignments if both of them match the query', async () => {
      const {getByTestId, queryByTestId} = renderUsedLocationsModal()
      await new Promise(resolve => setTimeout(resolve, 0))
      const filterInput = getByTestId('used-locations-modal-search-input')
      fireEvent.change(filterInput, {target: {value: 'Same Name'}})
      DefaultUsedLocations.find(location => location.name === 'Same Name')?.assignments.forEach(
        assignment => {
          expect(
            getByTestId(`used-locations-modal-assignment-${assignment.id}`)
          ).toBeInTheDocument()
        }
      )
      const sameNameAssignmentCourse = DefaultUsedLocations.find(
        location => location.name === 'Course with name assignment'
      )
      expect(
        getByTestId(`used-locations-modal-course-${sameNameAssignmentCourse?.id}`)
      ).toBeInTheDocument()
      sameNameAssignmentCourse?.assignments.forEach(assignment => {
        if (assignment.title === 'Same Name') {
          expect(
            getByTestId(`used-locations-modal-assignment-${assignment.id}`)
          ).toBeInTheDocument()
        } else {
          expect(
            queryByTestId(`used-locations-modal-assignment-${assignment.id}`)
          ).not.toBeInTheDocument()
        }
      })
    })
  })
})
