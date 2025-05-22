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
import userEvent from '@testing-library/user-event'
import ContentMigrationsForm from '../migrations_form'
import fetchMock from 'fetch-mock'
import {completeUpload} from '@canvas/upload-file'

const attachment = {
  id: '183',
  uuid: 'B9NafLSg93EiR8CK3GMvVZClKQYl0u1wD9kMb0IJ',
  folder_id: null,
  display_name: 'my_file.zip',
  filename: '1722434447_290__my_file.zip',
  upload_status: 'success',
  'content-type': 'application/zip',
  url: 'http://canvas-web.inseng.test/files/183/download?download_frd=1',
  size: 3804,
  created_at: '2024-08-06T08:49:47Z',
  updated_at: '2024-08-06T08:49:48Z',
  unlock_at: null,
  locked: false,
  hidden: false,
  lock_at: null,
  hidden_for_user: false,
  thumbnail_url: null,
  modified_at: '2024-08-06T08:49:47Z',
  mime_class: 'zip',
  media_entry_id: null,
  category: 'uncategorized',
  locked_for_user: false,
}

jest.mock('@canvas/upload-file', () => ({
  completeUpload: jest.fn(async () => attachment),
}))

const CommonCartridgeImporter = jest.fn()
// @ts-expect-error
jest.mock('../migrator_forms/common_cartridge', () => props => {
  CommonCartridgeImporter(props)
  // @ts-expect-error
  return <mock-CommonCartridgeImporter />
})

const setMigrationsMock = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(<ContentMigrationsForm setMigrations={setMigrationsMock} {...overrideProps} />)

const submitAMigration = async () => {
  await userEvent.click(await screen.findByTitle('Select one'))
  await userEvent.click(screen.getByText('Copy a Canvas Course'))

  await userEvent.type(screen.getByPlaceholderText('Search...'), 'MyCourse')
  await userEvent.click(await screen.findByRole('option', {name: 'MyCourse'}))

  await userEvent.click(screen.getByTestId('submitMigration'))
}

