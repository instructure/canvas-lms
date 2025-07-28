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
import {render, screen} from '@testing-library/react'
import ManuallySettableQuotas from '../ManuallySettableQuotas'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'

describe('ManuallySettableQuotas', () => {
  const courseId = '1'
  const foundCourse = {name: 'Test Course', storage_quota_mb: '100'}
  const COURSE_API_URI = `/api/v1/courses/${courseId}`

  afterEach(() => {
    fetchMock.reset()
  })

  describe('Find course or group form', () => {
    it('should show an error message when the ID is empty', async () => {
      render(<ManuallySettableQuotas />)
      const id = screen.getByLabelText(/id \*/i)
      const submit = screen.getByLabelText('Find')

      await userEvent.clear(id)
      await userEvent.click(submit)

      const errorMessage = await screen.findByText('ID is required.')
      expect(errorMessage).toBeInTheDocument()
    })

    it('should show an error if the course/group not found', async () => {
      fetchMock.get(COURSE_API_URI, 404, {overwriteRoutes: true})
      render(<ManuallySettableQuotas />)
      const id = screen.getByLabelText(/id \*/i)
      const submit = screen.getByLabelText('Find')

      await userEvent.type(id, courseId)
      await userEvent.click(submit)

      const errorMessage = await screen.findAllByText('Could not find a course with that ID.')
      expect(errorMessage).toHaveLength(2)
      expect(fetchMock.called(COURSE_API_URI, {method: 'GET', body: {id: courseId}})).toBe(true)
    })

    it('should show an error if the user has no access to the course', async () => {
      fetchMock.get(COURSE_API_URI, 401, {overwriteRoutes: true})
      render(<ManuallySettableQuotas />)
      const id = screen.getByLabelText(/id \*/i)
      const submit = screen.getByLabelText('Find')

      await userEvent.type(id, courseId)
      await userEvent.click(submit)

      const errorMessage = await screen.findAllByText(
        'You are not authorized to access that course.',
      )
      expect(errorMessage).toHaveLength(2)
      expect(fetchMock.called(COURSE_API_URI, {method: 'GET', body: {id: courseId}})).toBe(true)
    })

    it('should show the quota form if the course/group is found', async () => {
      fetchMock.get(COURSE_API_URI, foundCourse, {overwriteRoutes: true})
      render(<ManuallySettableQuotas />)
      const id = screen.getByLabelText(/id \*/i)
      const submit = screen.getByLabelText('Find')

      await userEvent.type(id, courseId)
      await userEvent.click(submit)

      const courseLink = await screen.findByText(new RegExp(`${foundCourse.name} *`, 'i'))
      const courseStorage = await screen.findByLabelText(new RegExp(`${foundCourse.name} *`, 'i'))
      expect(courseLink).toHaveAttribute('href', `/courses/${courseId}`)
      expect(courseStorage).toHaveValue(foundCourse.storage_quota_mb)
    })
  })

  describe('Update quotas form', () => {
    beforeEach(async () => {
      fetchMock.get(COURSE_API_URI, foundCourse, {overwriteRoutes: true})
      render(<ManuallySettableQuotas />)
      const id = screen.getByLabelText(/id \*/i)
      const submit = screen.getByLabelText('Find')

      await userEvent.type(id, courseId)
      await userEvent.click(submit)
    })

    it('should show an error message when the quota is empty', async () => {
      const courseStorage = await screen.findByLabelText(new RegExp(`${foundCourse.name} *`, 'i'))
      const submit = screen.getByLabelText('Update Quota')

      await userEvent.clear(courseStorage)
      await userEvent.click(submit)

      const errorMessage = await screen.findByText('Quota is required.')
      expect(errorMessage).toBeInTheDocument()
    })

    it('should show an error message when the quota is not a number', async () => {
      const courseStorage = await screen.findByLabelText(new RegExp(`${foundCourse.name} *`, 'i'))
      const submit = screen.getByLabelText('Update Quota')
      const invalidQuota = 'invalid'

      await userEvent.type(courseStorage, invalidQuota)
      await userEvent.click(submit)

      const errorMessage = await screen.findByText('Quota must be an integer.')
      expect(errorMessage).toBeInTheDocument()
    })

    it('should show an error alert if the update fails', async () => {
      fetchMock.put(COURSE_API_URI, 500, {overwriteRoutes: true})
      const courseStorage = await screen.findByLabelText(new RegExp(`${foundCourse.name} *`, 'i'))
      const submit = screen.getByLabelText('Update Quota')

      await userEvent.type(courseStorage, '1000')
      await userEvent.click(submit)

      const errorMessage = await screen.findAllByText('Quota was not updated.')
      expect(errorMessage).toHaveLength(2)
    })

    it('should show a success alert if the quota was updated', async () => {
      fetchMock.put(COURSE_API_URI, 200, {overwriteRoutes: true})
      const courseStorage = await screen.findByLabelText(new RegExp(`${foundCourse.name} *`, 'i'))
      const submit = screen.getByLabelText('Update Quota')
      const newQuota = '1000'

      await userEvent.clear(courseStorage)
      await userEvent.type(courseStorage, newQuota)
      await userEvent.click(submit)

      const successMessage = await screen.findAllByText('Quota updated.')
      expect(successMessage).toHaveLength(2)
      expect(
        fetchMock.called(COURSE_API_URI, {
          method: 'PUT',
          body: {course: {...foundCourse, storage_quota_mb: newQuota}},
        }),
      ).toBe(true)
    })
  })
})
