/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, screen, waitFor} from '@testing-library/react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {ContentSelectionModal} from '../content_selection_modal'

jest.mock('@canvas/do-fetch-api-effect')

const selectiveData: any[] = [
  {
    property: 'copy[all_course_settings]',
    title: 'Course Settings',
    type: 'course_settings',
  },
]

const migration = {
  id: '2',
  migration_type: 'course_copy_importer',
  migration_type_title: 'Copy a Canvas Course',
  progress_url: 'http://mock.progress.url',
  settings: {
    source_course_id: '456',
    source_course_name: 'Other course',
    source_course_html_url: 'http://mock.other-course.url',
  },
  workflow_state: 'waiting_for_select',
  migration_issues_count: 0,
  migration_issues_url: 'http://mock.issues.url',
  created_at: 'Apr 15 at 9:11pm',
}

const renderComponent = (overrideProps?: any) =>
  render(<ContentSelectionModal courseId="1" migration={migration} {...overrideProps} />)

describe('ContentSelectionModal', () => {
  afterEach(() => jest.clearAllMocks())

  it('renders button', () => {
    renderComponent()
    expect(screen.getByRole('button', {name: 'Select content'})).toBeInTheDocument()
  })

  describe('modal', () => {
    beforeEach(() => doFetchApi.mockImplementation(() => Promise.resolve({json: selectiveData})))

    it('opens on click', async () => {
      renderComponent()
      const button = screen.getByRole('button', {name: 'Select content'})
      await userEvent.click(button)
      expect(screen.getByRole('heading', {name: 'Select Content for Import'})).toBeInTheDocument()
    })

    it('fetch content selection data', async () => {
      renderComponent()
      const button = screen.getByRole('button', {name: 'Select content'})
      await userEvent.click(button)
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/api/v1/courses/1/content_migrations/2/selective_data',
        method: 'GET',
      })
    })

    it('shows content selection data', async () => {
      renderComponent()
      const button = screen.getByRole('button', {name: 'Select content'})
      await userEvent.click(button)
      await waitFor(() => expect(screen.getAllByText('Course Settings')[0]).toBeInTheDocument())
    })

    it('sends user content selection', async () => {
      window.ENV.current_user_id = '3'
      renderComponent()
      const button = screen.getByRole('button', {name: 'Select content'})
      await userEvent.click(button)
      await waitFor(() => expect(screen.getByRole('checkbox')).toBeInTheDocument())
      const checkbox = screen.getByRole('checkbox')
      await userEvent.click(checkbox)
      const submitButton = screen.getByRole('button', {name: 'Select Content'})
      await userEvent.click(submitButton)

      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/api/v1/courses/1/content_migrations/2',
        method: 'PUT',
        body: {
          id: '2',
          user_id: '3',
          workflow_state: 'waiting_for_select',
          copy: {
            all_course_settings: '1',
          },
        },
      })
    })

    it('calls updateMigrationItem', async () => {
      window.ENV.current_user_id = '3'
      const updateMigrationItem = jest.fn()
      renderComponent({updateMigrationItem})
      expect(updateMigrationItem).not.toHaveBeenCalled()

      const button = screen.getByRole('button', {name: 'Select content'})
      await userEvent.click(button)
      await waitFor(() => expect(screen.getByRole('checkbox')).toBeInTheDocument())
      const checkbox = screen.getByRole('checkbox')
      await userEvent.click(checkbox)
      const submitButton = screen.getByRole('button', {name: 'Select Content'})
      await userEvent.click(submitButton)

      await waitFor(() => {
        expect(updateMigrationItem).toHaveBeenCalled()
      })
    })

    it('shows alert if fetch fails', async () => {
      doFetchApi.mockImplementation(() => Promise.reject())
      renderComponent()
      const button = screen.getByRole('button', {name: 'Select content'})
      await userEvent.click(button)
      await waitFor(() => {
        expect(screen.getByText('Failed to fetch content for import.')).toBeInTheDocument()
      })
    })

    it('shows spinner when loading', async () => {
      doFetchApi.mockImplementation(() => new Promise(resolve => setTimeout(resolve, 5000)))
      renderComponent()
      const button = screen.getByRole('button', {name: 'Select content'})
      await userEvent.click(button)
      expect(screen.getByText('Loading content for import.')).toBeInTheDocument()
    })

    it('closes with x button', async () => {
      const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
      renderComponent()
      const button = screen.getByRole('button', {name: 'Select content'})
      await user.click(button)
      const xButton = screen.getByText('Close')
      await user.click(xButton)

      expect(
        screen.queryByRole('heading', {name: 'Select Content for Import'})
      ).not.toBeInTheDocument()
    })

    it('closes with cancel button', async () => {
      const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
      renderComponent()
      const button = screen.getByRole('button', {name: 'Select content'})
      await user.click(button)
      const cancelButton = screen.getByText('Cancel')
      await user.click(cancelButton)

      expect(
        screen.queryByRole('heading', {name: 'Select Content for Import'})
      ).not.toBeInTheDocument()
    })
  })
})
