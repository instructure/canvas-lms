/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, fireEvent, act, screen} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import useManagedCourseSearchApi from '@canvas/direct-sharing/react/effects/useManagedCourseSearchApi'
import useModuleCourseSearchApi, {
  useCourseModuleItemApi,
} from '@canvas/direct-sharing/react/effects/useModuleCourseSearchApi'
import {FAKE_FILES} from '../../../../../fixtures/fakeData'
import DirectShareCourseTray from '../DirectShareCourseTray'
import userEvent from '@testing-library/user-event'

jest.mock('@canvas/direct-sharing/react/effects/useManagedCourseSearchApi')
jest.mock('@canvas/direct-sharing/react/effects/useModuleCourseSearchApi')

const defaultProps = {
  open: true,
  onDismiss: jest.fn(),
  courseId: '1',
  file: FAKE_FILES[0],
}

const renderComponent = (props = {}) =>
  render(<DirectShareCourseTray {...defaultProps} {...props} />)

describe('DirectShareCourseTray', () => {
  let ariaLive: HTMLElement

  beforeAll(() => {
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    if (ariaLive) ariaLive.remove()
  })

  beforeEach(() => {
    ;(useManagedCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', name: 'abc', course_code: '1', term: 'default term'},
        {id: 'cde', name: 'cde', course_code: '1', term: 'default term'},
      ])
    })
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('shows the overwrite warning', () => {
    renderComponent()
    expect(
      screen.getByText(/^Importing the same course content more than once/),
    ).toBeInTheDocument()
  })

  it('calls the onDismiss property', () => {
    renderComponent()
    fireEvent.click(screen.getByText(/cancel/i))
    expect(defaultProps.onDismiss).toHaveBeenCalled()
  })

  // skip due to jenkins failure LX-2248
  it.skip('starts a copy operation and reports status', async () => {
    fetchMock.postOnce('path:/api/v1/courses/abc/content_migrations', {
      id: '8',
      workflow_state: 'running',
    })
    fetchMock.getOnce('path:/api/v1/courses/abc/modules', [])
    renderComponent()
    const input = await screen.getByLabelText(/select a course/i)
    await userEvent.click(input)
    await userEvent.type(input, 'abc')
    await userEvent.click(screen.getByText('abc'))
    await userEvent.click(screen.getByTestId('direct-share-course-copy'))
    const mockCall = fetchMock.lastCall()
    const fetchOptions = mockCall?.[1] || {}
    expect(fetchOptions.method).toBe('POST')
    expect(JSON.parse(fetchOptions.body?.toString() || '')).toMatchObject({
      migration_type: 'course_copy_importer',
      select: {attachments: ['178']},
      settings: {source_course_id: '1'},
    })
    expect(screen.getAllByText(/start/i)[0]).toBeInTheDocument()
    await act(() => {
      fetchMock.flush(true)
    })
    expect(screen.getAllByText(/success/i)[0]).toBeInTheDocument()
  })

  // skip due to jenkins failure LX-2248
  it.skip('deletes the module and removes the position selector when a new course is selected', async () => {
    ;(useModuleCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([
        {id: '1', name: 'Module 1'},
        {id: '2', name: 'Module 2'},
      ])
    })
    renderComponent()
    let input = await screen.getByLabelText(/select a course/i)
    await userEvent.click(input)
    await userEvent.type(input, 'abc')
    await userEvent.click(screen.getByText('abc'))

    input = await screen.getByLabelText(/select a module/i)
    await userEvent.click(input)
    await userEvent.type(input, 'Module 1')
    await userEvent.click(screen.getByText('Module 1'))
    expect(screen.getByTestId('select-position')).toBeInTheDocument()
    ;(useManagedCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([{id: 'ghi', name: 'foo', course_code: '3', term: 'default term'}])
    })
    ;(useCourseModuleItemApi as jest.Mock).mockClear()

    input = await screen.getByLabelText(/select a course/i)
    await userEvent.click(input)
    await userEvent.type(input, 'f')
    await userEvent.click(screen.getByText('foo'))
    expect(screen.queryByTestId('select-position')).not.toBeInTheDocument()
    expect(useCourseModuleItemApi).not.toHaveBeenCalled()
  })

  describe('errors', () => {
    it.skip('shows an error when user tries to submit without a selected course', async () => {
      renderComponent()
      await userEvent.click(screen.getByTestId('direct-share-course-copy'))
      expect(screen.getByLabelText(/a course needs to be selected/i)).toBeInTheDocument()
    })

    it.skip('reports an error if the fetch fails', async () => {
      fetchMock.postOnce('path:/api/v1/courses/abc/content_migrations', 400)
      fetchMock.getOnce('path:/api/v1/courses/abc/modules', [])
      renderComponent()
      const input = await screen.getByLabelText(/select a course/i)
      await userEvent.click(input)
      await userEvent.type(input, 'abc')
      await userEvent.click(screen.getByText('abc'))
      await userEvent.click(screen.getByTestId('direct-share-course-copy'))
      await act(() => {
        fetchMock.flush(true)
      })
      expect(screen.getAllByText(/start/i)[0]).toBeInTheDocument()
      expect(screen.getAllByText(/failed/i)[0]).toBeInTheDocument()
    })
  })
})
