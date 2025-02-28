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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import LinkToStudents, {LinkToStudentsProps, Observee} from '../LinkToStudents'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'

describe('LinkToStudents', () => {
  const GET_OBSERVEES_URL = '/search/recipients'
  const GET_USER_URL = (courseId: string, userId: string) =>
    `/api/v1/courses/${courseId}/users/${userId}`
  const LINK_OBSERVEE_URL = (courseSectionId: string) =>
    `/api/v1/sections/${courseSectionId}/enrollments`
  const UNLINK_OBSERVEE_URL = (courseId: string, enrollmentId: string) =>
    `/courses/${courseId}/unenroll/${enrollmentId}`
  const firstObservee: Observee = {
    id: '1',
    name: 'Pikachu',
    avatar_url: 'pikachu_avatar_url',
    enrollments: [
      {
        course_section_id: '1',
        id: '1',
        type: 'StudentEnrollment',
        associated_user_id: '1',
      },
    ],
  }
  const props: LinkToStudentsProps = {
    course: {
      id: '1',
      name: 'course1',
    },
    initialObservees: [],
    observer: {
      id: '1',
      name: 'John Doe',
      avatar_url: 'avatar_url',
      enrollments: [],
    },
    onClose: jest.fn(),
    onSubmit: jest.fn(),
  }

  beforeAll(() => {
    // Not supported by the current version of NodeJS. It will be available in 22.11.0
    Set.prototype.difference = function (setB: Set<any>) {
      const difference = new Set(this)
      for (const elem of setB) {
        difference.delete(elem)
      }
      return difference
    }
  })

  afterAll(() => {
    Set.prototype.difference = undefined as any
  })

  afterEach(() => {
    fetchMock.reset()
  })

  it('should render the observer name in the description', () => {
    render(<LinkToStudents {...props} />)
    const observerName = screen.getByText(props.observer.name)

    expect(observerName).toBeInTheDocument()
  })

  it('should be able to close the modal', async () => {
    render(<LinkToStudents {...props} />)
    const cancelButton = screen.getByLabelText('Cancel')

    await userEvent.click(cancelButton)

    expect(props.onClose).toHaveBeenCalled()
  })

  describe('when the observer has no observees', () => {
    it('should be able to add a student as observee', async () => {
      fetchMock.get(new RegExp(GET_OBSERVEES_URL), [firstObservee], {
        overwriteRoutes: true,
      })
      fetchMock.get(new RegExp(GET_USER_URL(props.course.id, firstObservee.id)), firstObservee, {
        overwriteRoutes: true,
      })
      fetchMock.post(
        LINK_OBSERVEE_URL(props.course.id),
        {observed_user: firstObservee},
        {overwriteRoutes: true},
      )
      render(<LinkToStudents {...props} />)
      const observeeSelect = screen.getByLabelText('Observee select')

      fireEvent.click(observeeSelect)
      const observeeOption = await screen.findByText(firstObservee.name)
      fireEvent.click(observeeOption)

      const tag = await screen.findByTestId(`observee-tag-${firstObservee.id}`)
      expect(tag).toBeInTheDocument()

      const updateButton = screen.getByLabelText('Update')
      fireEvent.click(updateButton)

      await waitFor(() => {
        expect(props.onSubmit).toHaveBeenCalledWith([{observed_user: firstObservee}], [])
      })
    })
  })

  describe('when the observer has observees', () => {
    it('should be able to remove an observee', async () => {
      const [enrollmentOfFirstObservee] = firstObservee.enrollments!
      fetchMock.get(new RegExp(GET_OBSERVEES_URL), [firstObservee], {
        overwriteRoutes: true,
      })
      fetchMock.get(new RegExp(GET_USER_URL(props.course.id, firstObservee.id)), firstObservee, {
        overwriteRoutes: true,
      })
      fetchMock.delete(
        UNLINK_OBSERVEE_URL(props.course.id, enrollmentOfFirstObservee.id),
        {enrollment: {observed_user: firstObservee}},
        {overwriteRoutes: true},
      )
      render(
        <LinkToStudents
          {...props}
          observer={{...props.observer, enrollments: [enrollmentOfFirstObservee]}}
          initialObservees={[firstObservee]}
        />,
      )

      const tag = await screen.findByTestId(`observee-tag-${firstObservee.id}`)
      expect(tag).toBeInTheDocument()

      fireEvent.click(tag)

      const updateButton = screen.getByLabelText('Update')
      fireEvent.click(updateButton)

      await waitFor(() => {
        expect(props.onSubmit).toHaveBeenCalledWith([], [{observed_user: firstObservee}])
      })
    })
  })
})
