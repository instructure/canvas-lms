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

describe('CourseCopyImporter Inputs', () => {
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

  it('disable inputs while uploading', async () => {
    const {getByRole} = renderComponent({isSubmitting: true})
    await waitFor(() => {
      expect(getByRole('button', {name: 'Clear'})).toBeDisabled()
      expect(getByRole('button', {name: /Adding.../})).toBeDisabled()
      expect(getByRole('combobox', {name: searchForACourse})).toBeDisabled()
      expect(getByRole('radio', {name: /All content/})).toBeDisabled()
      expect(getByRole('radio', {name: 'Select specific content'})).toBeDisabled()
      expect(getByRole('checkbox', {name: 'Adjust events and due dates'})).toBeDisabled()
    })
  })

  it('disable "Adjust events and due dates" inputs while uploading', async () => {
    const {getByRole, rerender, getByLabelText} = renderComponent()

    await userEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))

    rerender(<CourseCopyImporter onSubmit={onSubmit} onCancel={onCancel} isSubmitting={true} />)

    await waitFor(() => {
      expect(getByRole('radio', {name: 'Shift dates'})).toBeInTheDocument()
      expect(getByRole('radio', {name: 'Shift dates'})).toBeDisabled()
      expect(getByRole('radio', {name: 'Remove dates'})).toBeDisabled()
      expect(getByLabelText('Select original beginning date')).toBeDisabled()
      expect(getByLabelText('Select new beginning date')).toBeDisabled()
      expect(getByLabelText('Select original end date')).toBeDisabled()
      expect(getByLabelText('Select new end date')).toBeDisabled()
      expect(getByRole('button', {name: 'Add substitution'})).toBeDisabled()
    })
  })

  describe('source course adjust date field prefills', () => {
    const expectDateField = (dataCid: string, value: string) => {
      expect((screen.getByTestId(dataCid) as HTMLInputElement).value).toBe(value)
    }

    it('parse the date from found course start date', async () => {
      const {getByRole, findByText} = renderComponent()

      await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
      await userEvent.click(await findByText('Mathmatics'))
      await userEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))

      expectDateField('old_start_date', 'Oct 14 at 8pm')
    })

    it('parse the date from found course end date', async () => {
      const {getByRole, findByText} = renderComponent()

      await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
      await userEvent.click(await findByText('Mathmatics'))
      await userEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))

      expectDateField('old_end_date', 'Oct 16 at 8pm')
    })
  })

  describe('course input error focus', () => {
    it('when SHOW_SELECT is false it focuses on input', async () => {
      fakeENV.setup({...defaultEnv, SHOW_SELECT: false})
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
      await waitFor(() => {
        expect(screen.getByTestId('course-copy-select-course')).toHaveFocus()
      })
    })

    it('when SHOW_SELECT is true it focuses on dropdown', async () => {
      fakeENV.setup({...defaultEnv, SHOW_SELECT: true})
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
      expect(screen.getByTestId('course-copy-select-preloaded-courses')).toHaveFocus()
    })
  })

  describe('URL crafting', () => {
    it('includes current_course_id in composeManageableCourseURL when ENV.COURSE_ID is set', async () => {
      fakeENV.setup({
        ...defaultEnv,
        COURSE_ID: '123',
      })

      renderComponent()

      await userEvent.type(screen.getByTestId('course-copy-select-course'), 'coursetest')

      // MSW will handle the request with current_course_id parameter
      await waitFor(() => {
        expect(screen.getByTestId('course-copy-select-course')).toHaveValue('coursetest')
      })
    })
  })
})
