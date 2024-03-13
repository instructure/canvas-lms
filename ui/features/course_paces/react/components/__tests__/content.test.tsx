// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {act, fireEvent, within} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {renderConnected} from '../../__tests__/utils'
import {
  COURSE,
  PACE_CONTEXTS_SECTIONS_RESPONSE,
  PACE_CONTEXTS_STUDENTS_RESPONSE,
  PACE_CONTEXTS_SECTIONS_SEARCH_RESPONSE,
  DEFAULT_STORE_STATE,
} from '../../__tests__/fixtures'
import PaceContent from '../content'
import fetchMock from 'fetch-mock'
import {actions as uiActions} from '../../actions/ui'
import {APIPaceContextTypes, Pace, PaceContextsState} from '../../types'
import * as tz from '@canvas/datetime'

jest.mock('../../actions/ui', () => ({
  ...jest.requireActual('../../actions/ui'),
  actions: {
    setSelectedPaceContext: jest
      .fn()
      .mockReturnValue({type: 'UI/SET_SELECTED_PACE_CONTEXT', payload: {newSelectedPace: {}}}),
    hideLoadingOverlay: jest.fn().mockReturnValue({type: 'UI/HIDE_LOADING_OVERLAY', payload: {}}),
    setCategoryError: jest
      .fn()
      .mockReturnValue({type: 'UI/SET_CATEGORY_ERROR', payload: {category: '', error: ''}}),
  },
}))

const firstSection = PACE_CONTEXTS_SECTIONS_RESPONSE.pace_contexts[0]
const secondSection = PACE_CONTEXTS_SECTIONS_RESPONSE.pace_contexts[1]
const firstStudent = PACE_CONTEXTS_STUDENTS_RESPONSE.pace_contexts[0]

const SECTION_CONTEXTS_API = `/api/v1/courses/${COURSE.id}/pace_contexts?type=section&page=1&per_page=10&sort=name&order=asc`
const STUDENT_CONTEXTS_API = `/api/v1/courses/${COURSE.id}/pace_contexts?type=student_enrollment&page=1&per_page=10&sort=name&order=asc`
const SECTION_PACE_CREATION_API = `/api/v1/courses/${COURSE.id}/course_pacing/new?course_section_id=${firstSection.item_id}`
const SEARCH_SECTION_CONTEXTS_API = `/api/v1/courses/${COURSE.id}/pace_contexts?type=section&page=1&per_page=10&search_term=A&sort=name&order=asc`
const STUDENT_CONTEXTS_API_WITH_DESC_SORTING = `/api/v1/courses/${COURSE.id}/pace_contexts?type=student_enrollment&page=1&per_page=10&sort=name&order=desc`
const INIT_PACE_PROGRESS_STATUS_POLL = `/api/v1/courses/${COURSE.id}/course_pacing/new?enrollment_id=${firstStudent.item_id}`
const INIT_SECTION_PACE_PROGRESS_STATUS_POLL = `/api/v1/courses/${COURSE.id}/course_pacing/new?course_section_id=${secondSection.item_id}`

const MINUTE = 1000 * 60
const HOUR = MINUTE * 60
const DAY = HOUR * 24
const WEEK = DAY * 7

const generateModifiedPace = timeAgo => {
  const lastModified = new Date(Date.now() - timeAgo)
  const appliedPace: Pace = {
    ...firstSection.applied_pace!,
    last_modified: lastModified.toLocaleString(),
  }
  const sectionContext = {...firstSection}
  sectionContext.applied_pace = appliedPace
  return sectionContext
}

