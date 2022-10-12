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
import {act} from '@testing-library/react'
import {renderConnected} from '../../__tests__/utils'
import {
  COURSE,
  PACE_CONTEXTS_SECTIONS_RESPONSE,
  PACE_CONTEXTS_STUDENTS_RESPONSE,
} from '../../__tests__/fixtures'
import PaceContent from '../content'
import fetchMock from 'fetch-mock'
import {actions as uiActions} from '../../actions/ui'

jest.mock('../../actions/ui', () => ({
  ...jest.requireActual('../../actions/ui'),
  actions: {
    setSelectedPaceContext: jest
      .fn()
      .mockReturnValue({type: 'UI/SET_SELECTED_PACE_CONTEXT', payload: {newSelectedPace: {}}}),
  },
}))

const firstSection = PACE_CONTEXTS_SECTIONS_RESPONSE.pace_contexts[0]

const SECTION_CONTEXTS_API = `/api/v1/courses/${COURSE.id}/pace_contexts?type=section&page=1&per_page=10`
const STUDENT_CONTEXTS_API = `/api/v1/courses/${COURSE.id}/pace_contexts?type=student_enrollment&page=1&per_page=10`
const SECTION_PACE_CREATION_API = `/api/v1/courses/${COURSE.id}/course_pacing/new?course_section_id=${firstSection.item_id}`

describe('PaceContextsContent', () => {
  beforeAll(() => {
    jest.useFakeTimers()
  })

  beforeEach(() => {
    fetchMock.get(SECTION_CONTEXTS_API, JSON.stringify(PACE_CONTEXTS_SECTIONS_RESPONSE))
    fetchMock.get(STUDENT_CONTEXTS_API, JSON.stringify(PACE_CONTEXTS_STUDENTS_RESPONSE))
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

  it('fetches student contexts when clicking the Students tab', async () => {
    const {findByText, getByRole} = renderConnected(<PaceContent />)
    const studentsTab = getByRole('tab', {name: 'Students'})
    act(() => studentsTab.click())
    expect(
      await findByText(PACE_CONTEXTS_STUDENTS_RESPONSE.pace_contexts[0].name)
    ).toBeInTheDocument()
    expect(
      await findByText(PACE_CONTEXTS_STUDENTS_RESPONSE.pace_contexts[1].name)
    ).toBeInTheDocument()
  })

  it('shows custom data for sections', async () => {
    const headers = ['Section', 'Section Size', 'Pace Type', 'Last Modified']
    const sectionPaceContext = PACE_CONTEXTS_SECTIONS_RESPONSE.pace_contexts[0]
    const {findByText, getByText, getAllByText} = renderConnected(<PaceContent />)
    expect(await findByText(sectionPaceContext.name)).toBeInTheDocument()
    headers.map(header => {
      expect(getAllByText(header)[0]).toBeInTheDocument()
    })
    expect(getByText(`${sectionPaceContext.associated_student_count} Students`)).toBeInTheDocument()
    expect(getAllByText('Section')[0]).toBeInTheDocument()
  })

  it('shows custom data for students', async () => {
    const headers = ['Student', 'Assigned Pace', 'Pace Type', 'Last Modified']
    const studentPaceContext = PACE_CONTEXTS_STUDENTS_RESPONSE.pace_contexts[0]
    const {findByText, getByText, getByRole, getAllByText} = renderConnected(<PaceContent />)
    const studentsTab = getByRole('tab', {name: 'Students'})
    act(() => studentsTab.click())
    expect(await findByText(studentPaceContext.name)).toBeInTheDocument()
    headers.map(header => {
      expect(getAllByText(header)[0]).toBeInTheDocument()
    })
    expect(getByText(studentPaceContext.applied_pace.name)).toBeInTheDocument()
    expect(getAllByText('Individual')[0]).toBeInTheDocument()
  })

  it('provides contextType and contextId to Pace modal', async () => {
    const {findByRole} = renderConnected(<PaceContent />)
    const studentLink = await findByRole('button', {name: firstSection.name})
    act(() => studentLink.click())
    expect(uiActions.setSelectedPaceContext).toHaveBeenCalledWith('Section', firstSection.item_id)
  })
})
