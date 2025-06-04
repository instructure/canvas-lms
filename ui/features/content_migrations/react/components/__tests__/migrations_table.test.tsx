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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import ContentMigrationsTable from '../migrations_table'
import fetchMock from 'fetch-mock'
import type {ContentMigrationItem} from '../types'
import fakeENV from '@canvas/test-utils/fakeENV'

const migrations: ContentMigrationItem[] = [
  {
    id: '123',
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
  },
]

const fetchNext = jest.fn()

const renderComponent = ({
  migrationArray = migrations,
  isLoading = false,
  hasMore = false,
}: {
  migrationArray?: ContentMigrationItem[]
  isLoading?: boolean
  hasMore?: boolean
}) => {
  return render(
    <ContentMigrationsTable
      migrations={migrationArray}
      isLoading={isLoading}
      updateMigrationItem={jest.fn()}
      fetchNext={fetchNext}
      hasMore={hasMore}
    />,
  )
}

describe('ContentMigrationTable', () => {
  // This is used to mock the result INST-UI Responsive component for rendering
  const originalMediaResult = window.matchMedia('(min-width: 768px)')

  afterEach(() => {
    jest.clearAllMocks()
  })

  beforeAll(() => {
    window.ENV.COURSE_ID = '0'
    fetchMock.mock('/api/v1/courses/0/content_migrations?per_page=25', ['api_return'])
  })

  describe('ContentMigrationTableCondensedView', () => {
    beforeAll(() => {
      Object.defineProperty(originalMediaResult, 'matches', {
        value: false,
        writable: true,
        configurable: true,
        enumerable: true,
      })
      window.matchMedia = jest.fn().mockReturnValueOnce(originalMediaResult)
    })

    it('renders the table', () => {
      renderComponent({})

      const headers = Array.from(document.querySelectorAll('[role="cell"] strong')).map(
        e => e.textContent,
      )

      // Get all cells
      const cells = Array.from(document.querySelectorAll('[role="cell"]'))

      // Verify headers
      expect(headers).toEqual([
        'Content Type',
        'Source Link',
        'Date Imported',
        'Status',
        'Progress',
        'Action',
      ])

      // Verify cell content for the first 4 cells and the last cell
      expect(cells[0].textContent).toBe('Content Type: Copy a Canvas Course')
      expect(cells[1].textContent).toBe('Source Link: Other course')
      expect(cells[2].textContent).toBe('Date Imported: Apr 15 at 9:11pm')
      expect(cells[3].textContent).toBe('Status: Waiting for selection')
      expect(cells[5].textContent).toBe('Action: ')

      // For the Progress cell, we just verify it exists
      // The content may vary based on the migration state and view mode
      const progressCell = cells[4]
      expect(progressCell).toBeInTheDocument()
    })

    it('displays the loading spinner', () => {
      renderComponent({isLoading: true})

      expect(screen.getByLabelText('Loading')).toBeInTheDocument()
    })
  })

  describe('ContentMigrationTableExpandedView', () => {
    beforeAll(() => {
      Object.defineProperty(originalMediaResult, 'matches', {
        value: true,
        writable: true,
        configurable: true,
        enumerable: true,
      })
      window.matchMedia = jest.fn().mockReturnValueOnce(originalMediaResult)
    })

    it('renders the table', () => {
      renderComponent({})

      // Verify table exists
      expect(screen.getByRole('table')).toBeInTheDocument()

      // Verify that key content is present
      expect(screen.getByText(/Content Type/)).toBeInTheDocument()
      expect(screen.getByText(/Copy a Canvas Course/)).toBeInTheDocument()
      expect(screen.getByText(/Source Link/)).toBeInTheDocument()
      expect(screen.getByText(/Other course/)).toBeInTheDocument()
      expect(screen.getByText(/Date Imported/)).toBeInTheDocument()
      expect(screen.getByText(/Status/)).toBeInTheDocument()

      // Verify migration status pill is present
      expect(screen.getByTestId('migrationStatus')).toBeInTheDocument()
      expect(screen.getByText(/Waiting for selection/)).toBeInTheDocument()
    })

    it('displays the loading spinner', () => {
      renderComponent({isLoading: true})

      expect(screen.getByLabelText('Loading')).toBeInTheDocument()
    })

    it('fetches next page of migrations when scrolled to the bottom', async () => {
      renderComponent({isLoading: false, hasMore: true})

      fireEvent.scroll(window, {target: {scrollY: 10000}})

      await waitFor(() => {
        expect(fetchNext).toHaveBeenCalled()
      })
    })
  })

  describe('Content migration expire', () => {
    it('renders the message with correct days', () => {
      fakeENV.setup({CONTENT_MIGRATIONS_EXPIRE_DAYS: 30})
      renderComponent({})

      expect(
        screen.getByText('Content import files cannot be downloaded after 30 days.'),
      ).toBeInTheDocument()
    })

    it('does not renders the message when ENV.CONTENT_MIGRATIONS_EXPIRE_DAYS is not set', () => {
      fakeENV.setup({CONTENT_MIGRATIONS_EXPIRE_DAYS: undefined})
      renderComponent({})

      expect(
        screen.queryByText(/Content import files cannot be downloaded after/),
      ).not.toBeInTheDocument()
    })
  })
})
