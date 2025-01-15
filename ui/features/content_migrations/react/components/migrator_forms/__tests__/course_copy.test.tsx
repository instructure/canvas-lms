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
import doFetchApi from '@canvas/do-fetch-api-effect'
import {sharedDateParsingTests} from './shared_form_cases'

jest.mock('@canvas/do-fetch-api-effect')

const onSubmit = jest.fn()
const onCancel = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(<CourseCopyImporter onSubmit={onSubmit} onCancel={onCancel} {...overrideProps} />)

describe('CourseCopyImporter', () => {
  beforeAll(() => {
    // @ts-expect-error
    window.ENV.current_user = {
      id: '0',
    }
    window.ENV.SHOW_BP_SETTINGS_IMPORT_OPTION = true
    // @ts-expect-error
    doFetchApi.mockReturnValue(
      Promise.resolve({
        json: [
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
        ],
      })
    )
  })

  afterEach(() => jest.clearAllMocks())

  it('searches for matching courses and includes concluded by default', async () => {
    renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course *'}), 'math')
    await waitFor(() => {
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/users/0/manageable_courses?term=math&include=concluded',
      })
    })
    expect(screen.getByText('Mathmatics')).toBeInTheDocument()
  })

  it('searches for matching courses and display proper terms', async () => {
    renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course *'}), 'math')
    await waitFor(() => {
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/users/0/manageable_courses?term=math&include=concluded',
      })
    })
    expect(screen.getByText('Term: Default term')).toBeInTheDocument()
    expect(screen.getByText('Term: Other term')).toBeInTheDocument()
  })

  it('searches for matching courses excluding concluded', async () => {
    renderComponent()
    await userEvent.click(screen.getByRole('checkbox', {name: 'Include completed courses'}))
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course *'}), 'math')
    await waitFor(() => {
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/users/0/manageable_courses?term=math',
      })
    })
    expect(screen.getByText('Mathmatics')).toBeInTheDocument()
  })

  it('calls onSubmit', async () => {
    renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course *'}), 'math')
    await userEvent.click(await screen.findByText('Mathmatics'))
    await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({
        settings: expect.objectContaining({
          source_course_id: '0',
        }),
      })
    )
  })

  it('calls onCancel', async () => {
    renderComponent()
    await userEvent.click(screen.getByRole('button', {name: 'Clear'}))
    expect(onCancel).toHaveBeenCalled()
  })

  // The testing of onCancel and onSubmit above need the actual common migrator controls
  // So instead of mocking it here and testing the prop being passed to the mock
  // we're following the precedent and testing all the way to the child in this suite
  it('Renders BP settings import option if appropriate', async () => {
    renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course *'}), 'math')
    await userEvent.click(await screen.findByText('Mathmatics'))
    await expect(await screen.getByText('Import Blueprint Course settings')).toBeInTheDocument()
  })

  it('Does not renders BP settings import option when the destination course is marked ineligible', async () => {
    window.ENV.SHOW_BP_SETTINGS_IMPORT_OPTION = false
    renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course *'}), 'math')
    await userEvent.click(await screen.findByText('Mathmatics'))
    expect(screen.queryByText('Import Blueprint Course settings')).toBeNull()
  })

  it('Does not render BP settings import option when the selected course is not a blueprint', async () => {
    renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course *'}), 'biol')
    await userEvent.click(await screen.findByText('Biology'))
    expect(screen.queryByText('Import Blueprint Course settings')).toBeNull()
  })

  it('disable inputs while uploading', async () => {
    renderComponent({isSubmitting: true})
    await waitFor(() => {
      expect(screen.getByRole('button', {name: 'Clear'})).toBeDisabled()
      expect(screen.getByRole('button', {name: /Adding.../})).toBeDisabled()
      expect(screen.getByRole('combobox', {name: 'Search for a course *'})).toBeDisabled()
      expect(screen.getByRole('radio', {name: /All content/})).toBeDisabled()
      expect(screen.getByRole('radio', {name: 'Select specific content'})).toBeDisabled()
      expect(screen.getByRole('checkbox', {name: 'Adjust events and due dates'})).toBeDisabled()
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

  sharedDateParsingTests(CourseCopyImporter)

  describe('source course adjust date field prefills', () => {
    const expectDateField = (dataCid: string, value: string) => {
      expect((screen.getByTestId(dataCid) as HTMLInputElement).value).toBe(value)
    }

    it('parse the date from found course start date', async () => {
      const {getByRole} = renderComponent()

      await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course *'}), 'math')
      await userEvent.click(await screen.findByText('Mathmatics'))
      await userEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))

      expectDateField('old_start_date', 'Oct 14 at 8pm')
    })

    it('parse the date from found course end date', async () => {
      const {getByRole} = renderComponent()

      await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course *'}), 'math')
      await userEvent.click(await screen.findByText('Mathmatics'))
      await userEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))

      expectDateField('old_end_date', 'Oct 16 at 8pm')
    })
  })
})
