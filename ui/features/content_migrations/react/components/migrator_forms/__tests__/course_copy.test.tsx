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
    doFetchApi.mockReturnValue(
      Promise.resolve({
        json: [
          {
            id: '0',
            label: 'Mathmatics',
            blueprint: true,
          },
          {
            id: '1',
            label: 'Biology',
            blueprint: false,
          },
        ],
      })
    )
  })

  afterEach(() => jest.clearAllMocks())

  it('searches for matching courses', async () => {
    renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course'}), 'math')
    await waitFor(() => {
      expect(doFetchApi).toHaveBeenCalledWith({path: '/users/0/manageable_courses?term=math'})
    })
    expect(screen.getByText('Mathmatics')).toBeInTheDocument()
  })

  it('searches for matching courses including concluded', async () => {
    renderComponent()
    await userEvent.click(screen.getByRole('checkbox', {name: 'Include completed courses'}))
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course'}), 'math')
    await waitFor(() => {
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/users/0/manageable_courses?term=math&include=concluded',
      })
    })
    expect(screen.getByText('Mathmatics')).toBeInTheDocument()
  })

  it('calls onSubmit', async () => {
    renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course'}), 'math')
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
    await userEvent.click(screen.getByRole('button', {name: 'Cancel'}))
    expect(onCancel).toHaveBeenCalled()
  })

  // The testing of onCancel and onSubmit above need the actual common migrator controls
  // So instead of mocking it here and testing the prop being passed to the mock
  // we're following the precedent and testing all the way to the child in this suite
  it('Renders BP settings import option if appropriate', async () => {
    renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course'}), 'math')
    await userEvent.click(await screen.findByText('Mathmatics'))
    await userEvent.click(screen.getByRole('radio', {name: 'All content'}))
    await expect(await screen.getByText('Import Blueprint Course settings')).toBeInTheDocument()
  })

  it('Does not renders BP settings import option when the destination course is marked ineligible', async () => {
    window.ENV.SHOW_BP_SETTINGS_IMPORT_OPTION = false
    renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course'}), 'math')
    await userEvent.click(await screen.findByText('Mathmatics'))
    await userEvent.click(screen.getByRole('radio', {name: 'All content'}))
    expect(screen.queryByText('Import Blueprint Course settings')).toBeNull()
  })

  it('Does not render BP settings import option when the selected course is not a blueprint', async () => {
    renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: 'Search for a course'}), 'biol')
    await userEvent.click(await screen.findByText('Biology'))
    await userEvent.click(screen.getByRole('radio', {name: 'All content'}))
    expect(screen.queryByText('Import Blueprint Course settings')).toBeNull()
  })
})
