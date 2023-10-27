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
    doFetchApi.mockReturnValue(
      Promise.resolve({
        json: [
          {
            id: '0',
            label: 'Mathmatics',
          },
        ],
      })
    )
  })

  afterEach(() => jest.clearAllMocks())

  it('searches for matching courses', async () => {
    renderComponent()
    userEvent.type(screen.getByRole('combobox', {name: 'Search for a course'}), 'math')
    await waitFor(() => {
      expect(doFetchApi).toHaveBeenCalledWith({path: '/users/0/manageable_courses?term=math'})
    })
    expect(screen.getByText('Mathmatics')).toBeInTheDocument()
  })

  it('searches for matching courses including concluded', async () => {
    renderComponent()
    userEvent.click(screen.getByRole('checkbox', {name: 'Include completed courses'}))
    userEvent.type(screen.getByRole('combobox', {name: 'Search for a course'}), 'math')
    await waitFor(() => {
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/users/0/manageable_courses?term=math&include=concluded',
      })
    })
    expect(screen.getByText('Mathmatics')).toBeInTheDocument()
  })

  it('calls onSubmit', async () => {
    renderComponent()
    userEvent.type(screen.getByRole('combobox', {name: 'Search for a course'}), 'math')
    userEvent.click(await screen.findByText('Mathmatics'))
    userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({
        settings: expect.objectContaining({
          source_course_id: '0',
        }),
      })
    )
  })

  it('calls onCancel', () => {
    renderComponent()
    userEvent.click(screen.getByRole('button', {name: 'Cancel'}))
    expect(onCancel).toHaveBeenCalled()
  })
})
