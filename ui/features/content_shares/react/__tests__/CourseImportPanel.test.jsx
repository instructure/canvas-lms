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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import useManagedCourseSearchApi from '@canvas/direct-sharing/react/effects/useManagedCourseSearchApi'
import useModuleCourseSearchApi, {
  useCourseModuleItemApi,
} from '@canvas/direct-sharing/react/effects/useModuleCourseSearchApi'
import CourseImportPanel from '../CourseImportPanel'
import {mockShare} from './test-utils'

vi.mock('@canvas/direct-sharing/react/effects/useManagedCourseSearchApi')
vi.mock('@canvas/direct-sharing/react/effects/useModuleCourseSearchApi')

const server = setupServer()

describe('CourseImportPanel', () => {
  let ariaLive

  beforeAll(() => {
    server.listen()
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    server.close()
    if (ariaLive) ariaLive.remove()
  })

  beforeEach(() => {
    vi.mocked(useManagedCourseSearchApi).mockImplementationOnce(({success}) => {
      success([
        {id: 'abc', name: 'abc'},
        {id: 'cde', name: 'cde'},
      ])
    })
  })

  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
  })

  it('does not include concluded courses', () => {
    render(<CourseImportPanel contentShare={mockShare()} />)
    const hookCalls = useManagedCourseSearchApi.mock.calls
    expect(hookCalls.every(call => !call[0].params.include)).toBe(true)
  })

  it('disables the import button initially', () => {
    const {getByText} = render(<CourseImportPanel contentShare={mockShare()} />)
    expect(
      getByText(/import/i)
        .closest('button')
        .getAttribute('disabled'),
    ).toBe('')
  })

  it('enables the import button when a course is selected', async () => {
    server.use(http.get('/api/v1/courses/abc/modules', () => HttpResponse.json([])))
    const {getByText} = render(<CourseImportPanel contentShare={mockShare()} />)
    fireEvent.click(getByText(/select a course/i))
    fireEvent.click(getByText('abc'))
    const copyButton = getByText(/import/i).closest('button')
    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 0))
    })
    expect(copyButton.getAttribute('disabled')).toBe(null)
  })

  it('disables the import button again when a course search is initiated', async () => {
    server.use(http.get('/api/v1/courses/abc/modules', () => HttpResponse.json([])))
    const {getByText, getByLabelText} = render(<CourseImportPanel contentShare={mockShare()} />)
    const input = getByLabelText(/select a course/i)
    fireEvent.click(input)
    fireEvent.click(getByText('abc'))
    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 0))
    })
    fireEvent.change(input, {target: {value: 'foo'}})
    expect(
      getByText(/import/i)
        .closest('button')
        .getAttribute('disabled'),
    ).toBe('')
  })

  it('starts an import operation and reports status', async () => {
    const share = mockShare()
    const onImport = vi.fn()
    let capturedRequest = null
    server.use(
      http.post('/api/v1/courses/abc/content_migrations', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json({
          id: '8',
          workflow_state: 'running',
        })
      }),
    )
    vi.mocked(useModuleCourseSearchApi).mockImplementationOnce(({success}) => {
      success([
        {id: '1', name: 'Module 1'},
        {id: '2', name: 'Module 2'},
      ])
    })
    const {getByText, getAllByText, getByLabelText, queryByText} = render(
      <CourseImportPanel contentShare={share} onImport={onImport} />,
    )
    fireEvent.click(getByLabelText(/select a course/i))
    fireEvent.click(getByText('abc'))
    fireEvent.click(getByLabelText(/select a module/i))
    fireEvent.click(getByText('Module 1'))
    fireEvent.click(getByText(/import/i))
    expect(queryByText('Import')).toBeNull()
    expect(getByText('Close')).toBeInTheDocument()
    expect(getAllByText(/start/i)).not.toHaveLength(0)
    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 0))
    })
    expect(capturedRequest).toMatchObject({
      migration_type: 'canvas_cartridge_importer',
      settings: {content_export_id: share.content_export.id, insert_into_module_id: '1'},
    })
    expect(getByText(/success/)).toBeInTheDocument()
    expect(queryByText('Import')).toBeNull()
    expect(getByText('Close')).toBeInTheDocument()

    expect(onImport).toHaveBeenCalledTimes(1)
    expect(onImport.mock.calls[0][0]).toBe(share)
  })

  it('deletes the module and removes the position selector when a new course is selected', () => {
    const share = mockShare()
    vi.mocked(useModuleCourseSearchApi).mockImplementationOnce(({success}) => {
      success([
        {id: '1', name: 'Module 1'},
        {id: '2', name: 'Module 2'},
      ])
    })
    const {getByText, getByLabelText, queryByText} = render(
      <CourseImportPanel contentShare={share} />,
    )
    const courseSelector = getByText(/select a course/i)
    fireEvent.click(courseSelector)
    fireEvent.click(getByText('abc'))
    fireEvent.click(getByText(/select a module/i))
    fireEvent.click(getByText(/Module 1/))
    expect(getByText(/Place/)).toBeInTheDocument()
    vi.mocked(useManagedCourseSearchApi).mockImplementationOnce(({success}) => {
      success([{id: 'ghi', name: 'foo'}])
    })
    vi.mocked(useCourseModuleItemApi).mockClear()
    const input = getByLabelText(/select a course/i)
    fireEvent.change(input, {target: {value: 'f'}})
    fireEvent.click(getByText('foo'))
    expect(queryByText(/Place/)).not.toBeInTheDocument()
    expect(useCourseModuleItemApi).not.toHaveBeenCalled()
  })

  describe('errors', () => {
    let consoleErrorSpy

    beforeEach(() => {
      consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation()
    })

    afterEach(() => {
      consoleErrorSpy.mockRestore()
    })

    it('reports an error if the fetch fails', async () => {
      server.use(
        http.post(
          '/api/v1/courses/abc/content_migrations',
          () => new HttpResponse(null, {status: 400}),
        ),
        http.get('/api/v1/courses/abc/modules', () => HttpResponse.json([])),
      )
      const share = mockShare()
      const onImport = vi.fn()
      const {getByText, getByLabelText, queryByText} = render(
        <CourseImportPanel contentShare={share} onImport={onImport} />,
      )
      const input = getByLabelText(/select a course/i)
      fireEvent.click(input)
      fireEvent.click(getByText('abc'))
      fireEvent.click(getByText('Import'))
      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0))
      })
      expect(getByText(/problem/i)).toBeInTheDocument()
      expect(queryByText('Import')).toBeNull()
      expect(getByText('Close')).toBeInTheDocument()
      expect(onImport).toHaveBeenCalledTimes(1)
      expect(onImport.mock.calls[0][0]).toBe(share)
    })
  })
})
