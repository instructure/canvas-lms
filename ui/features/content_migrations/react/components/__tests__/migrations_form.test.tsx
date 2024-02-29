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
import {render, screen, waitFor, waitForElementToBeRemoved} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ContentMigrationsForm from '../migrations_form'
import fetchMock from 'fetch-mock'
import {completeUpload} from '@canvas/upload-file'

jest.mock('@canvas/upload-file', () => ({
  completeUpload: jest.fn(),
}))

const CommonCartridgeImporter = jest.fn()
jest.mock('../migrator_forms/common_cartridge', () => props => {
  CommonCartridgeImporter(props)
  return <mock-CommonCartridgeImporter />
})

const setMigrationsMock = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(<ContentMigrationsForm setMigrations={setMigrationsMock} {...overrideProps} />)

describe('ContentMigrationForm', () => {
  beforeEach(() => {
    window.ENV.COURSE_ID = '0'
    window.ENV.NEW_QUIZZES_MIGRATION = true
    // @ts-expect-error
    window.ENV.current_user = {id: '1'}

    fetchMock.mock('/api/v1/courses/0/content_migrations/migrators', [
      {
        name: 'Copy a Canvas Course',
        type: 'course_copy_importer',
      },
      {
        name: 'Canvas Course Export Package',
        type: 'canvas_cartridge_importer',
      },
      {
        name: 'Common Course Export Package',
        type: 'common_cartridge_importer',
      },
    ])
    fetchMock.mock(
      '/api/v1/courses/0/content_migrations',
      {
        id: '4',
        migration_type: 'course_copy_importer',
        migration_type_title: 'Test',
        pre_attachment: true,
      },
      {
        overwriteRoutes: true,
      }
    )
    fetchMock.mock(/users\/1\/manageable_courses\?term=(.*)/, [{id: '3', label: 'MyCourse'}])
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('does not show any form by default', () => {
    renderComponent()

    expect(screen.queryByRole('button', {name: 'Add to Import Queue'})).not.toBeInTheDocument()
    expect(screen.queryByRole('button', {name: 'Cancel'})).not.toBeInTheDocument()
  })

  it('Waits for loading of migrator options', () => {
    renderComponent()
    expect(screen.getByText('Loading options...')).toBeInTheDocument()
  })

  it('Populates select with migrator options', async () => {
    render(<ContentMigrationsForm setMigrations={jest.fn()} />)
    const selectOne = await screen.findByTitle('Select one')
    await userEvent.click(selectOne)
    expect(screen.getByText('Copy a Canvas Course')).toBeInTheDocument()
    expect(screen.getByText('Canvas Course Export Package')).toBeInTheDocument()
  })

  it('performs POST when submitting', async () => {
    renderComponent()

    await userEvent.click(await screen.findByTitle('Select one'))
    await userEvent.click(screen.getByText('Copy a Canvas Course'))

    await userEvent.type(screen.getByPlaceholderText('Search...'), 'MyCourse')
    await userEvent.click(await screen.findByRole('option', {name: 'MyCourse'}))

    await userEvent.click(screen.getByText('All content'))

    await userEvent.click(screen.getByTestId('submitMigration'))

    // @ts-expect-error
    const [url, response] = fetchMock.lastCall()
    expect(url).toBe('/api/v1/courses/0/content_migrations')
    expect(JSON.parse(response.body)).toStrictEqual({
      adjust_dates: {
        enabled: false,
        operation: 'shift_dates',
      },
      course_id: '0',
      migration_type: 'course_copy_importer',
      settings: {import_quizzes_next: false, source_course_id: '3'},
      selective_import: false,
      date_shift_options: {
        day_substitutions: [],
        new_end_date: false,
        new_start_date: false,
        old_end_date: false,
        old_start_date: false,
        substitutions: {},
      },
    })
  })

  it('performs file upload request when submitting', async () => {
    fetchMock.mock(
      '/api/v1/courses/0/content_migrations',
      {
        id: '4',
        migration_type: 'course_copy_importer',
        migration_type_title: 'Test',
        pre_attachment: {
          name: 'my_file.zip',
          size: 1024,
          no_redirect: false,
        },
      },
      {overwriteRoutes: true}
    )

    renderComponent()

    await userEvent.click(await screen.findByTitle('Select one'))
    await userEvent.click(screen.getByText('Canvas Course Export Package'))

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    Object.defineProperty(file, 'size', {value: 1024})
    const input = screen.getByTestId('migrationFileUpload')
    await userEvent.upload(input, file)

    await userEvent.click(screen.getByText('All content'))

    await userEvent.click(screen.getByTestId('submitMigration'))

    await waitFor(() => {
      expect(completeUpload).toHaveBeenCalledWith(
        {
          name: 'my_file.zip',
          size: 1024,
          no_redirect: false,
        },
        expect.any(File),
        {
          ignoreResult: true,
          onProgress: expect.any(Function),
        }
      )
    })
  })

  it('calls setMigrations when submitting', async () => {
    renderComponent()

    await userEvent.click(await screen.findByTitle('Select one'))
    await userEvent.click(screen.getByText('Copy a Canvas Course'))

    await userEvent.type(screen.getByPlaceholderText('Search...'), 'MyCourse')
    await userEvent.click(await screen.findByRole('option', {name: 'MyCourse'}))

    await userEvent.click(screen.getByText('All content'))

    await userEvent.click(screen.getByTestId('submitMigration'))

    expect(setMigrationsMock).toHaveBeenCalled()
  })

  it('passes the file upload progress to the migrator component', async () => {
    renderComponent()
    await userEvent.click(await screen.findByTitle('Select one'))
    await userEvent.click(screen.getByText('Common Course Export Package'))
    // would be undefined otherwise
    expect(CommonCartridgeImporter.mock.calls[0][0].fileUploadProgress).toEqual(null)
  })

  it('resets form after submitting', async () => {
    renderComponent()

    await userEvent.click(await screen.findByTitle('Select one'))
    await userEvent.click(screen.getByText('Copy a Canvas Course'))

    await userEvent.type(screen.getByPlaceholderText('Search...'), 'MyCourse')
    await userEvent.click(await screen.findByRole('option', {name: 'MyCourse'}))

    await userEvent.click(screen.getByText('All content'))

    await userEvent.click(screen.getByTestId('submitMigration'))
    expect(screen.queryByTestId('submitMigration')).not.toBeInTheDocument()
  })
})
