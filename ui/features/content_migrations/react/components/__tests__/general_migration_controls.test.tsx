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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import GeneralMigrationControls from '../general_migration_controls'

describe('GeneralMigrationControls', () => {
  let submitMigrationMock: () => void

  beforeAll(() => {
    submitMigrationMock = jest.fn(() => {})
    fetchMock.mock('/api/v1/courses/0/content_migrations/migrators', [
      {
        name: 'Mock Migrator',
        type: 'mock_migrator',
      },
    ])
  })

  it('Runs proper callback on CTA click', async () => {
    render(<GeneralMigrationControls submitMigration={submitMigrationMock} />)
    userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue', hidden: false}))
    expect(submitMigrationMock).toHaveBeenCalledWith({
      adjustDates: false,
      importAsNewQuizzes: false,
      selectiveImport: false,
    })
  })
})
