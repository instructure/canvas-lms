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
import CourseCopyImporter from '../course_copy'
import userEvent from '@testing-library/user-event'
import {sharedDateParsingTests} from './shared_form_cases'
import fakeENV from '@canvas/test-utils/fakeENV'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const onSubmit = vi.fn()
const onCancel = vi.fn()

const fakeCourses = [
  {
    id: '0',
    label: 'Mathmatics',
    term: 'Default term',
    blueprint: true,
    end_at: '16 Oct 2024 at 0:00',
    start_at: '14 Oct 2024 at 0:00',
  },
  {
    id: '1',
    label: 'Biology',
    term: 'Other term',
    blueprint: false,
  },
]

const server = setupServer(
  http.get('/users/:userId/manageable_courses', () => {
    return HttpResponse.json(fakeCourses)
  }),
)

const renderComponent = (overrideProps?: any) =>
  render(
    <CourseCopyImporter
      onSubmit={onSubmit}
      onCancel={onCancel}
      isSubmitting={false}
      {...overrideProps}
    />,
  )

const defaultEnv = {
  current_user: {
    id: '0',
  },
  SHOW_BP_SETTINGS_IMPORT_OPTION: true,
  SHOW_SELECT: false,
}

const searchForACourse = 'Search for a course'
const addToImportQueue = 'Add to Import Queue'

describe('CourseCopyImporter', () => {
  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    fakeENV.setup({...defaultEnv})
  })

  afterEach(() => {
    vi.clearAllMocks()
    fakeENV.teardown()
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  it('searches for matching courses and includes concluded by default', async () => {
    const {getByRole, getByText} = renderComponent()
    await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
    await waitFor(() => {
      expect(getByText('Mathmatics')).toBeInTheDocument()
    })
  })

  it('searches for matching courses and display proper terms', async () => {
    const {getByRole, getByText} = renderComponent()
    await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
    await waitFor(() => {
      expect(getByText('Term: Default term')).toBeInTheDocument()
    })
    expect(getByText('Term: Other term')).toBeInTheDocument()
  })

  it('searches for matching courses excluding concluded', async () => {
    const {getByRole} = renderComponent()
    await userEvent.click(getByRole('checkbox', {name: 'Include completed courses'}))
    await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
    await waitFor(() => {
      expect(screen.getByText('Mathmatics')).toBeInTheDocument()
    })
  })

  it('calls onSubmit', async () => {
    const {getByRole, findByText} = renderComponent()
    await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
    await userEvent.click(await findByText('Mathmatics'))
    await userEvent.click(getByRole('button', {name: addToImportQueue}))
    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({
        settings: expect.objectContaining({
          source_course_id: '0',
        }),
      }),
    )
  })

  it('calls onCancel', async () => {
    const {getByRole} = renderComponent()
    await userEvent.click(getByRole('button', {name: 'Clear'}))
    expect(onCancel).toHaveBeenCalled()
  })

  // The testing of onCancel and onSubmit above need the actual common migrator controls
  // So instead of mocking it here and testing the prop being passed to the mock
  // we're following the precedent and testing all the way to the child in this suite
  it('Renders BP settings import option if appropriate', async () => {
    const {getByRole, findByText, getByText} = renderComponent()
    await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
    await userEvent.click(await findByText('Mathmatics'))
    await expect(await getByText('Import Blueprint Course settings')).toBeInTheDocument()
  })

  it('Does not renders BP settings import option when the destination course is marked ineligible', async () => {
    fakeENV.setup({...defaultEnv, SHOW_BP_SETTINGS_IMPORT_OPTION: false})
    const {getByRole, findByText, queryByText} = renderComponent()
    await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
    await waitFor(async () => {
      await expect(findByText('Mathmatics')).resolves.toBeInTheDocument()
    })
    await userEvent.click(await findByText('Mathmatics'))
    expect(queryByText('Import Blueprint Course settings')).toBeNull()
  })

  it('Does not render BP settings import option when the selected course is not a blueprint', async () => {
    const {queryByText} = renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: searchForACourse}), 'biol')
    await userEvent.click(await screen.findByText('Biology'))
    expect(queryByText('Import Blueprint Course settings')).toBeNull()
  })

  sharedDateParsingTests(CourseCopyImporter)
})
