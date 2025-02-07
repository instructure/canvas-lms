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
    // @ts-expect-error
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

    describe('when selectiveData contains nested sub_items_url', () => {
      const subItemUrl1 = 'http://mock.sub-items.url1'
      const selectiveDataWithSubItems1 = [
        {
          property: 'copy[sub_item1]',
          title: 'sub_item1',
          type: 'course_settings',
          sub_items_url: subItemUrl1,
          count: 1,
        },
      ]
      const subItemUrl2 = 'http://mock.sub-items.url2'
      const selectiveDataWithSubItems2 = [
        {
          property: 'copy[sub_item2]',
          title: 'sub_item2',
          type: 'course_settings',
          sub_items_url: subItemUrl2,
          count: 1,
        },
      ]

      beforeEach(() => {
        // @ts-expect-error
        doFetchApi.mockImplementationOnce(() => Promise.resolve({json: selectiveDataWithSubItems1}))
        // @ts-expect-error
        doFetchApi.mockImplementationOnce(() => Promise.resolve({json: selectiveDataWithSubItems2}))
        // @ts-expect-error
        doFetchApi.mockImplementationOnce(() => Promise.resolve({json: selectiveData}))
      })

      it('fetches nested sub items', async () => {
        renderComponent()
        const button = screen.getByRole('button', {name: 'Select content'})
        await userEvent.click(button)

        expect(doFetchApi).toHaveBeenNthCalledWith(1, {
          path: '/api/v1/courses/1/content_migrations/2/selective_data',
          method: 'GET',
        })
        expect(doFetchApi).toHaveBeenNthCalledWith(2, {
          path: subItemUrl1,
          method: 'GET',
        })
        expect(doFetchApi).toHaveBeenNthCalledWith(3, {
          path: subItemUrl2,
          method: 'GET',
        })
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

    describe('fetch fails', () => {
      beforeEach(async () => {
        // @ts-expect-error
        doFetchApi.mockImplementation(() => Promise.reject())
        renderComponent()
        const button = screen.getByRole('button', {name: 'Select content'})
        await userEvent.click(button)
      })

      it('shows alert', async () => {
        await waitFor(() => {
          expect(screen.getByText('Failed to fetch content for import.')).toBeInTheDocument()
        })
      })

      it('submit button is disabled', async () => {
        expect(screen.getByRole('button', {name: 'Select Content'})).toBeDisabled()
      })
    })

    describe('is loading', () => {
      beforeEach(async () => {
        // @ts-expect-error
        doFetchApi.mockImplementation(() => new Promise(resolve => setTimeout(resolve, 5000)))
        renderComponent()
        const button = screen.getByRole('button', {name: 'Select content'})
        await userEvent.click(button)
      })

      it('shows spinner', async () => {
        expect(screen.getByText('Loading content for import.')).toBeInTheDocument()
      })

      it('submit button is disabled', async () => {
        expect(screen.getByRole('button', {name: 'Select Content'})).toBeDisabled()
      })
    })

    it('closes with x button', async () => {
      const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
      renderComponent()
      const button = screen.getByRole('button', {name: 'Select content'})
      await user.click(button)
      const xButton = screen.getByText('Close')
      await user.click(xButton)

      expect(
        screen.queryByRole('heading', {name: 'Select Content for Import'}),
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
        screen.queryByRole('heading', {name: 'Select Content for Import'}),
      ).not.toBeInTheDocument()
    })

    describe('response is empty', () => {
      beforeEach(async () => {
        // @ts-expect-error
        doFetchApi.mockImplementation(() => Promise.resolve({json: []}))
        renderComponent()
        const button = screen.getByRole('button', {name: 'Select content'})
        await userEvent.click(button)
      })

      it('show empty message', async () => {
        await waitFor(() => {
          expect(
            screen.getByText(
              'This file appears to be empty. Do you still want to proceed with content selection?',
            ),
          ).toBeInTheDocument()
        })
      })

      it('submit button is enabled', async () => {
        expect(screen.getByRole('button', {name: 'Select Content'})).not.toBeDisabled()
      })

      it('sends empty data', async () => {
        window.ENV.current_user_id = '3'
        const submitButton = screen.getByRole('button', {name: 'Select Content'})
        await userEvent.click(submitButton)

        expect(doFetchApi).toHaveBeenCalledWith({
          path: '/api/v1/courses/1/content_migrations/2',
          method: 'PUT',
          body: {
            id: '2',
            user_id: '3',
            workflow_state: 'waiting_for_select',
            copy: {},
          },
        })
      })
    })
  })
})
