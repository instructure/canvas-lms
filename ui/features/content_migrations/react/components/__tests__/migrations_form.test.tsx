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
import ContentMigrationsForm from '../migrations_form'
import fetchMock from 'fetch-mock'

const setMigrationsMock = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(
    <ContentMigrationsForm migrations={[]} setMigrations={setMigrationsMock} {...overrideProps} />
  )

describe('ContentMigrationForm', () => {
  beforeEach(() => {
    window.ENV.COURSE_ID = '0'
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
    ])
    fetchMock.mock('/api/v1/courses/0/content_migrations', {
      id: '4',
      migration_type: 'course_copy_importer',
      migration_type_title: 'Test',
    })
    fetchMock.mock('/users/1/manageable_courses?term=MyCourse', [{id: '3', label: 'MyCourse'}])
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('Waits for loading of migrator options', () => {
    renderComponent()
    expect(screen.getByText('Loading options...')).toBeInTheDocument()
  })

  it('Populates select with migrator options', async () => {
    render(<ContentMigrationsForm migrations={[]} setMigrations={jest.fn()} />)
    const selectOne = await screen.findByTitle('Select one')
    userEvent.click(selectOne)
    expect(screen.getByText('Copy a Canvas Course')).toBeInTheDocument()
    expect(screen.getByText('Canvas Course Export Package')).toBeInTheDocument()
  })

  it('does POST request with course_copy_importer when submit', async () => {
    renderComponent()

    userEvent.click(await screen.findByTitle('Select one'))
    userEvent.click(screen.getByText('Copy a Canvas Course'))

    userEvent.type(screen.getByPlaceholderText('Search...'), 'MyCourse')
    userEvent.click(await screen.findByRole('option', {name: 'MyCourse'}))

    userEvent.click(screen.getByText('All content'))

    userEvent.click(screen.getByTestId('submitMigration'))

    // @ts-expect-error
    const [url, response] = fetchMock.lastCall()
    expect(url).toBe('/api/v1/courses/0/content_migrations')
    expect(JSON.parse(response.body)).toStrictEqual({
      course_id: '0',
      migration_type: 'course_copy_importer',
      settings: {import_quizzes_next: false, source_course_id: '3'},
      selective_import: false,
      date_shift_options: false,
    })
  })

  it('does POST request with canvas_cartridge_importer when submit', async () => {
    renderComponent()

    userEvent.click(await screen.findByTitle('Select one'))
    userEvent.click(screen.getByText('Canvas Course Export Package'))

    const file = new File(['blah, blah, blah'], 'my_file.zip', {type: 'application/zip'})
    Object.defineProperty(file, 'size', {value: 1024})
    const input = screen.getByTestId('migrationFileUpload')
    userEvent.upload(input, file)

    userEvent.click(screen.getByText('All content'))

    userEvent.click(screen.getByTestId('submitMigration'))

    const [url, response] = fetchMock.lastCall()
    expect(url).toBe('/api/v1/courses/0/content_migrations')
    expect(JSON.parse(response.body)).toStrictEqual({
      course_id: '0',
      migration_type: 'canvas_cartridge_importer',
      settings: {import_quizzes_next: false},
      selective_import: false,
      date_shift_options: false,
      pre_attachment: {size: 1024, name: 'my_file.zip', no_redirect: true},
    })
  })
})
