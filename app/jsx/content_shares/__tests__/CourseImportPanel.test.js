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
import CourseImportPanel from '../CourseImportPanel'
import {mockShare} from 'jsx/content_shares/__tests__/test-utils'

jest.mock('jsx/shared/effects/useManagedCourseSearchApi')

describe('CourseImportPanel', () => {
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

  it('disables the import button initially', () => {
    const {getByText} = render(<CourseImportPanel contentShare={mockShare()} />)
    expect(
      getByText(/import/i)
        .closest('button')
        .getAttribute('disabled')
    ).toBe('')
  })

  it('enables the import button when a course is selected', () => {
    const {getByText} = render(<CourseImportPanel contentShare={mockShare()} />)
    fireEvent.click(getByText(/select a course/i))
    fireEvent.click(getByText('abc'))
    const copyButton = getByText(/import/i).closest('button')
    expect(copyButton.getAttribute('disabled')).toBe(null)
  })

  it('disables the import button again when a course search is initiated', () => {
    const {getByText, getByLabelText} = render(<CourseImportPanel contentShare={mockShare()} />)
    const input = getByLabelText(/select a course/i)
    fireEvent.click(input)
    fireEvent.click(getByText('abc'))
    fireEvent.change(input, {target: {value: 'foo'}})
    expect(
      getByText(/import/i)
        .closest('button')
        .getAttribute('disabled')
    ).toBe('')
  })

  it('starts an import operation and reports status', async () => {
    const share = mockShare()
    fetchMock.postOnce('path:/api/v1/courses/abc/content_migrations', {
      id: '8',
      workflow_state: 'running'
    })
    const {getByText, getByLabelText, queryByText} = render(
      <CourseImportPanel contentShare={share} />
    )
    const input = getByLabelText(/select a course/i)
    fireEvent.click(input)
    fireEvent.click(getByText('abc'))
    fireEvent.click(getByText(/import/i))
    expect(queryByText('Import')).toBeNull()
    expect(getByText('Close')).toBeInTheDocument()
    const [, fetchOptions] = fetchMock.lastCall()
    expect(fetchOptions.method).toBe('POST')
    expect(JSON.parse(fetchOptions.body)).toMatchObject({
      migration_type: 'canvas_cartridge_importer',
      settings: {content_export_id: share.content_export.id}
    })
    expect(getByText(/start/i)).toBeInTheDocument()
    await act(() => fetchMock.flush(true))
    expect(getByText(/success/)).toBeInTheDocument()
    expect(queryByText('Import')).toBeNull()
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
        <CourseImportPanel contentShare={mockShare()} />
      )
      const input = getByLabelText(/select a course/i)
      fireEvent.click(input)
      fireEvent.click(getByText('abc'))
      fireEvent.click(getByText('Import'))
      await act(() => fetchMock.flush(true))
      expect(getByText(/problem/i)).toBeInTheDocument()
      expect(queryByText('Import')).toBeNull()
      expect(getByText('Close')).toBeInTheDocument()
    })
  })
})
