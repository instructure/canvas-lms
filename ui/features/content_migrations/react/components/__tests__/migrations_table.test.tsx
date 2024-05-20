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
import {render, waitFor, screen} from '@testing-library/react'
import ContentMigrationsTable from '../migrations_table'
import fetchMock from 'fetch-mock'
import type {ContentMigrationItem} from '../types'

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
let setMigrationsMock: () => void

const renderComponent = () => {
  return render(
    <ContentMigrationsTable migrations={migrations} setMigrations={setMigrationsMock} />
  )
}

describe('ContentMigrationTable', () => {
  // This is used to mock the result INST-UI Responsive component for rendering
  const originalMediaResult = window.matchMedia('(min-width: 768px)')

  afterEach(() => {
    jest.clearAllMocks()
  })

  beforeAll(() => {
    setMigrationsMock = jest.fn(() => {})
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
      renderComponent()

      const headers = Array.from(document.querySelectorAll('span[as="th"]')).map(e => e.textContent)
      const data = Array.from(document.querySelectorAll('span[as="td"]')).map(e => e.textContent)

      expect(headers).toEqual([
        'Content Type',
        'Source Link',
        'Date Imported',
        'Status',
        'Progress',
        'Action',
      ])
      expect(data).toEqual([
        'Copy a Canvas Course',
        'Other course',
        'Apr 15 at 9:11pm',
        'Waiting for selection',
        'Select content',
        '',
      ])
    })

    it('calls the API', async () => {
      renderComponent()

      expect(fetchMock.called('/api/v1/courses/0/content_migrations?per_page=25', 'GET')).toBe(true)
      await waitFor(() => {
        expect(setMigrationsMock).toHaveBeenCalledWith(expect.any(Function))
      })
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
      renderComponent()

      expect(screen.getByRole('table', {hidden: false})).toBeInTheDocument()
      expect(
        screen.getByRole('row', {
          name: 'Content Type Source Link Date Imported Status Progress Action',
          hidden: false,
        })
      ).toBeInTheDocument()
    })

    it('calls the API', async () => {
      renderComponent()

      expect(fetchMock.called('/api/v1/courses/0/content_migrations?per_page=25', 'GET')).toBe(true)
      await waitFor(() => {
        expect(setMigrationsMock).toHaveBeenCalledWith(expect.any(Function))
      })
    })
  })
})