describe('PaceContextsContent', () => {
  beforeAll(() => {
    jest.useFakeTimers()
  })

  beforeEach(() => {
    fetchMock.get(SECTION_CONTEXTS_API, JSON.stringify(PACE_CONTEXTS_SECTIONS_RESPONSE))
    fetchMock.get(STUDENT_CONTEXTS_API, JSON.stringify(PACE_CONTEXTS_STUDENTS_RESPONSE))
    fetchMock.get(
      SEARCH_SECTION_CONTEXTS_API,
      JSON.stringify(PACE_CONTEXTS_SECTIONS_SEARCH_RESPONSE)
    )
    fetchMock.get(SECTION_PACE_CREATION_API, JSON.stringify({course_pace: {}, progress: null}))
    jest.clearAllMocks()
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('shows section contexts by default', async () => {
    const {findByText} = renderConnected(<PaceContent />)
    expect(
      await findByText(PACE_CONTEXTS_SECTIONS_RESPONSE.pace_contexts[0].name)
    ).toBeInTheDocument()
    expect(
      await findByText(PACE_CONTEXTS_SECTIONS_RESPONSE.pace_contexts[1].name)
    ).toBeInTheDocument()
  })

  it('sets the selected tab based on the selected pace context', async () => {
    const paceContextsState: PaceContextsState = {
      ...DEFAULT_STORE_STATE.paceContexts,
      selectedContextType: 'student_enrollment' as APIPaceContextTypes,
    }
    const state = {...DEFAULT_STORE_STATE, paceContexts: paceContextsState}
    const {findByText} = renderConnected(<PaceContent />, state)
    expect(await findByText(firstStudent.name)).toBeInTheDocument()
  })

  it('fetches student contexts when clicking the Students tab', async () => {
    const user = userEvent.setup({delay: null})
    const {findByText, getByRole} = renderConnected(<PaceContent />)
    const studentsTab = getByRole('tab', {name: 'Students'})
    await user.click(studentsTab)
    expect(await findByText(firstStudent.name)).toBeInTheDocument()
    expect(
      await findByText(PACE_CONTEXTS_STUDENTS_RESPONSE.pace_contexts[1].name)
    ).toBeInTheDocument()
  })

  describe('Pace contexts table', () => {
    it('shows custom data for sections', async () => {
      const headers = ['Section', 'Section Size', 'Pace Type', 'Last Modified']
      const sectionPaceContext = PACE_CONTEXTS_SECTIONS_RESPONSE.pace_contexts[0]
      const {findByText, getByText, getAllByText} = renderConnected(<PaceContent />)
      expect(await findByText(sectionPaceContext.name)).toBeInTheDocument()
      headers.forEach(header => {
        expect(getAllByText(header)[0]).toBeInTheDocument()
      })
      expect(
        getByText(`${sectionPaceContext.associated_student_count} Students`)
      ).toBeInTheDocument()
      expect(getAllByText('Section')[0]).toBeInTheDocument()
    })

    it('shows custom data for students', async () => {
      const user = userEvent.setup({delay: null})
      const headers = ['Student', 'Assigned Pace', 'Pace Type', 'Last Modified']
      const studentPaceContext = firstStudent
      const {findByText, getByText, getByRole, getAllByText} = renderConnected(<PaceContent />)
      const studentsTab = getByRole('tab', {name: 'Students'})
      await user.click(studentsTab)
      expect(await findByText(studentPaceContext.name)).toBeInTheDocument()
      headers.forEach(header => {
        expect(getAllByText(header)[0]).toBeInTheDocument()
      })
      expect(getByText('J-M')).toBeInTheDocument()
      expect(getAllByText('Individual')[0]).toBeInTheDocument()
    })

    it('filters results by search term', async () => {
      const {findByText, queryByText, getByRole, getByPlaceholderText, getByText} = renderConnected(
        <PaceContent />
      )
      const searchInput = getByPlaceholderText('Search for sections')
      const searchButton = getByRole('button', {name: 'Search'})
      fireEvent.change(searchInput, {target: {value: 'A'}})
      act(() => {
        searchButton.click()
      })

      expect(await findByText('A-C')).toBeInTheDocument()
      expect(queryByText('D-F')).not.toBeInTheDocument()
      expect(queryByText('G-K')).not.toBeInTheDocument()
      expect(queryByText('No results found')).not.toBeInTheDocument()
      expect(getByText('Showing 1 result below')).toBeInTheDocument()
    })

    it("shows no results if there's no contexts for the search", async () => {
      fetchMock.get(
        SEARCH_SECTION_CONTEXTS_API,
        JSON.stringify({pace_contexts: [], total_entries: 0}),
        {overwriteRoutes: true}
      )
      const {findAllByText, getByText, getByPlaceholderText} = renderConnected(<PaceContent />)
      const searchInput = getByPlaceholderText('Search for sections')
      const searchButton = getByText('Search', {selector: 'button span'})
      fireEvent.change(searchInput, {target: {value: 'A'}})
      act(() => searchButton.click())
      const noResults = await findAllByText('No results found')
      expect(noResults.length).toBe(2) // no results label, SR-only alert
      expect(getByText('Please try another search term')).toBeInTheDocument()
    })

    it('provides contextType and contextId to Pace modal', async () => {
      const {findByRole} = renderConnected(<PaceContent />)
      const sectionLink = await findByRole('button', {name: firstSection.name})
      act(() => sectionLink.click())
      expect(uiActions.setSelectedPaceContext).toHaveBeenCalledWith('Section', firstSection.item_id)
    })

    describe('Last Modified column', () => {
      it('displays just now if the last modification was 5 minutes ago or less', async () => {
        const justModifiedPace = generateModifiedPace(MINUTE)
        fetchMock.get(SECTION_CONTEXTS_API, JSON.stringify({pace_contexts: [justModifiedPace]}), {
          overwriteRoutes: true,
        })

        const {findByText} = renderConnected(<PaceContent />)
        expect(await findByText('Just Now')).toBeInTheDocument()
      })

      it('displays the number of minutes if the last modification was between 5 and 59 mins ago', async () => {
        const modifiedPace = generateModifiedPace(7 * MINUTE)
        fetchMock.get(SECTION_CONTEXTS_API, JSON.stringify({pace_contexts: [modifiedPace]}), {
          overwriteRoutes: true,
        })

        const {findByText} = renderConnected(<PaceContent />)
        expect(await findByText('7 minutes ago')).toBeInTheDocument()
      })

      it('displays the number of hours if the last modification was between 1 and 24 hours ago', async () => {
        const modifiedPace = generateModifiedPace(3 * HOUR)
        fetchMock.get(SECTION_CONTEXTS_API, JSON.stringify({pace_contexts: [modifiedPace]}), {
          overwriteRoutes: true,
        })

        const {findByText} = renderConnected(<PaceContent />)
        expect(await findByText('3 hours ago')).toBeInTheDocument()
      })

      it('displays the number of days if the last modification was between 1 and 7 days ago', async () => {
        const modifiedPace = generateModifiedPace(4 * DAY)
        fetchMock.get(SECTION_CONTEXTS_API, JSON.stringify({pace_contexts: [modifiedPace]}), {
          overwriteRoutes: true,
        })

        const {findByText} = renderConnected(<PaceContent />)
        expect(await findByText('4 days ago')).toBeInTheDocument()
      })

      it('displays the number of weeks if the last modification was between 1 and 4 weeks ago', async () => {
        const modifiedPace = generateModifiedPace(WEEK)
        fetchMock.get(SECTION_CONTEXTS_API, JSON.stringify({pace_contexts: [modifiedPace]}), {
          overwriteRoutes: true,
        })

        const {findByText} = renderConnected(<PaceContent />)
        expect(await findByText('1 week ago')).toBeInTheDocument()
      })

      it('displays the date if the last modification was more than 4 weeks ago', async () => {
        const timeAgo = 5 * WEEK
        const modifiedPace = generateModifiedPace(timeAgo)
        const lastModified = new Date(Date.now() - timeAgo)
        const formattedDate = tz.format(lastModified, 'date.formats.long')
        fetchMock.get(SECTION_CONTEXTS_API, JSON.stringify({pace_contexts: [modifiedPace]}), {
          overwriteRoutes: true,
        })

        const {findByText} = renderConnected(<PaceContent />)
        expect(await findByText(formattedDate)).toBeInTheDocument()
      })
    })

    describe('Sortable Column', () => {
      beforeEach(() => {
        fetchMock.get(
          STUDENT_CONTEXTS_API_WITH_DESC_SORTING,
          JSON.stringify(PACE_CONTEXTS_STUDENTS_RESPONSE)
        )
      })

      it('sorts the table in ascending order by default', async () => {
        const {getByRole} = renderConnected(<PaceContent />)
        const studentsTab = getByRole('tab', {name: 'Students'})
        act(() => studentsTab.click())
        expect(fetchMock.lastUrl()).toMatch(STUDENT_CONTEXTS_API)
      })

      it('toggles between ascending and descending order', async () => {
        const user = userEvent.setup({delay: null})
        const {getByRole, findByTestId} = renderConnected(<PaceContent />)
        const studentsTab = getByRole('tab', {name: 'Students'})
        const getSortButton = async () => {
          const sortableHeader = await findByTestId('sortable-column-name')
          return within(sortableHeader).getByRole('button')
        }
        await user.click(studentsTab)
        // ascending order by default
        expect(fetchMock.lastUrl()).toMatch(STUDENT_CONTEXTS_API)
        let sortButton = await getSortButton()
        await user.click(sortButton)
        // toggles to descending order
        expect(fetchMock.lastUrl()).toMatch(STUDENT_CONTEXTS_API_WITH_DESC_SORTING)
        // comes back to ascending order
        sortButton = await getSortButton()
        await user.click(sortButton)
        expect(fetchMock.lastUrl()).toMatch(STUDENT_CONTEXTS_API)
      })
    })

    describe('Paces publishing', () => {
      beforeEach(() => {
        fetchMock.get(
          INIT_PACE_PROGRESS_STATUS_POLL,
          JSON.stringify({course_pace: {}, progress: {id: 1}})
        )
        fetchMock.get(
          INIT_SECTION_PACE_PROGRESS_STATUS_POLL,
          JSON.stringify({course_pace: {}, progress: {id: 2}})
        )
      })

      // passes, but with warning: "Unmatched GET to /api/v1/progress/2"
      // FOO-3818
      it.skip('shows a loading indicator for each pace publishing', async () => {
        const paceContextsState: PaceContextsState = {
          ...DEFAULT_STORE_STATE.paceContexts,
          contextsPublishing: [
            {
              progress_context_id: '1',
              pace_context: firstSection,
              polling: false,
            },
            {
              progress_context_id: '2',
              pace_context: secondSection,
              polling: false,
            },
          ],
        }
        const state = {...DEFAULT_STORE_STATE, paceContexts: paceContextsState}
        const {findByTestId} = renderConnected(<PaceContent />, state)
        expect(
          await findByTestId(`publishing-pace-${firstSection.item_id}-indicator`)
        ).toBeInTheDocument()
        expect(
          await findByTestId(`publishing-pace-${secondSection.item_id}-indicator`)
        ).toBeInTheDocument()
      })

      it('starts polling for published status updates on mount', async () => {
        const user = userEvent.setup({delay: null})
        const paceContextsState: PaceContextsState = {
          ...DEFAULT_STORE_STATE.paceContexts,
          contextsPublishing: [
            {
              progress_context_id: '1',
              pace_context: firstStudent,
              polling: false,
            },
          ],
        }

        const state = {...DEFAULT_STORE_STATE, paceContexts: paceContextsState}
        const {getByRole, findByTestId} = renderConnected(<PaceContent />, state)
        const studentsTab = getByRole('tab', {name: 'Students'})
        await user.click(studentsTab)
        expect(
          await findByTestId(`publishing-pace-${firstStudent.item_id}-indicator`)
        ).toBeInTheDocument()
        expect(fetchMock.called(INIT_PACE_PROGRESS_STATUS_POLL, 'GET')).toBe(true)
      })
    })
  })
})
