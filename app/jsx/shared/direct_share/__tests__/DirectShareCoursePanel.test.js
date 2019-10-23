/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, fireEvent, act} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import useManagedCourseSearchApi from 'jsx/shared/effects/useManagedCourseSearchApi'
import DirectShareCoursePanel from '../DirectShareCoursePanel'

jest.mock('jsx/shared/effects/useManagedCourseSearchApi')

describe('DirectShareCoursePanel', () => {
  let ariaLive

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
    useManagedCourseSearchApi.mockImplementationOnce(({success}) => {
      success([{id: 'abc', name: 'abc'}, {id: 'cde', name: 'cde'}])
    })
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('disables the copy button initially', () => {
    const {getByText} = render(<DirectShareCoursePanel />)
    expect(
      getByText(/copy/i)
        .closest('button')
        .getAttribute('disabled')
    ).toBe('')
  })

  it('enables the copy button when a course is selected and calls onStart property', () => {
    const handleStart = jest.fn()
    const {getByText} = render(<DirectShareCoursePanel onStart={handleStart} />)
    fireEvent.click(getByText(/select a course/i))
    fireEvent.click(getByText('abc'))
    const copyButton = getByText(/copy/i).closest('button')
    expect(copyButton.getAttribute('disabled')).toBe(null)
  })

  it('disables the copy button again when a course search is initiated', () => {
    const {getByText, getByLabelText} = render(<DirectShareCoursePanel />)
    const input = getByLabelText(/select a course/i)
    fireEvent.click(input)
    fireEvent.click(getByText('abc'))
    fireEvent.change(input, {target: {value: 'foo'}})
    expect(
      getByText(/copy/i)
        .closest('button')
        .getAttribute('disabled')
    ).toBe('')
  })

  it('calls the onCancel property', () => {
    const handleCancel = jest.fn()
    const {getByText} = render(<DirectShareCoursePanel onCancel={handleCancel} />)
    fireEvent.click(getByText(/cancel/i))
    expect(handleCancel).toHaveBeenCalled()
  })

  it('starts a copy operation and reports status', async () => {
    fetchMock.postOnce('path:/api/v1/courses/abc/content_migrations', {
      id: '8',
      workflow_state: 'running'
    })
    const {getByText, getByLabelText, queryByText} = render(
      <DirectShareCoursePanel
        sourceCourseId="42"
        contentSelection={{discussion_topics: ['1123']}}
      />
    )
    const input = getByLabelText(/select a course/i)
    fireEvent.click(input)
    fireEvent.click(getByText('abc'))
    fireEvent.click(getByText(/copy/i))
    expect(queryByText('Copy')).toBeNull()
    expect(getByText('Close')).toBeInTheDocument()
    const [, fetchOptions] = fetchMock.lastCall()
    expect(fetchOptions.method).toBe('POST')
    expect(JSON.parse(fetchOptions.body)).toMatchObject({
      migration_type: 'course_copy_importer',
      select: {discussion_topics: ['1123']},
      settings: {source_course_id: '42'}
    })
    expect(getByText(/start/i)).toBeInTheDocument()
    await act(() => fetchMock.flush(true))
    expect(getByText(/success/)).toBeInTheDocument()
    expect(queryByText('Copy')).toBeNull()
    expect(getByText('Close')).toBeInTheDocument()
  })

  describe('errors', () => {
    beforeEach(() => {
      jest.spyOn(console, 'error').mockImplementation()
    })

    afterEach(() => {
      console.error.mockRestore() // eslint-disable-line no-console
    })

    it('reports an error if the fetch fails', async () => {
      fetchMock.postOnce('path:/api/v1/courses/abc/content_migrations', 400)
      const {getByText, getByLabelText, queryByText} = render(
        <DirectShareCoursePanel sourceCourseId="42" />
      )
      const input = getByLabelText(/select a course/i)
      fireEvent.click(input)
      fireEvent.click(getByText('abc'))
      fireEvent.click(getByText('Copy'))
      await act(() => fetchMock.flush(true))
      expect(getByText(/problem/i)).toBeInTheDocument()
      expect(queryByText('Copy')).toBeNull()
      expect(getByText('Close')).toBeInTheDocument()
    })
  })
})
