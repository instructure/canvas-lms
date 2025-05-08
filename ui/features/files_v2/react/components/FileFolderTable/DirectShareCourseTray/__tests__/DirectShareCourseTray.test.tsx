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
import {render, cleanup, screen} from '@testing-library/react'
import useManagedCourseSearchApi from '@canvas/direct-sharing/react/effects/useManagedCourseSearchApi'
import useModuleCourseSearchApi from '@canvas/direct-sharing/react/effects/useModuleCourseSearchApi'
import {FAKE_FILES} from '../../../../../fixtures/fakeData'
import DirectShareCourseTray from '../DirectShareCourseTray'
import doFetchApi from '@canvas/do-fetch-api-effect'
import userEvent from '@testing-library/user-event'

jest.mock('@canvas/direct-sharing/react/effects/useManagedCourseSearchApi')
jest.mock('@canvas/direct-sharing/react/effects/useModuleCourseSearchApi')
jest.mock('@canvas/do-fetch-api-effect')

const courseA = {id: '1', name: 'Course A', course_code: '1', term: 'default term'}
const courseB = {id: '2', name: 'Course B', course_code: '2', term: 'default term'}

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
    if (ariaLive) document.body.removeChild(ariaLive)
  })

  beforeEach(() => {
    ;(useManagedCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([courseA, courseB])
    })
    ;(useModuleCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([])
    })
    ;(doFetchApi as jest.Mock).mockResolvedValue({})
  })

  afterEach(() => {
    jest.clearAllMocks()
    jest.resetAllMocks()
    cleanup()
  })

  it('shows the overwrite warning', () => {
    renderComponent()
    expect(
      screen.getByText(/^Importing the same course content more than once/),
    ).toBeInTheDocument()
  })

  it('calls the onDismiss property', async () => {
    renderComponent()
    await userEvent.click(screen.getByTestId('direct-share-course-cancel'))
    expect(defaultProps.onDismiss).toHaveBeenCalled()
  })

  it('starts a copy operation and reports status', async () => {
    renderComponent()

    const input = await screen.getByLabelText(/select a course/i)
    await userEvent.click(input)
    await userEvent.type(input, courseA.name)
    await userEvent.click(screen.getByText(courseA.name))
    await userEvent.click(screen.getByTestId('direct-share-course-copy'))

    expect(doFetchApi as jest.Mock).toHaveBeenCalledWith({
      method: 'POST',
      path: `/api/v1/courses/1/content_migrations`,
      body: {
        migration_type: 'course_copy_importer',
        select: {attachments: [178]},
        settings: {
          source_course_id: '1',
          insert_into_module_id: null,
          associate_with_assignment_id: null,
          is_copy_to: true,
          insert_into_module_type: 'attachments',
          insert_into_module_position: null,
        },
      },
    })

    expect(await screen.getAllByText(/start/i)[0]).toBeInTheDocument()
    expect(await screen.getAllByText(/success/i)[0]).toBeInTheDocument()
    expect(defaultProps.onDismiss).toHaveBeenCalled()
  })

  it('deletes the module and removes the position selector when a new course is selected', async () => {
    ;(useModuleCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([
        {id: '1', name: 'Module 1'},
        {id: '2', name: 'Module 2'},
      ])
    })

    renderComponent()

    let input = await screen.getByLabelText(/select a course/i)
    await userEvent.click(input)
    await userEvent.type(input, courseA.name)
    await userEvent.click(screen.getByText(courseA.name))

    input = await screen.getByLabelText(/select a module/i)
    await userEvent.click(input)
    await userEvent.type(input, 'Module 1')
    await userEvent.click(screen.getByText('Module 1'))

    expect(await screen.getByTestId('select-position')).toBeInTheDocument()
    expect(doFetchApi).toHaveBeenCalled()
    ;(useManagedCourseSearchApi as jest.Mock).mockImplementationOnce(({success}) => {
      success([courseA, courseB])
    })
    ;(doFetchApi as jest.Mock).mockClear()

    input = await screen.getByLabelText(/select a course/i)
    await userEvent.click(input)
    await userEvent.type(input, courseB.name)
    await userEvent.click(screen.getByText(courseB.name))

    expect(await screen.queryByTestId('select-position')).not.toBeInTheDocument()
    expect(doFetchApi).not.toHaveBeenCalled()
  })

  describe('errors', () => {
    it('shows an error when user tries to submit without a selected course', async () => {
      renderComponent()
      await userEvent.click(screen.getByTestId('direct-share-course-copy'))
      expect(await screen.getByLabelText(/a course needs to be selected/i)).toBeInTheDocument()
    })

    it('reports an error if the fetch fails', async () => {
      ;(doFetchApi as jest.Mock).mockRejectedValueOnce(() => ({}))

      renderComponent()
      const input = await screen.getByLabelText(/select a course/i)
      await userEvent.click(input)
      await userEvent.type(input, courseA.name)
      await userEvent.click(screen.getByText(courseA.name))
      await userEvent.click(screen.getByTestId('direct-share-course-copy'))

      expect(doFetchApi as jest.Mock).toHaveBeenCalledWith({
        method: 'POST',
        path: `/api/v1/courses/1/content_migrations`,
        body: {
          migration_type: 'course_copy_importer',
          select: {attachments: [178]},
          settings: {
            source_course_id: '1',
            insert_into_module_id: null,
            associate_with_assignment_id: null,
            is_copy_to: true,
            insert_into_module_type: 'attachments',
            insert_into_module_position: null,
          },
        },
      })

      expect(await screen.getAllByText(/start/i)[0]).toBeInTheDocument()
      expect(await screen.getAllByText(/failed/i)[0]).toBeInTheDocument()
      expect(defaultProps.onDismiss).not.toHaveBeenCalled()
    })
  })
})