describe('ContentMigrationForm', () => {
  const postResponseMock = {
    id: '4',
    migration_type: 'course_copy_importer',
    migration_type_title: 'Test',
    pre_attachment: true,
    workflow_state: 'queued',
  }

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
    fetchMock.mock('/api/v1/courses/0/content_migrations', postResponseMock, {
      overwriteRoutes: true,
    })
    fetchMock.mock(
      /users\/1\/manageable_courses\?(.*&)?term=.*(&.*)?current_course_id=.*|current_course_id=.*(&.*)?term=.*/,
      [{id: '3', label: 'MyCourse'}],
    )
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

    await userEvent.click(screen.getByTestId('submitMigration'))

    const foundCall = fetchMock.calls('/api/v1/courses/0/content_migrations')[0]
    expect(foundCall[0]).toBe('/api/v1/courses/0/content_migrations')
    expect(JSON.parse(foundCall[1]?.body as string)).toStrictEqual({
      course_id: '0',
      migration_type: 'course_copy_importer',
      settings: {import_quizzes_next: false, source_course_id: '3'},
      selective_import: false,
      date_shift_options: {
        day_substitutions: {},
        new_end_date: '',
        new_start_date: '',
        old_end_date: '',
        old_start_date: '',
      },
    })
  })

  it('performs file upload request when submitting', async () => {
    // Reset the mock before this test to ensure clean state
    setMigrationsMock.mockReset()

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
      {overwriteRoutes: true},
    )

    renderComponent()

    await userEvent.click(await screen.findByTitle('Select one'))
    await userEvent.click(screen.getByText('Canvas Course Export Package'))

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    Object.defineProperty(file, 'size', {value: 1024})
    const input = screen.getByTestId('migrationFileUpload')
    await userEvent.upload(input, file)

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
        },
      )

      // The setMigrations function should have been called once
      expect(setMigrationsMock).toHaveBeenCalledTimes(1)
      const setterFunction = setMigrationsMock.mock.calls[0][0]
      const result = setterFunction([])
      expect(result[0].attachment.display_name).toBe(attachment.display_name)
      expect(result[0].attachment.url).toBe(attachment.url)
    })
  })

  it('calls setMigrations when submitting', async () => {
    renderComponent()
    await submitAMigration()
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

    await userEvent.click(screen.getByTestId('submitMigration'))
    expect(screen.queryByTestId('submitMigration')).not.toBeInTheDocument()
  })

  it('shows success alert after submitting', async () => {
    renderComponent()
    await submitAMigration()
    expect(screen.getAllByText('Content migration queued.')[0]).toBeInTheDocument()
  })

  describe('migration type', () => {
    const selectMigrator = async (migratorName: string) => {
      await userEvent.click(screen.getByText(migratorName))
    }

    const openSelectMigratorDropdown = async () => {
      await userEvent.click(await screen.findByTestId('select-content-type-dropdown'))
    }

    const renderAndOpenDropdown = async () => {
      renderComponent()
      await openSelectMigratorDropdown()
    }

    it('shows select one after initial load', async () => {
      await renderAndOpenDropdown()

      expect(screen.queryByText('Select one')).toBeInTheDocument()
    })

    it('does not show select one after selecting migrator', async () => {
      await renderAndOpenDropdown()

      await selectMigrator('Copy a Canvas Course')
      await openSelectMigratorDropdown()

      expect(screen.queryByText('Select one')).not.toBeInTheDocument()
    })

    it('shows select one after clicking clear', async () => {
      await renderAndOpenDropdown()

      await selectMigrator('Copy a Canvas Course')
      await userEvent.click(await screen.findByTestId('clear-migration-button'))
      await openSelectMigratorDropdown()

      expect(screen.queryByText('Select one')).toBeInTheDocument()
    })
  })

  describe('workflow_state setting', () => {
    afterEach(() => {
      setMigrationsMock.mockReset()
    })

    describe('when content_migration workflow_state is not waiting_for_select', () => {
      it('set workflow_state to queued', async () => {
        // Reset the mock before this test to ensure clean state
        setMigrationsMock.mockReset()

        // Create a specific response with running workflow state
        const runningResponse = {
          ...postResponseMock,
          workflow_state: 'running', // Explicitly set the workflow_state
        }

        fetchMock.mock('/api/v1/courses/0/content_migrations', runningResponse, {
          overwriteRoutes: true,
        })
        renderComponent()
        await submitAMigration()

        // Verify the mock was called
        expect(setMigrationsMock).toHaveBeenCalledTimes(1)

        const setterFunction = setMigrationsMock.mock.calls[0][0]
        const setterFunctionResult = setterFunction([])
        expect(setterFunctionResult).toHaveLength(1)
        expect(setterFunctionResult[0].workflow_state).toBe('queued')
      })
    })

    describe('when content_migration workflow_state is in waiting_for_select', () => {
      it('preserves waiting_for_select workflow_state', async () => {
        // Reset the mock before this test to ensure clean state
        setMigrationsMock.mockReset()

        // Create a specific response with waiting_for_select workflow state
        const waitingForSelectResponse = {
          ...postResponseMock,
          workflow_state: 'waiting_for_select', // Explicitly set the workflow_state
        }

        fetchMock.mock('/api/v1/courses/0/content_migrations', waitingForSelectResponse, {
          overwriteRoutes: true,
        })
        renderComponent()
        await submitAMigration()

        // Verify the mock was called
        expect(setMigrationsMock).toHaveBeenCalledTimes(1)

        const setterFunction = setMigrationsMock.mock.calls[0][0]
        const setterFunctionResult = setterFunction([])
        expect(setterFunctionResult).toHaveLength(1)
        expect(setterFunctionResult[0].workflow_state).toBe('waiting_for_select')
      })
    })
  })
})
